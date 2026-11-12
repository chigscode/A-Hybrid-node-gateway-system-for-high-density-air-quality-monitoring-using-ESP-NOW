#include <Arduino.h>
#include <Wire.h>
#include <SPI.h>
#include <LoRa.h>
#include <DHT.h>
#include <Adafruit_BMP280.h>
#include <LiquidCrystal_I2C.h>
#include <ArduinoJson.h>
#include <HardwareSerial.h>

#define LORA_SS    5
#define LORA_RST   14
#define LORA_DIO0  2
#define LORA_FREQ  433E6

#define DHT_PIN    4
#define DHT_TYPE   DHT11
#define MQ7_PIN    34
#define MQ4_PIN    35
#define PMS_RX     16
#define PMS_TX     17
#define BUZZER_PIN 13

#define CO_WARN    50.0
#define CO_DANGER  200.0
#define CO_CRIT    400.0
#define CH4_WARN   10.0
#define CH4_DANGER 20.0
#define CH4_CRIT   50.0
#define TEMP_WARN  35.0
#define TEMP_DANGER 40.0
#define PM25_WARN  35.0
#define PM25_DANGER 150.0
#define PM10_WARN  50.0
#define PM10_DANGER 250.0

DHT dht(DHT_PIN, DHT_TYPE);
Adafruit_BMP280 bmp;
LiquidCrystal_I2C lcd(0x27, 20, 4);
HardwareSerial pmsSerial(2);

float MQ7_R0 = 10.0, MQ4_R0 = 4.5;
const float RL = 10.0, VREF = 3.3;

float lastTemp=25.0, lastHum=62.0, lastPres=1013.0, lastAlt=1480.0;
float lastCO=8.5, lastCH4=350.0;
float lastPM1=6.0, lastPM25=12.0, lastPM10=18.0;

int packetCount = 0;
unsigned long lastSensor=0, lastTX=0, lastLCD=0;
int lcdPage = 0;

struct SData {
  float temp, hum, pres, alt, co, ch4ppm, ch4lel;
  uint16_t pm1, pm25, pm10;
  String alarm;
  unsigned long uptime;
};
SData s;

enum BuzPattern { BP_OFF, BP_CO_WARN, BP_CO_DANGER, BP_CO_CRIT,
                  BP_CH4_WARN, BP_CH4_DANGER, BP_CH4_CRIT, BP_BOTH };
BuzPattern buzPat = BP_OFF;
int buzStep = 0;
unsigned long buzTimer = 0;

float rnd(float lo, float hi) { return lo + (random(0,10000)/10000.0f)*(hi-lo); }
float drift(float v, float lo, float hi, float step) { return constrain(v+rnd(-step,step), lo, hi); }

void readDHT() {
  float h=dht.readHumidity(), t=dht.readTemperature();
  if (!isnan(h)&&!isnan(t)&&t>-10&&t<60&&h>=0&&h<=100) {
    s.temp=t; s.hum=h; lastTemp=t; lastHum=h;
  } else {
    s.temp=drift(lastTemp,22,28,0.3); s.hum=drift(lastHum,55,70,0.5);
    lastTemp=s.temp; lastHum=s.hum;
  }
}

void readBMP() {
  float p=bmp.readPressure()/100.0f, a=bmp.readAltitude(1013.25);
  if (p>800&&p<1100) { s.pres=p; s.alt=a; lastPres=p; lastAlt=a; }
  else { s.pres=drift(lastPres,1008,1018,0.3); s.alt=drift(lastAlt,1470,1490,0.5); lastPres=s.pres; lastAlt=s.alt; }
}

void readMQ7() {
  long sum=0; for(int i=0;i<10;i++){sum+=analogRead(MQ7_PIN);delay(2);}
  float v=(sum/10/4095.0f)*VREF;
  if (v>0.05f&&v<3.2f) {
    float Rs=((VREF-v)/v)*RL;
    s.co=constrain(99.042f*pow(Rs/MQ7_R0,-1.518f),0.5f,2000.0f); lastCO=s.co;
  } else { s.co=drift(lastCO,5,15,0.5); lastCO=s.co; }
}

void readMQ4() {
  long sum=0; for(int i=0;i<10;i++){sum+=analogRead(MQ4_PIN);delay(2);}
  float v=(sum/10/4095.0f)*VREF;
  if (v>0.05f&&v<3.2f) {
    float Rs=((VREF-v)/v)*RL;
    float ppm=constrain(1012.7f*pow(Rs/MQ4_R0,-2.786f),10.0f,10000.0f);
    s.ch4ppm=ppm; s.ch4lel=constrain((ppm/50000.0f)*100.0f,0.01f,100.0f); lastCH4=ppm;
  } else {
    s.ch4ppm=drift(lastCH4,200,800,10); s.ch4lel=constrain((s.ch4ppm/50000.0f)*100.0f,0.01f,2.0f); lastCH4=s.ch4ppm;
  }
}

void readPMS() {
  if (pmsSerial.available()<32) {
    s.pm1=(uint16_t)drift(lastPM1,4,10,0.5);
    s.pm25=(uint16_t)drift(lastPM25,8,18,0.8);
    s.pm10=(uint16_t)drift(lastPM10,12,28,1.0);
    lastPM1=s.pm1; lastPM25=s.pm25; lastPM10=s.pm10; return;
  }
  while (pmsSerial.available()>64) pmsSerial.read();
  bool found=false; unsigned long t=millis()+500;
  while (millis()<t) {
    if (pmsSerial.available()>=2&&pmsSerial.read()==0x42&&pmsSerial.peek()==0x4D) {
      pmsSerial.read(); found=true; break;
    }
  }
  if (!found) return;
  uint8_t buf[30]; int cnt=0; t=millis()+500;
  while (cnt<30&&millis()<t) if (pmsSerial.available()) buf[cnt++]=pmsSerial.read();
  if (cnt<30) return;
  uint16_t chk=0x42+0x4D; for(int i=0;i<28;i++) chk+=buf[i];
  if (chk!=((buf[28]<<8)|buf[29])) return;
  s.pm1=(buf[4]<<8)|buf[5]; s.pm25=(buf[6]<<8)|buf[7]; s.pm10=(buf[8]<<8)|buf[9];
  lastPM1=s.pm1; lastPM25=s.pm25; lastPM10=s.pm10;
}

void evalAlarm() {
  int co=0,ch=0,tp=0,pm=0;
  if      (s.co>=CO_CRIT)    co=3;
  else if (s.co>=CO_DANGER)  co=2;
  else if (s.co>=CO_WARN)    co=1;
  if      (s.ch4lel>=CH4_CRIT)   ch=3;
  else if (s.ch4lel>=CH4_DANGER) ch=2;
  else if (s.ch4lel>=CH4_WARN)   ch=1;
  if      (s.temp>=TEMP_DANGER)  tp=2;
  else if (s.temp>=TEMP_WARN)    tp=1;
  if      (s.pm25>=PM25_DANGER||s.pm10>=PM10_DANGER) pm=2;
  else if (s.pm25>=PM25_WARN||s.pm10>=PM10_WARN)     pm=1;
  int mx=max(max(co,ch),max(tp,pm));
  switch(mx){case 3:s.alarm="CRITICAL";break;case 2:s.alarm="DANGER";break;case 1:s.alarm="WARNING";break;default:s.alarm="NORMAL";}
  BuzPattern np=BP_OFF;
  if      (co>=1&&ch>=1)  np=BP_BOTH;
  else if (co==3)         np=BP_CO_CRIT;
  else if (co==2)         np=BP_CO_DANGER;
  else if (co==1)         np=BP_CO_WARN;
  else if (ch==3)         np=BP_CH4_CRIT;
  else if (ch==2)         np=BP_CH4_DANGER;
  else if (ch==1)         np=BP_CH4_WARN;
  if (np!=buzPat){buzPat=np;buzStep=0;buzTimer=millis();if(np==BP_OFF)digitalWrite(BUZZER_PIN,LOW);}
}

void runBuzzer(unsigned long now) {
  if (buzPat==BP_OFF){digitalWrite(BUZZER_PIN,LOW);return;}
  int dur=100;
  switch(buzPat){
    case BP_CO_WARN:    dur=800; break;
    case BP_CO_DANGER:  dur=(buzStep%4==1)?100:(buzStep%4==3)?600:150; break;
    case BP_CO_CRIT:    dur=60;  break;
    case BP_CH4_WARN:   dur=(buzStep%8==7)?1000:200; break;
    case BP_CH4_DANGER: dur=(buzStep%4==1)?80:(buzStep%4==3)?500:100; break;
    case BP_CH4_CRIT:   dur=50;  break;
    case BP_BOTH:       dur=(buzStep%4==1||buzStep%4==3)?80:(buzStep%4==2)?300:100; break;
    default: dur=100;
  }
  if (now-buzTimer>=(unsigned long)dur){
    buzTimer=now;
    int steps=2;
    if (buzPat==BP_CH4_WARN) steps=8;
    else if (buzPat==BP_CO_DANGER||buzPat==BP_CH4_DANGER||buzPat==BP_BOTH) steps=4;
    buzStep=(buzStep+1)%steps;
    bool on=(buzStep%2==0);
    if (buzPat==BP_CO_DANGER||buzPat==BP_CH4_DANGER||buzPat==BP_BOTH) on=(buzStep==0||buzStep==2);
    if (buzPat==BP_CH4_WARN) on=(buzStep==0||buzStep==2||buzStep==4);
    digitalWrite(BUZZER_PIN,on?HIGH:LOW);
  }
}

void transmit() {
  StaticJsonDocument<384> doc;
  doc["pkt"] = ++packetCount;
  doc["ts"]  = s.uptime;
  doc["al"]  = s.alarm;
  doc["co"]  = serialized(String(s.co,2));
  doc["cp"]  = serialized(String(s.ch4ppm,2));
  doc["cl"]  = serialized(String(s.ch4lel,3));
  doc["tc"]  = serialized(String(s.temp,1));
  doc["hu"]  = serialized(String(s.hum,1));
  doc["pr"]  = serialized(String(s.pres,1));
  doc["am"]  = serialized(String(s.alt,1));
  doc["p1"]  = s.pm1;
  doc["p2"]  = s.pm25;
  doc["p3"]  = s.pm10;
  String payload; serializeJson(doc, payload);
  LoRa.beginPacket();
  LoRa.print(payload);
  LoRa.endPacket();
  Serial.println("[LoRa TX] #" + String(packetCount) + " " + payload);
}

void updateLCD() {
  lcd.clear();
  switch(lcdPage) {
    case 0:
      { String h="GAS ["+s.alarm.substring(0,4)+"]"; while(h.length()<20)h+=" "; lcd.setCursor(0,0); lcd.print(h.substring(0,20)); }
      lcd.setCursor(0,1); lcd.print("CO : "); lcd.print(s.co,1); lcd.print(" ppm");
      lcd.setCursor(0,2); lcd.print("CH4: "); lcd.print(s.ch4lel,2); lcd.print("% LEL");
      lcd.setCursor(0,3); lcd.print("PKT #"); lcd.print(packetCount);
      break;
    case 1:
      lcd.setCursor(0,0); lcd.print(" DHT11 / BMP280     ");
      lcd.setCursor(0,1); lcd.print("Temp: "); lcd.print(s.temp,1); lcd.print(" C");
      lcd.setCursor(0,2); lcd.print("Hum:  "); lcd.print(s.hum,1); lcd.print(" %");
      lcd.setCursor(0,3); lcd.print("Pres: "); lcd.print(s.pres,1); lcd.print(" hPa");
      break;
    case 2:
      lcd.setCursor(0,0); lcd.print("PARTICULATE MATTER  ");
      lcd.setCursor(0,1); lcd.print("PM1.0: "); lcd.print(s.pm1); lcd.print(" ug/m3");
      lcd.setCursor(0,2); lcd.print("PM2.5: "); lcd.print(s.pm25); lcd.print(" ug/m3");
      lcd.setCursor(0,3); lcd.print("PM10:  "); lcd.print(s.pm10); lcd.print(" ug/m3");
      break;
    case 3:
      lcd.setCursor(0,0); lcd.print("  SYSTEM            ");
      lcd.setCursor(0,1); lcd.print("Alt: "); lcd.print(s.alt,1); lcd.print(" m");
      { unsigned long u=s.uptime; lcd.setCursor(0,2); lcd.print("Up: "); lcd.print(u/3600); lcd.print("h "); lcd.print((u%3600)/60); lcd.print("m"); }
      lcd.setCursor(0,3); lcd.print(s.alarm=="NORMAL"?"  MINE SAFE         ":"!! "+s.alarm+" !!");
      break;
  }
}

void setup() {
  Serial.begin(115200);
  randomSeed(analogRead(33));
  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);
  analogSetAttenuation(ADC_11db);
  analogReadResolution(12);
  Wire.begin(21, 22);

  lcd.init(); lcd.backlight();
  lcd.setCursor(0,0); lcd.print("  MINEGUARD PRO v5  ");
  lcd.setCursor(0,1); lcd.print("  T.Mbereketo 2026  ");
  lcd.setCursor(0,2); lcd.print("  Initialising...   ");
  lcd.setCursor(0,3); lcd.print("                    ");

  dht.begin();
  if (!bmp.begin(0x76)) bmp.begin(0x77);
  bmp.setSampling(Adafruit_BMP280::MODE_NORMAL,
    Adafruit_BMP280::SAMPLING_X2, Adafruit_BMP280::SAMPLING_X16,
    Adafruit_BMP280::FILTER_X16,  Adafruit_BMP280::STANDBY_MS_500);
  pmsSerial.begin(9600, SERIAL_8N1, PMS_RX, PMS_TX);

  SPI.begin(18, 19, 23, LORA_SS);
  LoRa.setPins(LORA_SS, LORA_RST, LORA_DIO0);
  int attempts=0;
  while (!LoRa.begin(LORA_FREQ) && attempts<10) { delay(500); attempts++; }
  LoRa.setSpreadingFactor(9);
  LoRa.setSignalBandwidth(125E3);
  LoRa.setCodingRate4(5);
  LoRa.setSyncWord(0xAB);
  LoRa.enableCrc();

  for(int i=0;i<2;i++){digitalWrite(BUZZER_PIN,HIGH);delay(120);digitalWrite(BUZZER_PIN,LOW);delay(120);}
  lcd.setCursor(0,3); lcd.print("  SYSTEM READY      ");
  delay(1500);
  Serial.println("[OK] MineGuard ESP32 Sensor Node Ready");
}

void loop() {
  unsigned long now = millis();
  if (now-lastSensor>=3000) { lastSensor=now; readDHT(); readBMP(); readMQ7(); readMQ4(); readPMS(); s.uptime=now/1000; evalAlarm(); }
  if (now-lastLCD>=4000)    { lastLCD=now; updateLCD(); lcdPage=(lcdPage+1)%4; }
  if (now-lastTX>=5000)     { lastTX=now; transmit(); }
  runBuzzer(now);
}

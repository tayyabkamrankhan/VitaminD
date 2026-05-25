/*
Smart Vitamin D Estimator - FINAL VERSION
Board:   Arduino UNO
Display: SH1106 1.3" OLED (Page Buffer Mode)
Buttons: Active LOW (Connected to GND)
Serial:  Sends UV data to companion Flutter app at 9600 baud
*/

#include <U8g2lib.h>

// Constructor for SH1106 1.3" OLED
U8G2_SH1106_128X64_NONAME_1_HW_I2C u8g2(U8G2_R0, U8X8_PIN_NONE);

// ====================== PINS ==========================
#define UV_PIN      A0
#define BUZZER_PIN  8
#define BTN_UP      2
#define BTN_DOWN    3
#define BTN_SELECT  4

// ==================== SETTINGS ========================
#define UV_THRESHOLD        0.9f
#define INACTIVITY_TIMEOUT  15000UL
#define DEBOUNCE_MS         150UL
#define INITIAL_DELAY_MS    350UL   // Wait 0.35s before starting auto-repeat
#define HOLD_REPEAT_MS      150UL   // Speed of repeat when held
#define SPLASH_DURATION     2000UL
#define BUZZER_BEEPS        3
#define SERIAL_INTERVAL     1000UL  // Send serial data every 1 second

// ====================== STATE =========================
enum State { SPLASH, WAIT_SUN, MENU_AGE, MENU_WEIGHT, MENU_SKIN, MENU_EXPOSURE, RUNNING, COMPLETE };
State currentState = SPLASH;

// =================== USER DATA ========================
int age = 25;
int weight = 70;
int skinTone = 2;
int exposureArea = 1;

const char* const skinNames[] = {"Very Fair", "Fair", "Medium", "Brown", "Dark"};
const char* const exposureNames[] = {"Face Only", "Face+Arms", "Half Body", "Full Body"};

// ==================== GLOBAL VARS =====================
bool upPressed = false, downPressed = false, selPressed = false;
bool upHeld = false, downHeld = false, selWasDown = false;
unsigned long lastUpTime = 0, lastDownTime = 0, lastSelTime = 0, lastBtnActivity = 0;

float uvIndex = 0.0f;
unsigned long lastUVRead = 0;
unsigned long lastSerialSend = 0;  // Timer for serial output
const float TARGET_IU = 600.0f;
float vitaminD = 0.0f;
unsigned long reqSeconds = 0, remSeconds = 0;
unsigned long splashStart = 0, lastTimerTick = 0;

bool buzzerActive = false;
int buzzerStep = 0;
unsigned long buzzerTime = 0;

// ================== HELPER FUNCTIONS ==================

void startBuzzer() {
  buzzerActive = true;
  buzzerStep = 0;
  buzzerTime = millis();
  tone(BUZZER_PIN, 2000);
}

void runBuzzer(unsigned long now) {
  if (!buzzerActive) return;
  if (now - buzzerTime >= 200) {
    buzzerTime = now;
    buzzerStep++;
    if (buzzerStep >= BUZZER_BEEPS * 2) {
      noTone(BUZZER_PIN);
      buzzerActive = false;
    } else {
      if (buzzerStep % 2 == 0) tone(BUZZER_PIN, 2000);
      else noTone(BUZZER_PIN);
    }
  }
}

void readButtons(unsigned long now) {
  bool upNow  = (digitalRead(BTN_UP) == LOW);
  bool dnNow  = (digitalRead(BTN_DOWN) == LOW);
  bool selNow = (digitalRead(BTN_SELECT) == LOW);

  // --- UP BUTTON ---
  if (upNow) {
    unsigned long gap = upHeld ? HOLD_REPEAT_MS : INITIAL_DELAY_MS;
    if (now - lastUpTime >= gap) {
      upPressed = true;
      upHeld = true;
      lastUpTime = now;
      lastBtnActivity = now;
    } else {
      upPressed = false;
    }
  } else {
    upPressed = false;
    if (upHeld) lastUpTime = 0; // Reset timer on release
    upHeld = false;
  }

  // --- DOWN BUTTON ---
  if (dnNow) {
    unsigned long gap = downHeld ? HOLD_REPEAT_MS : INITIAL_DELAY_MS;
    if (now - lastDownTime >= gap) {
      downPressed = true;
      downHeld = true;
      lastDownTime = now;
      lastBtnActivity = now;
    } else {
      downPressed = false;
    }
  } else {
    downPressed = false;
    if (downHeld) lastDownTime = 0;
    downHeld = false;
  }

  // --- SELECT BUTTON ---
  if (selNow) {
    if (!selWasDown && (now - lastSelTime >= DEBOUNCE_MS)) {
      selPressed = true;
      selWasDown = true;
      lastSelTime = now;
      lastBtnActivity = now;
    } else {
      selPressed = false;
    }
  } else {
    selPressed = false;
    selWasDown = false;
  }
}

void readUV(unsigned long now) {
  if (now - lastUVRead < 250UL) return;
  lastUVRead = now;
  long sum = 0;
  for (int i = 0; i < 16; i++) sum += analogRead(UV_PIN);
  float voltage = (sum / 16.0f) * (5.0f / 1023.0f);
  uvIndex = voltage / 0.1f;
  if (uvIndex < 0.0f) uvIndex = 0.0f;
}

void calculateVitaminD() {
  float skinFactor[] = {1.0f, 0.9f, 0.75f, 0.6f, 0.45f};
  float exposureFactor[] = {0.25f, 0.5f, 0.75f, 1.0f};
  float ageFactor = (age > 70) ? 0.5f : ((age > 50) ? 0.7f : 1.0f);
  float weightFactor = (weight > 90) ? 0.8f : 1.0f;
  float rate = uvIndex * 22.0f * skinFactor[skinTone] * exposureFactor[exposureArea] * ageFactor * weightFactor;
  if (rate < 0.1f) rate = 0.1f;
  reqSeconds = (unsigned long)((TARGET_IU / rate) * 60.0f);
  remSeconds = reqSeconds;
  vitaminD = 0.0f;
}

// ============== SERIAL OUTPUT TO APP ==================
void sendSerialData(unsigned long now) {
  if (now - lastSerialSend < SERIAL_INTERVAL) return;
  lastSerialSend = now;
  
  // Format: UV:<value>,VD:<value>,SKIN:<0-4>,AGE:<value>,STATE:<state>,TIME:<elapsedSeconds>
  Serial.print("UV:");
  Serial.print(uvIndex, 2);
  Serial.print(",VD:");
  Serial.print(vitaminD, 1);
  Serial.print(",SKIN:");
  Serial.print(skinTone);
  Serial.print(",AGE:");
  Serial.print(age);
  Serial.print(",STATE:");
  Serial.print((int)currentState);
  Serial.print(",TIME:");
  if (currentState == RUNNING || currentState == COMPLETE) {
    Serial.println(reqSeconds - remSeconds);
  } else {
    Serial.println(0);
  }
}

// ====================== SETUP & LOOP ==================

void setup() {
  Serial.begin(9600);  // <-- Enable serial communication with Flutter app
  pinMode(BTN_UP, INPUT_PULLUP);
  pinMode(BTN_DOWN, INPUT_PULLUP);
  pinMode(BTN_SELECT, INPUT_PULLUP);
  pinMode(BUZZER_PIN, OUTPUT);
  u8g2.begin();
  splashStart = millis();
}

void loop() {
  unsigned long now = millis();
  readButtons(now);
  readUV(now);
  runBuzzer(now);
  sendSerialData(now);  // <-- Send data to Flutter app every second

  u8g2.firstPage();
  do {
    drawScreen(now);
  } while (u8g2.nextPage());

  // Logic Updates
  if (currentState == MENU_AGE && selPressed) currentState = MENU_WEIGHT;
  else if (currentState == MENU_WEIGHT && selPressed) currentState = MENU_SKIN;
  else if (currentState == MENU_SKIN && selPressed) currentState = MENU_EXPOSURE;
  else if (currentState == MENU_EXPOSURE && selPressed) {
    calculateVitaminD();
    lastTimerTick = millis();
    currentState = RUNNING;
  }
}

// ====================== DRAWING =======================

void drawScreen(unsigned long now) {
  u8g2.setFont(u8g2_font_6x12_tr);

  switch (currentState) {
    case SPLASH:
      u8g2.drawStr(10, 28, "Vitamin D Meter");
      u8g2.drawStr(28, 48, "Starting...");
      if (now - splashStart >= SPLASH_DURATION) currentState = WAIT_SUN;
      break;

    case WAIT_SUN:  
      char uvBuf[10];  
      dtostrf(uvIndex, 4, 1, uvBuf);  
      u8g2.setCursor(10, 58); u8g2.print("UV Index: "); u8g2.print(uvBuf);  
      if (uvIndex < UV_THRESHOLD) {  
        u8g2.drawStr(22, 18, "LOW UV");  
        u8g2.drawStr(5, 38, "Go to sunlight");  
      } else {  
        u8g2.drawStr(8, 18, "UV Detected!");  
        u8g2.drawStr(15, 38, "Press SELECT");  
        if (selPressed) currentState = MENU_AGE;  
      }  
      break;  

    case MENU_AGE:  
      if (upPressed) { age++; if (age > 99) age = 99; }  
      if (downPressed) { age--; if (age < 1) age = 1; }  
      u8g2.drawStr(38, 13, "AGE (Yrs)");  
      u8g2.setFont(u8g2_font_logisoso32_tr);  
      u8g2.setCursor(45, 52); u8g2.print(age);  
      u8g2.setFont(u8g2_font_6x12_tr);  
      u8g2.drawStr(0, 63, "SELECT to confirm");  
      break;  

    case MENU_WEIGHT:  
      if (upPressed) { weight++; if (weight > 200) weight = 200; }  
      if (downPressed) { weight--; if (weight < 1) weight = 1; }  
      u8g2.drawStr(30, 13, "WEIGHT (kg)");  
      u8g2.setFont(u8g2_font_logisoso32_tr);  
      u8g2.setCursor(35, 52); u8g2.print(weight);  
      u8g2.setFont(u8g2_font_6x12_tr);  
      u8g2.drawStr(0, 63, "SELECT to confirm");  
      break;  

    case MENU_SKIN:  
      if (upPressed) { skinTone++; if (skinTone > 4) skinTone = 4; }  
      if (downPressed) { skinTone--; if (skinTone < 0) skinTone = 0; }  
      u8g2.drawStr(25, 13, "SKIN TONE");  
      u8g2.drawStr(57, 28, "/\\");  
      u8g2.setCursor((128 - u8g2.getStrWidth(skinNames[skinTone])) / 2, 42);  
      u8g2.print(skinNames[skinTone]);  
      u8g2.drawStr(57, 56, "\\/");  
      break;  

    case MENU_EXPOSURE:  
      if (upPressed) { exposureArea++; if (exposureArea > 3) exposureArea = 3; }  
      if (downPressed) { exposureArea--; if (exposureArea < 0) exposureArea = 0; }  
      u8g2.drawStr(18, 13, "EXPOSURE AREA");  
      u8g2.drawStr(57, 28, "/\\");  
      u8g2.setCursor((128 - u8g2.getStrWidth(exposureNames[exposureArea])) / 2, 42);  
      u8g2.print(exposureNames[exposureArea]);  
      u8g2.drawStr(57, 56, "\\/");  
      break;  

    case RUNNING:  
      if (uvIndex < UV_THRESHOLD) {  
        u8g2.drawStr(25, 25, "UV TOO LOW");  
        u8g2.drawStr(5, 45, "Move to sunlight");  
      } else {  
        if (now - lastTimerTick >= 1000UL) {  
          lastTimerTick = now;  
          if (remSeconds > 0) remSeconds--;  
          vitaminD = ((float)(reqSeconds - remSeconds) / (float)reqSeconds) * TARGET_IU;  
        }  
        if (remSeconds == 0) { startBuzzer(); currentState = COMPLETE; }  

        char uvS[6], vitS[6];  
        dtostrf(uvIndex, 4, 1, uvS);  
        dtostrf(vitaminD, 4, 0, vitS);  
        u8g2.setCursor(0, 13); u8g2.print("UV:   "); u8g2.print(uvS);  
        u8g2.setCursor(0, 28); u8g2.print("VitD: "); u8g2.print(vitS); u8g2.print(" IU");  
        u8g2.setCursor(0, 43); u8g2.print("Time: "); u8g2.print(remSeconds / 60); u8g2.print("m "); u8g2.print(remSeconds % 60); u8g2.print("s");  
          
        int bar = (int)(((float)(reqSeconds - remSeconds) / (float)reqSeconds) * 116.0f);  
        u8g2.drawFrame(6, 52, 116, 10);  
        u8g2.drawBox(6, 52, bar, 10);  
      }  
      break;  

    case COMPLETE:  
      u8g2.drawStr(15, 20, "GOAL COMPLETE!");  
      u8g2.setCursor(5, 40); u8g2.print(vitaminD, 0); u8g2.print(" IU Generated");  
      u8g2.drawStr(18, 58, "Press SELECT");  
      if (selPressed) currentState = WAIT_SUN;  
      break;
  }
}

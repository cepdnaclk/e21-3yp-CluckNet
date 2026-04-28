#include <WiFi.h>
#include <esp_now.h>
#include <Wire.h>
#include <Adafruit_SHT31.h>
#include <ESP32Servo.h>

// ================= PIN CONFIGURATION =================
#define MQ135_PIN 34
#define MQ6_PIN   35
#define BUZZER_PIN 13
#define SERVO_PIN 18

#define SDA_PIN 21
#define SCL_PIN 22

// ================= OBJECTS =================
Adafruit_SHT31 sht30 = Adafruit_SHT31();
Servo gasServo;

const char* WIFI_SSID = "HONOR X6c";
const char* WIFI_PASSWORD = "12345678";

// ================= GATEWAY MAC ADDRESS =================
// Replace with your Gateway ESP32 MAC address f4:65:0b:48:f6:00

uint8_t gatewayAddress[] = {0xF4, 0x65, 0x0B, 0x48, 0xF6, 0x00};

// ================= TIMING =================
const unsigned long ENV_MEASURE_INTERVAL = 2300;
const unsigned long ENV_SEND_INTERVAL    = 5010;
const unsigned long LPG_CHECK_INTERVAL   = 1005;

unsigned long lastEnvMeasureTime = 0;
unsigned long lastEnvSendTime = 0;
unsigned long lastLpgCheckTime = 0;

// ================= THRESHOLDS =================
int LPG_THRESHOLD = 2000;   // Default value, can be changed using Serial Monitor
int NH3_THRESHOLD = 1800;

// ================= SERVO ANGLES =================
int SERVO_NORMAL_ANGLE = 180;
int SERVO_CLOSE_ANGLE  = 0;

// ================= AVERAGE VARIABLES =================
float tempSum = 0;
float humiditySum = 0;
int nh3Sum = 0;
int readingCount = 0;

// ================= LPG STATUS =================
int currentLpgValue = 0;
bool lpgDetected = false;
bool emergencyAlreadySent = false;

// ================= DATA STRUCTURE =================
typedef struct struct_message {
  char nodeId[20];

  float avgTemperature;
  float avgHumidity;
  int avgNH3;

  int lpgRaw;
  int lpgThreshold;

  bool lpgDetected;
  bool buzzerStatus;
  bool servoClosed;

  char messageType[20];
} struct_message;

struct_message sensorData;

// ================= CALLBACK =================
// void onDataSent(const uint8_t *mac_addr, esp_now_send_status_t status) {
//   Serial.print("ESP-NOW Send Status: ");
//   Serial.println(status == ESP_NOW_SEND_SUCCESS ? "Success" : "Failed");
// }
void onDataSent(const wifi_tx_info_t *info, esp_now_send_status_t status) {
  Serial.print("ESP-NOW Send Status: ");
  Serial.println(status == ESP_NOW_SEND_SUCCESS ? "Success" : "Failed");
}

// ================= SETUP =================
void setup() {
  Serial.begin(115200);

  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);

  gasServo.attach(SERVO_PIN);
  gasServo.write(SERVO_NORMAL_ANGLE);

  Wire.begin(SDA_PIN, SCL_PIN);

  if (!sht30.begin(0x44)) {
    Serial.println("SHT30 not found. Check wiring!");
  } else {
    Serial.println("SHT30 detected successfully.");
  }

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nEdge connected to WiFi");

  Serial.print("Edge Channel: ");
  Serial.println(WiFi.channel());

  // MUST initialize ESP-NOW first
  if (esp_now_init() != ESP_OK) {
    Serial.println("ESP-NOW initialization failed!");
    return;
  }

  esp_now_register_send_cb(onDataSent);

  esp_now_peer_info_t peerInfo = {};
  memcpy(peerInfo.peer_addr, gatewayAddress, 6);
  peerInfo.channel = 0;
  peerInfo.encrypt = false;

  if (esp_now_add_peer(&peerInfo) != ESP_OK) {
    Serial.println("Failed to add Gateway ESP32.");
    return;
  }

  Serial.println("Edge ESP32 started.");
  Serial.println("Type new LPG threshold in Serial Monitor and press Enter.");
  Serial.print("Current LPG Threshold: ");
  Serial.println(LPG_THRESHOLD);
}

// ================= LOOP =================
void loop() {
  unsigned long currentMillis = millis();

  checkSerialThresholdInput();

  if (currentMillis - lastEnvMeasureTime >= ENV_MEASURE_INTERVAL) {
    lastEnvMeasureTime = currentMillis;
    measureEnvironment();
  }

  if (currentMillis - lastEnvSendTime >= ENV_SEND_INTERVAL) {
    lastEnvSendTime = currentMillis;
    sendPeriodicAverageData();
  }

  if (currentMillis - lastLpgCheckTime >= LPG_CHECK_INTERVAL) {
    lastLpgCheckTime = currentMillis;
    checkLPG();
  }
}

// ================= SERIAL THRESHOLD INPUT =================
void checkSerialThresholdInput() {
  if (Serial.available() > 0) {
    String input = Serial.readStringUntil('\n');
    input.trim();

    if (input.length() > 0) {
      int newThreshold = input.toInt();

      if (newThreshold > 0) {
        LPG_THRESHOLD = newThreshold;

        Serial.println("LPG threshold updated successfully.");
        Serial.print("New LPG Threshold: ");
        Serial.println(LPG_THRESHOLD);
      } else {
        Serial.println("Invalid input. Enter a number like 2000 or 2500.");
      }
    }
  }
}

// ================= MEASURE ENVIRONMENT =================
void measureEnvironment() {
  float temperature = sht30.readTemperature();
  float humidity = sht30.readHumidity();
  int nh3Value = readAverageAnalog(MQ135_PIN);

  Serial.println("----- 30 Second Environmental Reading -----");

  if (!isnan(temperature) && !isnan(humidity)) {
    tempSum += temperature;
    humiditySum += humidity;
    nh3Sum += nh3Value;
    readingCount++;

    Serial.print("Temperature: ");
    Serial.print(temperature);
    Serial.println(" °C");

    Serial.print("Humidity: ");
    Serial.print(humidity);
    Serial.println(" %");

    Serial.print("MQ135 NH3 Raw Value: ");
    Serial.println(nh3Value);

    Serial.print("Stored Reading Count: ");
    Serial.println(readingCount);
  } else {
    Serial.println("SHT30 reading failed. Reading ignored.");
  }

  if (nh3Value > NH3_THRESHOLD) {
    Serial.println("Warning: High ammonia level detected.");
  }
}

// ================= CHECK LPG =================
void checkLPG() {
  currentLpgValue = readAverageAnalog(MQ6_PIN);

  Serial.println("----- LPG Check -----");
  Serial.print("MQ6 LPG Raw Value: ");
  Serial.println(currentLpgValue);

  Serial.print("Current LPG Threshold: ");
  Serial.println(LPG_THRESHOLD);

  if (currentLpgValue >= LPG_THRESHOLD) {
    lpgDetected = true;
    activateEmergency();

    if (!emergencyAlreadySent) {
      sendLpgAlertImmediately();
      emergencyAlreadySent = true;
    }
  } else {
    lpgDetected = false;
    emergencyAlreadySent = false;
    deactivateEmergency();
  }
}

// ================= EMERGENCY ACTION =================
void activateEmergency() {
  digitalWrite(BUZZER_PIN, HIGH);
  gasServo.write(SERVO_CLOSE_ANGLE);

  Serial.println("EMERGENCY: LPG detected!");
  Serial.println("Buzzer ON");
  Serial.println("Servo rotated 180 degrees to turn off regulator.");
}

void deactivateEmergency() {
  digitalWrite(BUZZER_PIN, LOW);
  gasServo.write(SERVO_NORMAL_ANGLE);

  Serial.println("LPG normal.");
  Serial.println("Buzzer OFF");
  Serial.println("Servo returned to normal position.");
}

// ================= SEND PERIODIC DATA =================
void sendPeriodicAverageData() {
  if (readingCount == 0) {
    Serial.println("No environmental readings available to send.");
    return;
  }

  float avgTemp = tempSum / readingCount;
  float avgHumidity = humiditySum / readingCount;
  int avgNH3 = nh3Sum / readingCount;

  strcpy(sensorData.nodeId, "ZONE_01");
  strcpy(sensorData.messageType, "PERIODIC");

  sensorData.avgTemperature = avgTemp;
  sensorData.avgHumidity = avgHumidity;
  sensorData.avgNH3 = avgNH3;

  sensorData.lpgRaw = currentLpgValue;
  sensorData.lpgThreshold = LPG_THRESHOLD;

  sensorData.lpgDetected = lpgDetected;
  sensorData.buzzerStatus = digitalRead(BUZZER_PIN);
  sensorData.servoClosed = lpgDetected;

  esp_err_t result = esp_now_send(
    gatewayAddress,
    (uint8_t *)&sensorData,
    sizeof(sensorData)
  );

  if (result == ESP_OK) {
    Serial.println("Periodic average data sent to gateway.");
  } else {
    Serial.println("Failed to send periodic data.");
  }

  tempSum = 0;
  humiditySum = 0;
  nh3Sum = 0;
  readingCount = 0;
}

// ================= SEND LPG ALERT IMMEDIATELY =================
void sendLpgAlertImmediately() {
  strcpy(sensorData.nodeId, "ZONE_01");
  strcpy(sensorData.messageType, "LPG_ALERT");

  sensorData.avgTemperature = 0;
  sensorData.avgHumidity = 0;
  sensorData.avgNH3 = 0;

  sensorData.lpgRaw = currentLpgValue;
  sensorData.lpgThreshold = LPG_THRESHOLD;

  sensorData.lpgDetected = true;
  sensorData.buzzerStatus = true;
  sensorData.servoClosed = true;

  esp_err_t result = esp_now_send(
    gatewayAddress,
    (uint8_t *)&sensorData,
    sizeof(sensorData)
  );

  if (result == ESP_OK) {
    Serial.println("Immediate LPG alert sent to gateway.");
  } else {
    Serial.println("Failed to send LPG alert.");
  }
}

// ================= ANALOG AVERAGING =================
int readAverageAnalog(int pin) {
  long total = 0;

  for (int i = 0; i < 10; i++) {
    total += analogRead(pin);
    delay(20);
  }

  return total / 10;
}
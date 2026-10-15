#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Wire.h>
#include <SoftwareSerial.h>

SoftwareSerial BTSerial(2, 3); // RX: D2, TX: D3
Adafruit_MPU6050 mpu;          // 허벅지 단독 센서

void setup() {
  Serial.begin(115200);        // PC 시리얼 모니터 확인용
  BTSerial.begin(9600);        // BT-05 블루투스 통신
  
  Wire.begin();

  // 단독 연결이므로 기본 주소 0x68 사용
  if (!mpu.begin(0x68)) {
    Serial.println("❌ Thigh MPU6050 (Nano) Connection Failed!");
    while (1); // 센서 연결 실패 시 대기
  }
  Serial.println("✅ Thigh MPU6050 (Nano) Ready!");
}

void loop() {
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  // 허벅지 패킷 구조: "$T|x,y,z"
  BTSerial.print("$T|");
  BTSerial.print(a.acceleration.x, 2); BTSerial.print(",");
  BTSerial.print(a.acceleration.y, 2); BTSerial.print(",");
  BTSerial.print(a.acceleration.z, 2);
  BTSerial.println(); // 줄바꿈 (패킷 끝)

  // PC 시리얼 모니터 출력 확인용
  Serial.print("$T|");
  Serial.print(a.acceleration.x, 2); Serial.print(",");
  Serial.print(a.acceleration.y, 2); Serial.print(",");
  Serial.println(a.acceleration.z, 2);

  delay(20); // 50Hz (실시간 운동 분석 최적화)
}
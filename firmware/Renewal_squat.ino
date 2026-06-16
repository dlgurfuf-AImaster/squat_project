#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Wire.h>
#include <SoftwareSerial.h>

// x y z 만 

SoftwareSerial BTSerial(2, 3); // RX, TX
Adafruit_MPU6050 mpu1; // 허리
Adafruit_MPU6050 mpu2; // 허벅지

void setup() {
  BTSerial.begin(9600);
  if (!mpu1.begin(0x68) || !mpu2.begin(0x69)) {
    while (1); // 센서 연결 안되면 대기
  }
}

void loop() {
  sensors_event_t a1, g1, t1, a2, g2, t2;
  mpu1.getEvent(&a1, &g1, &t1);
  mpu2.getEvent(&a2, &g2, &t2);

  // 패킷 시작 표시: '$' (실무에서 자주 쓰는 방식)
  BTSerial.print("$"); 
  
  // 허리 데이터
  BTSerial.print(a1.acceleration.x, 2); BTSerial.print(",");
  BTSerial.print(a1.acceleration.y, 2); BTSerial.print(",");
  BTSerial.print(a1.acceleration.z, 2); BTSerial.print("|"); // 센서 구분
  
  // 허벅지 데이터
  BTSerial.print(a2.acceleration.x, 2); BTSerial.print(",");
  BTSerial.print(a2.acceleration.y, 2); BTSerial.print(",");
  BTSerial.print(a2.acceleration.z, 2);
  
  // 패킷 끝 표시: 줄바꿈
  BTSerial.println();

  delay(20); // 50Hz (실시간 운동 분석에 최적화된 속도)
}
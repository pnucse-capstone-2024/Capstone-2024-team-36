# AlphaTron: AI 기반 실시간 객체 탐지 및 자동 대응 보안 시스템

## 1. 프로젝트 소개

### 1.1. 배경 및 필요성
- 미국의 가택 침입 증가로 인한 실시간 대응 보안 시스템 필요
- 농업 지대의 야생동물 관리를 위한 효율적인 모니터링 솔루션 요구
- 한국의 인구 감소로 인한 국경 경비 인력 부족 문제 해결 필요
- 이러한 다양한 환경에서 활용 가능한 지능형 감시 시스템의 수요 증가

### 1.2. 목표 및 주요 내용

#### 1.2.1. 핵심 기능
- 실시간 영상에서 객체(사람, 동물, 차량 등) 탐지 및 분류
- AI 기반 위협 수준 판단 및 자동 대응
- 실시간 모니터링 및 녹화 영상 관리
- 객체 추적 및 정밀 조준 시스템

#### 1.2.2. 기대 효과
- 24시간 실시간 감시 및 신속한 대응
- 인력 부족 문제 해결
- 다양한 환경(가정, 농장, 국경)에서 활용 가능
- 자동화된 위협 대응으로 효율적인 보안 관리

## 2. 상세 설계

### 2.1. 시스템 흐름도도
<!-- 시스템 전체 구성도 이미지 -->
![시스템 전체 흐름도](https://github.com/user-attachments/assets/73b4269b-e812-4555-b3e9-d3d9de642d35)


### 2.2. 사용 기술
#### Backend (AlphatronWebSocketServer)
- Java JDK 17
- Spring Boot 3.x
- H2 Database
- FFmpeg

#### Hardware Server
- Python 3.8+
- YOLO v8
- DeepOCSORT
- OpenCV
- Flask

#### Raspberry Pi
- Python 3.8+
- Picamera2
- RPi.GPIO
- Adafruit ServoKit

#### Frontend (AlphatronApp)
- Flutter
- WebSocket
- VLC Player

## 3. 설치 및 사용 방법

### 3.1. 필요 소프트웨어 설치

#### WebSocket 서버 설정
```bash
# JDK 17 설치
sudo apt install openjdk-17-jdk

# FFmpeg 설치
sudo apt install ffmpeg
```

#### 하드웨어 서버 설정
```bash
# Python 가상환경 생성 및 활성화
python -m venv venv
source venv/bin/activate  # Linux
venv\Scripts\activate     # Windows

# 필요 패키지 설치
pip install ultralytics opencv-python boxmot flask websocket-client
```

#### 라즈베리파이 설정
```bash
# 필요 패키지 설치
sudo apt install python3-picamera2
pip install adafruit-circuitpython-servokit opencv-python
```

### 3.2. 실행 방법

#### 1. 웹소켓 서버 설정 및 실행
1. AlphatronWebSocketServer 디렉토리를 웹소켓 서버용 컴퓨터로 전송
2. 웹소켓 서버 실행
    ```bash
    cd AlphatronWebSocketServer
    ./gradlew bootRun
    ```

#### 2. 하드웨어 연결 설정
1. 라즈베리파이에 하드웨어 연결
   - Camera Module 3 Wide: 카메라 포트에 연결
   - 1번 서보모터: GPIO18 핀에 연결
   - Servo Driver HAT: I2C 포트에 연결
     - 2번 서보모터: Servo Driver HAT의 0번 핀에 연결
2. 라즈베리파이와 하드웨어 서버용 컴퓨터를 이더넷 케이블로 연결
3. 네트워크 설정
   - 라즈베리파이 IP: 192.168.1.2
   - 하드웨어 서버 IP: 192.168.1.1
   - 서브넷 마스크: 255.255.255.0

#### 3. 하드웨어 서버 실행
1. 하드웨어 서버용 컴퓨터에서 Python 가상환경 활성화
    ```bash
    cd HardwareServer
    source venv/bin/activate  # Linux
    # 또는
    venv\Scripts\activate     # Windows
    ```
2. main.py 실행
    ```bash
    python main.py
    ```

#### 4. 라즈베리파이 프로그램 실행
1. 라즈베리파이에서 Python 가상환경 활성화
    ```bash
    source venv/bin/activate
    ```
2. alphatronRPI.py 실행
    ```bash
    python3 alphatronRPI.py
    ```

#### 5. 사용자 애플리케이션 실행
1. Flutter 앱 설치 (택 1)
    - 개발자 모드가 활성화된 안드로이드 기기를 컴퓨터와 USB로 연결하여 디버깅 모드로 실행
        ```bash
        cd AlphatronApp
        flutter run
        ```
    - 또는 APK 파일 생성 후 설치
        ```bash
        cd AlphatronApp
        flutter build apk
        ```
        생성된 APK 파일 경로: `AlphatronApp/build/app/outputs/flutter-apk/app-release.apk`

2. 앱 실행 및 서버 연결
   - 앱 실행 후 메인 화면에서 'Connect' 버튼 클릭
   - 실시간 영상 스트리밍 확인

## 4. 프로젝트 구조
```
Alphatron/
├── AlphatronApp/          # Flutter 애플리케이션
├── AlphatronWebSocketServer/  # 스프링 웹소켓 서버
├── HardwareServer/        # 객체 탐지/추적 서버
└── RaspberryPi/          # 라즈베리파이 제어 프로그램
```

### 4.1. AlphatronApp
<!-- 구성도 이미지 -->
![플러터 앱 흐름도](https://github.com/user-attachments/assets/f4c4a086-1922-441c-854b-f46b07677a79)

### 4.2. AlphatronWebSocketServer
<!-- 구성도 이미지 -->
![웹소켓 서버 흐름도](https://github.com/user-attachments/assets/e38fe23a-264f-46a8-8a9a-a2f8ce137bef)

### 4.3. HardwareServer
<!-- 구성도 이미지 -->
![하드웨어 서버 흐름도](https://github.com/user-attachments/assets/8350c245-d28c-4a1b-82a5-59d20a69ca83)

### 4.4. RaspberryPi
<!-- 구성도 이미지 -->
![라즈베리파이 흐름도](https://github.com/user-attachments/assets/67d46e84-3b06-44be-a787-8d8f88ec3df9)

## 5. 소개 및 시연 영상

[![2024년 전기 졸업과제 36 T1_민영대](http://img.youtube.com/vi/OJvjejhozVw/0.jpg)](https://www.youtube.com/watch?v=OJvjejhozVw)   

## 6. 팀 소개

- 김대영 (팀장)
    - 하드웨어 설계 및 제어 (alphatronRPI.py 코드 작성)
    - 시스템 통합 테스트
    - 프론트엔드 개발 (Flutter)
    - Contact: eodudrepublic@pusan.ac.kr

- 조영진
    - 웹소켓 서버 개발 (Spring Boot)
    - 프론트엔드 개발 (Flutter)
    - Contact: jhy0285@gmail.com
- 박민재
    - 하드웨어 서버 개발 (main.py 코드 작성)
    - AI 모델 통합 및 최적화
    - Contact: mjack123@pusan.ac.kr

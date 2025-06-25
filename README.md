# patrol_management_app

스마트 순찰 시스템

## Getting Started
Flutter 3.7.0 기반으로 개발된 스마트 순찰 시스템입니다.

## 기능
- NFC 기반 순찰 포인트 인식  
  → NFC 태그를 이용하여 순찰 지점 자동 인식
- QR 기반 순찰 포인트 인식  
  → QR코드 스캔을 통해 순찰 지점 인식
- 실시간 카메라 / 사진 / 동영상 촬영  
  → 순찰 중 이상 발견 시 사진/영상 촬영 및 등록 가능
- 순찰 결과 등록  
  → 순찰 지점별 결과 등록 (이상/이상없음)
- 순찰 기록 조회  
  → 순찰 이력 검색, 상세 조회 및 이미지/영상 결과 확인 가능

## 개발 환경
- Flutter 3.7.0
- Android / iOS 지원
- 서버: Spring Boot + MariaDB


## 📸 주요 화면 스크린샷
<p align="center">
  <img src="https://github.com/user-attachments/assets/8516ff91-8d04-4f5e-a705-7d432675d22b" width="45%" />
  <img src="https://github.com/user-attachments/assets/6663eaf8-c219-4936-8fc7-b26e8d7dcae5" width="45%" /><br>
  <img src="https://github.com/user-attachments/assets/b721d7b7-c611-443c-8e66-5ff0b12eb3d9" width="45%" />
  <img src="https://github.com/user-attachments/assets/719e4ab7-c082-486c-9dd2-f52960e1d276" width="45%" />
</p>


## 빌드
### Android

```bash
flutter build apk --release
```

## 기타
개발/운영 서버 API 환경설정은 assets/env/.env 파일로 관리


⚠️ 해당 프로젝트는 학습/포트폴리오용으로 제작되었으며, 상업적 목적이 아닙니다.



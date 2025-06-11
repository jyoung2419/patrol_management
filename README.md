# patrol_management_app

스마트 순찰 시스템

## Getting Started
Flutter 3.7.0 기반으로 개발된 스마트 순찰 시스템입니다.

## 기능
- NFC 기반 순찰 포인트 인식
- QR 기반 순찰 포인트 인식
- 실시간 카메라 / 사진 / 동영상 촬영
- 순찰 결과 등록
- 순찰 기록 조회

## 개발 환경
Flutter 3.7.0

Android / iOS 지원

서버: Spring Boot + MariaDB

## 빌드
### Android

```bash
flutter build apk --release
```

## 기타
개발/운영 서버 API 환경설정은 assets/env/.env 파일로 관리
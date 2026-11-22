---
name: android-log-capture
description: 외부 SDK 벤더(예: 광고 미디에이션 SDK)에 지원 요청을 보내기 위해, 연결된 Android 기기에서 앱의 SDK 로그를 adb로 수집하고 요청 단위로 잘라 헤더, 요약과 함께 zip으로 묶는다. "SDK 로그 뽑아줘", "벤더에 보낼 로그 정리해줘", "광고 안 뜨는 로그 수집해줘" 같은 요청 시 사용한다.
---

# Android SDK 로그 수집

벤더가 바로 읽을 수 있게, 문제가 된 요청 하나의 로그와 세션 전체 SDK 로그, 요약을 한 묶음으로 만든다.

## 1. 기기와 앱 상태 확인

```bash
adb devices
adb shell pidof <applicationId>
adb shell dumpsys package <applicationId> | grep versionName
```

- 기기가 안 잡히거나 앱이 실행 중이 아니면(`pidof` 결과 없음) 사용자에게 알리고 기다린다.
- `versionName`은 헤더에 쓴다.

## 2. 지우기 전에 기존 버퍼부터 덤프

재현이 이미 버퍼에 남아 있을 수 있다. `logcat -c`로 지우기 전에 현재 버퍼를 먼저 저장한다.

```bash
adb logcat -d --pid=<pid> > raw_session.log
```

버퍼에 재현 구간이 없을 때만 버퍼를 비우고 사용자에게 재현을 요청한 뒤 다시 덤프한다.

## 3. SDK verbose 로그 설정 확인

다시 빌드해 달라고 하기 전에, SDK 자체의 상세 로그 플래그(예: `AndroidManifest.xml`의 `meta-data`, 초기화 코드의 debug/log level 설정)가 이미 켜져 있는지 코드에서 확인한다. 이미 켜져 있으면 재빌드 없이 지금 로그로 진행한다.

## 4. 태그로 거르기

SDK 태그와 앱이 SDK를 감싸는 래퍼 뷰/클래스의 태그를 같이 남긴다.

```bash
grep -E "<SDK 태그>|<앱 래퍼 태그>" raw_session.log > sdk_session.log
```

## 5. 실패한 요청 블록 잘라내기

- placement/unit id로 실패한 요청을 찾는다.
- 그 요청의 "load" 시작부터 최종 실패 콜백까지를 잘라 단일 요청 로그로 만든다.
- 요청 id가 로그에 있으면 기록해 둔다.
- 미디에이션 SDK면 네트워크별로 어떤 순서로 시도했고 각각 어떤 이유로 실패했는지 체인을 정리한다.

## 6. 헤더

두 로그 파일 맨 위에 같은 헤더를 붙인다.

```
App: <applicationId> <versionName>
Device: <기기 모델>
Android: <버전> (SDK <API level>)
Placement: <placement id>
Captured: <YYYY-MM-DD HH:MM:SS> <타임존>
Request ID: <있으면>
```

기기 정보는 아래로 얻는다.

```bash
adb shell getprop ro.product.model
adb shell getprop ro.build.version.release
adb shell getprop ro.build.version.sdk
date "+%Y-%m-%d %H:%M:%S %Z"
```

## 7. 결과물

| 파일 | 내용 |
|---|---|
| `<placement>_single_request.log` | 헤더 + 실패한 요청 하나(load ~ 최종 실패 콜백) |
| `<placement>_full_session_sdk.log` | 헤더 + 세션 전체 SDK 로그 |
| `summary.txt` | 환경, 증상, 네트워크별 실패 체인 표, 요청 사항 |

- 파일명은 ASCII 영문으로 짓는다. 한글 파일명은 Windows에서 zip을 풀 때 깨질 수 있다.
- 세 파일을 zip으로 묶는다.

`summary.txt` 구성:

```
[Environment]
<헤더와 같은 내용>

[Symptom]
<무엇이 언제 어떻게 실패하는지 한두 줄>

[Failure chain]
| Order | Network | Result | Reason / error code |
|---|---|---|---|

[Request]
<벤더에게 확인받고 싶은 것>
```

## 8. 보내기 전 확인

- 로그에 광고 ID(advertising ID)나 사용자 식별자가 들어 있는지 grep으로 찾고, 있으면 그대로 보낼지 가릴지 사용자에게 묻는다. 묻기 전에 보내거나 임의로 지우지 않는다.
- 파일 이름을 바꾸거나 옮긴 뒤에는 결과 폴더와 zip이 실제로 있는지 다시 목록을 찍어 확인한다.

```bash
ls -la <결과 폴더>
unzip -l <결과>.zip
```

## 9. (선택) 회신 메일 초안

요청받으면 벤더에게 보낼 메일 초안을 쓴다. 환경, 증상, 첨부 파일 설명, 요청 사항 순서로 짧게 쓰고, 보내기는 사용자가 한다.

---
name: android-release-build
description: 사용자가 Android release APK/AAB 빌드를 요청하면 서명된 산출물을 만들고 서명, 버전, 크기, 16KB 페이지 정렬, 키 포함 여부를 검증한다. "릴리즈 빌드해줘", "서명된 APK 뽑아줘", "배포용 APK 만들어줘", "AAB 만들어줘" 같은 요청 시 사용. 빌드 요청이 없으면 실행하지 않는다.
---

# Android Release Build

서명된 release 산출물을 만들고, 배포 전에 확인해야 할 항목을 한 번에 검증한다.

## 전제

- 사용자가 빌드를 요청했을 때만 실행한다(`rules/working-style.md` 7번).
- 서명 키가 이미 있으면 새로 만들지 않는다. 키를 바꾸면 기존 설치본 위에 업데이트할 수 없고, 스토어 앱이면 업데이트 경로가 끊긴다. 키가 어디 있는지 모르면 묻는다.
- 키스토어 파일과 비밀번호는 저장소 밖(또는 `.gitignore`된 `local.properties`, `keystore.properties`)에 둔다. 비밀번호 값은 메모리, 대화, 커밋 어디에도 쓰지 않는다.

## 실행 순서

1. 서명 설정 확인: `signingConfigs.release`가 연결돼 있는지 본다. 없으면 산출물이 unsigned로 나오므로 빌드 전에 알린다.
2. 빌드: APK는 `./gradlew assembleRelease`, 스토어 업로드용은 `./gradlew bundleRelease`.
3. 서명 검증: 최신 build-tools의 `apksigner`를 쓴다.
   ```bash
   BT=$(ls -d ~/Library/Android/sdk/build-tools/* | sort -V | tail -1)
   "$BT/apksigner" verify --print-certs app/build/outputs/apk/release/app-release.apk
   ```
   서명자(CN)가 기대한 키인지 확인한다.
4. 버전 확인: `versionName`, `versionCode`가 이번 배포에 맞게 올라갔는지 본다(`aapt2 dump badging` 또는 빌드 스크립트).
5. 크기 확인: 크기가 예상보다 크면 원인을 본다. 실기기 배포만 대상이면 `ndk { abiFilters += "arm64-v8a" }`로 ABI를 줄일 수 있다(네이티브 라이브러리가 큰 앱에서 효과가 크다).
6. 16KB 페이지 정렬: 64비트 ABI의 `.so`마다 ELF `PT_LOAD` 세그먼트의 `p_align`이 16384 이상인지 본다. Android 15+ 16KB 기기와 스토어 요구사항에 걸린다.
   ```python
   import struct, sys, zipfile
   with zipfile.ZipFile(sys.argv[1]) as z:
       for n in z.namelist():
           if not n.endswith(".so") or not ("arm64-v8a" in n or "x86_64" in n):
               continue
           d = z.read(n)
           phoff, = struct.unpack_from("<Q", d, 0x20)
           phentsize, phnum = struct.unpack_from("<HH", d, 0x36)
           aligns = [struct.unpack_from("<Q", d, phoff + i * phentsize + 0x30)[0]
                     for i in range(phnum)
                     if struct.unpack_from("<I", d, phoff + i * phentsize)[0] == 1]
           print("OK " if min(aligns) >= 16384 else "BAD", min(aligns), n)
   ```
7. 키 포함 여부: 외부 배포용이면 `BuildConfig`의 API 키 필드가 비었는지 확인한다. 값을 출력하지 말고 길이만 본다(`rules/llm-features.md` 1번).
8. 결과 보고: 산출물 경로, 서명자, 버전, 크기, 16KB 결과, 키 포함 여부.

## 주의

- 기기에 debug 빌드가 깔려 있으면 서명이 달라 release 설치가 실패한다. 이때는 사용자에게 기존 앱 삭제가 필요하다고 알린다(데이터가 지워진다).
- 업로드(Firebase App Distribution, 스토어, 릴리즈 페이지)는 사용자가 명시적으로 요청했을 때만 한다.
- 배포 직전이면 `release-obfuscation-check` 스킬로 R8 점검을 제안한다(`rules/security.md` 2번).

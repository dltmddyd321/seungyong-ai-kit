---
name: release-obfuscation-check
description: Android 빌드 업로드나 배포 전에 R8 난독화로 Gson/리플렉션 직렬화가 깨지지 않는지 점검한다. 사용자가 버전 빌드 커밋, 테스트 배포, 스토어 업로드를 하려는 게 보이면 이 점검을 먼저 제안하고, 사용자가 요청하면 실행한다.
---

# 배포 전 난독화 점검

## 언제

사용자가 빌드 업로드나 배포(버전 빌드 커밋, 테스트 배포, 스토어 업로드 등)를 하려는 게 보이면, 배포를 직접 실행하지 말고 이 점검을 먼저 하자고 제안한다. 점검은 사용자가 요청하면 그때 한다.

## 왜

debug 빌드가 `minifyEnabled false`라면 난독화 문제는 release 빌드에서만 드러난다. ProGuard keep 대상 패키지 밖에 있던 캐시용 클래스가 난독화되어, Gson 직렬화 때 `multiple JSON fields named 'a'` 크래시가 release에서만 난 사례가 있다.

## 점검 항목

1. R8이 통과하는지 확인한다.
   ```bash
   ./gradlew :app:minifyReleaseWithR8
   ```
2. 이번 변경에서 Gson이나 리플렉션으로 직렬화되는 클래스를 찾는다. 특히 `FieldNamingPolicy`를 쓰거나 필드 이름을 키로 쓰는 곳을 본다. 각 클래스가 아래 중 하나로 보호되는지 확인한다.
   - `proguard-rules.pro`의 keep 대상 패키지 안에 있다
   - `@Keep`이 붙어 있다
   - 모든 필드에 `@SerializedName`이 있다
3. `app/build/outputs/mapping/release/mapping.txt`에서 해당 클래스의 필드 이름이 바뀌지 않았는지 확인한다.
4. release 빌드를 설치해 핵심 화면(결제, 동기화, 설정 반영 등)이 동작하는지 확인한다. 설치와 실기기 확인은 사용자가 한다.

## 보고

- R8 통과 여부
- 점검한 직렬화 클래스 목록과 각각의 보호 방식(패키지 / `@Keep` / `@SerializedName` / 보호 안 됨)
- 보호되지 않은 클래스와 제안하는 조치. 조치는 승인받은 뒤에 적용한다.
- 사용자가 실기기에서 확인할 화면 목록

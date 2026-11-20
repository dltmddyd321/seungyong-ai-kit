---
name: android-api-task
description: Android 프로젝트에서 API 엔드포인트와 Example Response JSON을 입력받아, 프로젝트의 기존 네트워크 패턴을 따르는 코드(응답 모델, Retrofit 인터페이스, 호출 래퍼 클래스)를 생성한다. "/android-api-task", "API Task 만들어줘", "이 API 코드 생성해줘" 요청 시 사용한다.
---

# Android API 코드 생성

엔드포인트 + Example JSON → 응답 모델 + Retrofit 인터페이스 + 호출 래퍼.
새 패턴을 만들지 않고, 프로젝트에 이미 있는 네트워크 베이스 클래스와 같은 방식으로 만든다.

## 입력 형식

```
Endpoint: GET api/coins/free/list
Response: { "err": 0, "message": "ok", "list": [{ "name": "보너스 코인", "issuedCnt": 10, "remainCnt": 8, "expireTime": 1745164800000, "expired": false }] }
Description: 무료 코인 목록 조회 (선택)
```

- `Endpoint`: HTTP 메서드 + 경로
- `Response`: Example JSON 응답(실제 서버 응답 또는 설계된 구조)
- `Description`: 화면 설명이나 스크린샷 맥락(선택)

## 실행 절차

### Step 1: 레퍼런스 파일 읽기

코드를 쓰기 전에 반드시 아래를 먼저 읽고 현재 패턴을 확인한다.

- 프로젝트의 네트워크 베이스 클래스(인증 헤더, 재시도, 결과 래핑을 담당하는 클래스). 프로젝트 `AGENTS.md`의 Architecture 섹션에 적혀 있으면 그것을, 없으면 grep으로 찾는다.
  ```bash
  grep -rln "abstract class .*Api\|getApi(\|Retrofit.Builder" app/src/main/java --include="*.kt" --include="*.java"
  ```
- 그 베이스 클래스를 쓰는 기존 호출 래퍼 하나와 그 응답 모델 하나. 가능하면 이번 API와 같은 도메인의 것.

레퍼런스로 쓸 파일 경로를 프로젝트 `AGENTS.md`나 이 스킬 하단에 적어 두면 다음부터 탐색을 건너뛸 수 있다.

### Step 2: 파일 배치 결정

레퍼런스 파일이 놓인 위치를 따른다. 도메인별로 패키지가 나뉘어 있으면(예: 결제·스토어 관련 API는 별도 패키지) 경로 키워드로 어느 쪽인지 판단하고, 애매하면 묻는다.

### Step 3: 클래스 이름 추론

엔드포인트 경로의 마지막 세그먼트들을 PascalCase로 조합한다. 접미사(`Result`, `ApiTask` 등)는 레퍼런스 파일의 명명 규칙을 따른다.

| 경로 예시 | 결과 |
|---|---|
| `GET api/coins/free/list` | `FreeCoinListResult`, `GetFreeCoinListApiTask` |
| `GET api/items/categories` | `ItemCategoriesResult`, `GetItemCategoriesApiTask` |
| `GET api/profile` | `ProfileResult`, `GetProfileApiTask` |
| `POST api/coins/charge` | `ChargeCoinResult`, `ChargeCoinApiTask` |

HTTP 메서드에 따른 동사:
- `GET` → `Get`
- `POST` → 동작 명사(`Charge`, `Create`, `Update` 등)
- `DELETE` → `Delete`
- `PUT` / `PATCH` → `Update`

### Step 4: JSON → Kotlin 모델 변환

| JSON 타입 | Kotlin 타입 |
|---|---|
| string | `String` |
| number(정수) | `Int` |
| number(소수) | `Double` |
| boolean | `Boolean` |
| 13자리 이상 숫자(epoch millis) | `Long` |
| null이거나 null 가능 | `Type?` |
| array | `List<ItemType>` |
| object(중첩) | 별도 `data class`로 추출 |

- 필드명은 레퍼런스 모델과 같은 방식으로 정한다(JSON 키 그대로인지, `@SerializedName`을 쓰는지, 직렬화 라이브러리의 naming policy에 맡기는지).
- 최상위 응답에 공통 필드(예: `err: Int`, `message: String`)가 있으면 레퍼런스 모델과 같은 방식으로 포함한다.
- 직렬화되는 모델은 release 난독화 대상이 될 수 있다. 레퍼런스 모델이 있는 패키지가 keep 규칙으로 보호되는지 확인하고, 다른 패키지에 둔다면 `release-obfuscation-check` 스킬의 기준으로 확인한다.

### Step 5: 코드 생성

모델 파일:

```kotlin
package {레퍼런스 모델과 같은 패키지}

data class XxxResult(
    val err: Int,
    val message: String,
    val list: List<XxxItem>?,
)

data class XxxItem(
    val name: String,
    val expireTime: Long,
)
```

호출 래퍼 + Retrofit 인터페이스(레퍼런스가 베이스 클래스를 상속하는 구조일 때의 예):

```kotlin
class GetXxxApiTask(/* 생성자 파라미터 */) : {베이스 클래스}<XxxResult?>() {
    override fun execute(): {결과 래퍼}<XxxResult?> {
        val response = getApi(GetXxxApi::class.java).getXxx(headers).execute()
        return {결과 래퍼}(response.body(), response.code())
    }
}

interface GetXxxApi {
    @GET("api/경로")
    fun getXxx(
        @HeaderMap headers: HashMap<String, String>
    ): Call<XxxResult>
}
```

시그니처, 헤더 전달 방식, 결과 래핑 방식은 위 예가 아니라 레퍼런스 파일을 그대로 따른다.

파라미터 판단:
- **언어 파라미터:** 응답에 지역화된 문자열(이름, 설명 등)이 있으면 `lang` 같은 쿼리 파라미터를 추가한다. 값은 레퍼런스 코드가 현재 언어를 얻는 방식을 그대로 쓰고, 생성자로 받지 않는다.
- **페이징:** 응답에 `totalPages`, `last`, `content`, `page` 등이 있으면 page 파라미터를 추가하고 생성자로 받는다(`class GetXxxApiTask(val page: Int)`).
- **body / path variable:** 엔드포인트와 입력에 맞춰 `@Body`, `@Path`, `@Query`를 붙인다.

### Step 6: 파일 작성과 검증

1. 모델 파일 Write
2. 호출 래퍼 파일 Write
3. Read/grep으로 import, 타입, 패키지 경로를 정적으로 확인한다. 컴파일(`./gradlew compile<Variant>Kotlin`)은 사용자가 요청했을 때만 돌리고, 실패하면 고치기 전에 원인과 수정안을 보고한다.

## 출력 요약 형식

```
생성된 파일:
- [XxxResult.kt](경로) — 응답 모델
- [GetXxxApiTask.kt](경로) — 호출 래퍼

사용 예시:
{레퍼런스 코드에서 쓰는 호출 방식 그대로}
```

## 주의사항

- 실제 서버 엔드포인트가 아직 없을 수 있으므로 경로는 사용자가 준 그대로 쓴다.
- `!!` 금지. nullable은 `?`로 처리한다.
- `var` 대신 `val`을 쓴다.
- `GlobalScope`를 쓰지 않는다.
- 파일을 쓰기 전에 반드시 레퍼런스 파일을 읽어 현재 패턴을 확인한다.

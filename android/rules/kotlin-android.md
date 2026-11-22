# Kotlin/Android 규칙

Android/Kotlin 프로젝트에서만 쓰는 규칙이다. 범용 규칙(`rules/`)의 Android 쪽 구체 내용을 여기에 둔다. `./install.sh --with-android`로 설치하면 import된다.

## 1. GoF 패턴의 Kotlin/Android 관용 표현

`rules/code-design.md` 1번 "증상 → 패턴" 표의 Android/Kotlin 대응이다. Kotlin 관용구나 프레임워크(`data class`, Hilt Scope, `StateFlow` 등)가 이미 그 패턴 역할을 하면 고전 GoF 구현으로 되돌리지 않는다.

| 증상 | 패턴 | Kotlin/Android에서의 관용 표현 |
|---|---|---|
| 생성자 파라미터가 많거나 선택 옵션이 많다 | Builder | `data class`의 named parameter와 default value로 대체되는 경우가 많다. 외부 라이브러리 연동이나 Java 상호운용이 필요할 때만 Builder 유지 |
| DB, 네트워크 클라이언트처럼 인스턴스가 하나여야 한다 | Singleton | `object`로 직접 만들기보다 Hilt `@Singleton`/`@ActivityScoped` 같은 Scope로 관리(생명주기 제어, 의존성 명시, 초기화 순서, 테스트 격리) |
| 생성할 객체 타입을 호출 시점에 정해야 한다 | Factory Method | `ViewModelProvider.Factory`, `Fragment.newInstance()`. `@HiltViewModel` + `@AssistedInject`/`@AssistedFactory`로 대체 가능하면 그쪽 우선 |
| 쓰려는 인터페이스와 라이브러리/레거시 인터페이스가 다르다 | Adapter | `RecyclerView.Adapter`, 콜백 API를 `callbackFlow`로 감싸기 |
| 기존 클래스 수정 없이 기능을 덧붙이고 싶다 | Decorator | `ContextWrapper`, OkHttp `Interceptor` 체인, Compose `Modifier` 체이닝 |
| 여러 서브시스템을 하나의 단순한 인터페이스로 감추고 싶다 | Facade | Retrofit 인터페이스가 OkHttp, 직렬화, 스레드 관리를 감추는 구조 |
| 실제 객체 접근을 중간에서 제어해야 한다 | Proxy | Retrofit 동적 프록시, ViewModel이 View의 Repository 직접 접근을 막는 구조 |
| 상태가 바뀌면 연관 객체가 자동으로 반응해야 한다 | Observer | `StateFlow` + `collectAsStateWithLifecycle` |
| 같은 동작인데 상황에 따라 구현이 달라진다(로그인 방식, 정렬 방식 등) | Strategy | 인터페이스 하나 + 구현 여러 개 + Context는 인터페이스에만 의존. `LayoutManager` 교체 |
| 작업을 나중에, 또는 조건부로 실행·취소해야 한다 | Command | `WorkManager`의 Worker(Command)와 `enqueue()`(Invoker) |

## 2. Kotlin/Android 기본 스타일

- 숫자를 붙인 변수명(`option0`, `temp1`)을 쓰지 않는다. 뜻이 드러나는 영어 이름을 쓴다.
- `var`를 줄이고 `val`을 쓴다.
- `!!`를 쓰지 않는다. `?.let`이나 `?:`를 쓴다. Java 메서드가 `null`을 반환할 수 있다는 점에 주의한다.
- `GlobalScope`를 쓰지 않는다. IO는 `Dispatchers.IO`, UI는 `Dispatchers.Main`이나 `lifecycleScope`를 쓴다.
- 캐시와 리스트 메모리(OOM), 스레드 안전성을 항상 고려한다. 스레드 간 공유가 안 되는 DB 인스턴스(Realm 등)는 스레드마다 따로 연다.
- 로깅 방식, 텍스트 크기 단위(sp/dp) 같은 프로젝트별 관례는 프로젝트 `AGENTS.md`에 적고 그것을 따른다.
- 변경 전 영향 범위를 볼 때 Java/Kotlin 혼용 프로젝트라면 두 언어 간 교차 참조를 반드시 본다.

## 3. 보안 감사 제안 대상 (Android)

`rules/security.md` 1번의 Android 구체 항목이다.

- 딥링크, App Link, intent 처리
- exported 컴포넌트, PendingIntent
- WebView
- `signingConfig`, `debuggable`. 예: debug 빌드가 release 키로 서명되고 `debuggable`이며 `applicationId` 접미사가 없으면, 유출됐을 때 운영 앱 위에 설치될 수 있다.

## 4. 배포 전 R8 점검

`rules/security.md` 2번의 Android 구체 항목이다. 빌드 업로드나 배포가 보이면 `release-obfuscation-check` 스킬의 R8/Gson 점검을 먼저 제안한다. Gson으로 직렬화하던 클래스가 난독화되어 release에서만 크래시가 난 사례가 있다.

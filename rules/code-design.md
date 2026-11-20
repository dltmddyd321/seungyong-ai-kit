# 코드 설계 규칙

## 1. 구조가 이상하면 GoF 패턴으로 증상을 진단한다

코드를 쓰거나 리뷰하다가 "구조가 뭔가 이상하다"는 느낌이 오면, 아래 "증상 → 패턴" 표에서 맞는 패턴을 먼저 찾는다.

**Why:** AI가 짠 코드가 구조적으로 이상해도 디자인 패턴을 모르면 문제로 인식하지 못하고 넘어가게 된다. 패턴을 알아야 "이 부분은 Strategy로 다시 짜 줘" 같은 구체적인 지시와 판단이 가능하다.

### 증상 → 패턴 대응표 (Android/Kotlin)

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

### 판단 절차

1. 위화감이 들면 표에서 증상에 맞는 패턴을 찾는다.
2. 억지로 끼워 맞추지 않는다. 표는 암기용이 아니라 문제 인식용이다. 해당 없으면 넘어간다.
3. Kotlin 관용구나 프레임워크(`data class`, Hilt Scope, `StateFlow` 등)가 이미 그 패턴의 역할을 하고 있으면 고전적인 GoF 구현으로 되돌리지 않는다. 이미 패턴이 적용된 것으로 본다.
4. 이미 알려진 구체적인 버그 패턴은 이 표보다 프로젝트별 기록을 우선한다. 이 표는 설계 판단 기준이지 버그 목록이 아니다.

## 2. 반복되는 UI 패턴은 공용 정의 하나로

반복되는 시각 패턴(버튼, pill, 뱃지 등)은 공용 스타일/컴포넌트로 한 번만 정의하고 모든 곳에서 그것을 쓴다. 컴포넌트마다 비슷한 padding, border, font-size를 따로 들고 있지 않게 한다.

- 새 버튼이나 뱃지를 만들기 전에 이미 있는 공용 스타일부터 확인한다.
- 중복 스타일 때문에 생긴 버그는 각각 숫자를 맞추지 말고 공용 정의로 통합해서 고친다.
- 컨트롤류는 padding만으로 크기를 잡지 말고 높이를 명시한다(웹이면 `height` + `box-sizing: border-box`).
- 중복 UI는 Composable로, 중복 로직은 내부 함수로 추출한다.

**Why:** 같은 줄의 버튼 세 개가 높이가 제각각이었다. `<a>` 하나와 `<button>` 둘을 각각 손으로 스타일링했는데, 두 요소의 기본 크기 계산이 달라 padding만으로는 맞춰지지 않았다. "작은 사이트라도 디자인 시스템 개념을 갖춰서 구성해야 한다"는 지적을 받았다.

## 3. Kotlin/Android 기본 스타일

- 숫자를 붙인 변수명(`option0`, `temp1`)을 쓰지 않는다. 뜻이 드러나는 영어 이름을 쓴다.
- `var`를 줄이고 `val`을 쓴다.
- `!!`를 쓰지 않는다. `?.let`이나 `?:`를 쓴다. Java 메서드가 `null`을 반환할 수 있다는 점에 주의한다.
- `GlobalScope`를 쓰지 않는다. IO는 `Dispatchers.IO`, UI는 `Dispatchers.Main`이나 `lifecycleScope`를 쓴다.
- 캐시와 리스트 메모리(OOM), 스레드 안전성을 항상 고려한다. 스레드 간 공유가 안 되는 DB 인스턴스(Realm 등)는 스레드마다 따로 연다.
- 로깅 방식, 텍스트 크기 단위(sp/dp) 같은 프로젝트별 관례는 프로젝트 `AGENTS.md`에 적고 그것을 따른다.

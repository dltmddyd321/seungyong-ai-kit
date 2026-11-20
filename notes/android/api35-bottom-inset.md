# Android 15(API 35+) edge-to-edge 하단 inset 이중 적용

## 증상

API 35 이상에서 내비게이션 바 위에 내비게이션 바와 같은 높이의 빈 띠가 생긴다.

## 원인

앱 공통 코드에서 `android.R.id.content`에 하단 패딩(내비게이션 바 높이)을 주고 insets는 그대로 아래로 넘기면, `fitsSystemWindows="true"`인 루트(특히 `CoordinatorLayout`)가 하단을 한 번 더 뺀다. Compose의 `Scaffold`나 `systemBarsPadding`을 쓰는 화면도 같은 문제가 생긴다.

## 해법

content에 붙인 insets 리스너에서 아래로 넘기는 insets의 하단을 두 곳 모두 0으로 만든다.

```kotlin
ViewCompat.setOnApplyWindowInsetsListener(content) { view, insets ->
    val nav = insets.getInsets(WindowInsetsCompat.Type.navigationBars())
    val system = insets.systemWindowInsets
    view.updatePadding(bottom = nav.bottom)
    WindowInsetsCompat.Builder(insets)
        .setInsets(WindowInsetsCompat.Type.navigationBars(), Insets.of(nav.left, nav.top, nav.right, 0))
        .setSystemWindowInsets(Insets.of(system.left, system.top, system.right, 0))
        .build()
}
```

- `navigationBars`만 0으로 바꾸면 `systemWindowInsets` 하단이 그대로 남는다. `CoordinatorLayout`은 `getSystemWindowInsetBottom`을 읽기 때문에 효과가 없다.
- 공통 헬퍼로 만들어 `fitsSystemWindows` 루트 XML 화면과 `Scaffold`/`systemBarsPadding` Compose 화면에서 `setContentView` 직후 호출한다.
- 하단 inset을 직접 처리하는 화면(하단 바를 직접 그리는 메인 화면 등)은 제외한다.

## 교훈

`navigationBars`만 바꾼 첫 시도를 여러 화면에 한꺼번에 넣었다가 효과가 없어 전부 되돌렸다. inset 처리는 실기기 로그로 두 값(`navigationBars`, `systemWindowInsets`) 하단을 모두 찍어 확인한 뒤 넓게 적용한다.

## 덤

Hilt 프로젝트에서 증분 `installDebug` 뒤 `*_GeneratedInjector` 누락 크래시가 나면 `clean installDebug`로 다시 설치한다.

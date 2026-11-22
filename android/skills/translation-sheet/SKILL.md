---
name: translation-sheet
description: 번역 시트(다국어 표) 데이터를 받아 Android strings.xml 여러 로케일에 반영한다. 사용자가 ko/en/ja/zh 같은 번역 표를 붙여넣으며 "다국어 처리", "번역 반영", "strings 정리", "다국어 확정됐어" 등으로 요청할 때 사용한다. 시트 원문을 한 글자도 바꾸지 않고 반영하고, 대응 키를 못 찾거나 애매한 건 반드시 사용자에게 묻는다.
---

## 목적

번역 담당자가 확정한 다국어 시트를 `strings.xml` 로케일별 파일에 정확히 반영한다.
**시트가 유일한 진실 원천(SSOT)이고, 에이전트는 문구를 판단하지 않는다.**

## 절대 규칙

1. **시트 원문을 그대로 반영한다.** 띄어쓰기, 마침표 유무, 전각/반각 기호(`：` vs `:`), 쉼표(`、`)를 임의로 교정하지 않는다.
   - 시트 ko가 `인증 코드 전송에 실패했습니다`(마침표 없음)면 마침표 없이 넣는다.
   - 다른 행들이 마침표로 끝나도 "일관성"을 이유로 추가하지 않는다.
   - 오타처럼 보여도 고치지 않는다. 이상하면 묻는다.
2. **추측 금지.** 대응 키가 애매하면 사용자에게 묻는다. 조용히 결정하지 않는다. 질문이 길거나 표가 필요하면 `AskUserQuestion` 대신 일반 텍스트로 묻는다.
3. **placeholder는 보존한다.** `%1$s`, `%1$d`, `%%` 등이 기존 값에 있으면 시트에 없어도 유지 여부를 묻는다.
   로케일 간 placeholder 개수나 형식이 어긋나면 lint `StringFormatMatches`가 터진다.
4. **시트에 없는 기존 키는 건드리지 않는다.**

## 로케일 매핑

프로젝트의 실제 로케일 디렉터리를 먼저 확인한다(`ls app/src/main/res | grep values`). 예시:

| 디렉터리 | 언어 | 비고 |
|---|---|---|
| `app/src/main/res/values/strings.xml` | English | base(기본) 로케일 |
| `app/src/main/res/values-ko/strings.xml` | 한국어 | |
| `app/src/main/res/values-ja/strings.xml` | 日本語 | |
| `app/src/main/res/values-zh/strings.xml` | 中文 | |

시트 컬럼 순서는 회차마다 다를 수 있다. 첫 행 몇 개를 실제 파일 값과 대조해 **어느 컬럼이 어느 언어인지 먼저 확정**한다.

## 수행 순서

### 1. 시트 파싱 + 키 매핑

시트 각 행의 ko(또는 가장 익숙한 언어) 텍스트로 기존 키를 역추적한다.

```bash
# 기능 영역의 기존 키를 한 번에 훑는다 (base 로케일 기준)
grep -n "otp_\|verification\|resend" app/src/main/res/values/strings.xml

# 특정 문구로 키 찾기
grep -rn "찾을 문구" app/src/main/res/values-ko/strings.xml
```

기존 키들은 보통 한 블록에 모여 있다. 한 키를 찾으면 그 주변 20줄을 읽어 같은 기능의 형제 키를 한꺼번에 확보한다.

### 2. 하드코딩 여부 확인

```bash
# Kotlin/Java 한글 리터럴 (주석 제외하고 확인)
grep -n '"[^"]*[가-힣][^"]*"' <대상 파일>

# XML 하드코딩 text/hint
grep -n 'android:text="[^@]\|android:hint="[^@]' app/src/main/res/layout/<레이아웃>.xml
```

하드코딩이 있으면 `@string/키` 또는 `getString(R.string.키)`로 교체한다.
Compose 화면이면 `findViewById`/ViewBinding이 아니라 컴포저블 안에서 처리한다.

### 3. 사용처 확인 (미사용 키 탐지)

```bash
for k in 키1 키2 키3; do
  n=$(grep -rn "R\.string\.$k\b\|@string/$k\b" app/src/main/java app/src/main/res \
      --include="*.kt" --include="*.java" --include="*.xml" 2>/dev/null \
      | grep -v "res/values" | wc -l | tr -d ' ')
  echo "[$n] $k"
done
```

`[0]`인 키는 사용처가 없다는 뜻이다. 반영은 하되 사용자에게 보고한다.

### 4. 애매한 건 묻는다

자주 나오는 애매함 유형:

| 유형 | 증상 | 물어볼 것 |
|---|---|---|
| placeholder 불일치 | 기존 값에 `%1$s`가 있는데 시트엔 없음 | placeholder 유지 + 시트 문구 병합? 코드를 고쳐 분리? |
| `\n` 강제 개행 | 기존 값에 `\n`이 있는데 시트는 한 줄 | `\n` 유지? 제거? (시트 ja가 `\n` 자리에 `、`를 넣었다면 제거 의도일 가능성) |
| 대응 키 없음 | 시트 행의 문구를 가진 키가 없음 | 신규 키 추가? 기존 키 값 교체? 이번엔 보류? |

**서버가 내려주는 메시지**(에러 응답 `message` 필드 등)가 시트에 있으면 특히 주의한다.
클라이언트에 문자열을 넣어도 서버 메시지가 우선 표시되면 의미가 없다. 반드시 묻는다.

### 5. 스크립트로 일괄 반영

행×로케일이 많으면(20개 이상) Edit를 반복하지 말고 스크립트를 쓴다.
임시 디렉터리에 Python 스크립트를 만들어 **변경 전/후를 전부 출력**하게 한다(검증 가능성 확보).

```python
import re, pathlib
RES = pathlib.Path("app/src/main/res")
LOCALES = ["values", "values-ko", "values-ja", "values-zh"]
DATA = {
    "key_name": {
        "values":    r"English text",
        "values-ko": r"한국어 텍스트",
        "values-ja": r"日本語テキスト",
        "values-zh": r"中文文本",
    },
}
for locale in LOCALES:
    path = RES / locale / "strings.xml"
    text = path.read_text(encoding="utf-8")
    for key, per_locale in DATA.items():
        pattern = re.compile(r'(<string name="' + re.escape(key) + r'">)(.*?)(</string>)')
        m = pattern.search(text)
        if not m:
            print(f"!! 키 없음: {locale}/{key}")
            continue
        new_val = per_locale[locale]
        if m.group(2) == new_val:
            continue
        print(f"[{locale}] {key}\n    - {m.group(2)}\n    + {new_val}")
        text = text[:m.start()] + m.group(1) + new_val + m.group(3) + text[m.end():]
    path.write_text(text, encoding="utf-8")
```

주의사항:
- Python raw string(`r"..."`)으로 값을 적어 `\n`, `\'`가 의도대로 들어가게 한다.
- 영어 아포스트로피는 `\'`로 이스케이프한다(`Didn\'t`, `don\'t`). 안 하면 Android가 경고하거나 무시한다.
- `&`, `<`는 XML 이스케이프(`&amp;`, `&lt;`)가 필요하다.

### 6. 검증

빌드 태스크는 사용자가 요청했거나 이 단계 실행에 동의한 경우에만 돌린다.

```bash
./gradlew merge<Variant>Resources   # XML 유효성 + placeholder 정합성 (빠름)
```

코드도 함께 고쳤다면:
```bash
./gradlew compile<Variant>Kotlin
```

번역 작업과 무관한 기존 경고는 따로 구분해서 보고하고 고치지 않는다.

### 7. 보고

작업 후 아래를 정리해 보고한다.

- 변경된 키 수 / 이미 동일했던 키 수
- 시트에 있는데 대응 키를 못 찾은 행
- 사용처가 없는 키
- 시트에 없어서 손대지 않은 기존 키 목록
- 보류한 행과 그 이유

## 부록: 시트 변경분 알림 스크립트 (`scripts/`)

번역 시트에서 새로 생기거나 바뀐 행만 골라 `strings.xml` 붙여넣기용 스니펫으로 정리하고 메일과 macOS 알림으로 보내는 스크립트다. 사용자가 "번역 시트 정리해줘", "새 번역 있어?"처럼 요청할 때만 실행한다. 자동 스케줄은 두지 않는다(주기 실행에서 요청 시 실행으로 줄였다).

```bash
zsh <설치 경로>/watch.sh
```

| 파일 | 역할 |
|---|---|
| `watch.sh` | 시트 수정 시각 확인 → xlsx 내보내기 → 비교 → 메일·알림 |
| `diff_sheet.py` | 이전 스냅샷과 비교해 새/변경 행만 추출, 스니펫 생성. 종료 코드 0 = 변경 있음, 3 = 변경 없음, 4 = 첫 실행(기준 스냅샷만 저장) |
| `xlsx_read.py` | 표준 라이브러리만 쓰는 xlsx 리더 |
| `config.example.env` | 설정 예시. `config.env`로 복사해 값을 채운다 |

설정(`config.env`):
- `TW_SHEET_FILE_ID`: Google Drive 시트 파일 ID
- `TW_RECIPIENT`: 결과를 받을 메일 주소
- `TW_RES_DIR`: 프로젝트의 `app/src/main/res` 경로
- `TW_TAB`: 읽을 시트 탭 이름
- `TW_LOCALES`: `[언어, [시트 헤더 후보], values 디렉터리]` 목록. 키 역추적에 쓰므로 `ko` 항목이 있어야 한다.
- `TW_HOME`(선택): 상태와 결과를 둘 디렉터리. 기본값은 스크립트가 있는 디렉터리.

필요한 것: `composio` CLI(googledrive, gmail 연결), `claude` CLI(신규 키 이름 제안), Python 3, macOS(`osascript` 알림).

동작:
- 시트 파일 수정 시각이 지난 확인 때와 같으면 아무것도 보내지 않고 끝난다. 이 경우 사용자에게 "변경 없음"이라고 알린다.
- 스냅샷(`state/snapshot.json`)과 비교해 새/변경 행만 고르고, `strings.xml`에 이미 같은 값이 있으면 뺀다.
- final 열이 비어 있는 행은 "번역 미확정"으로 따로 표시하고 스니펫에서 뺀다.
- 신규 문구의 키 이름은 `claude -p`(도구 없음)가 기존 키를 예시로 프로젝트 명명 규칙(소문자 snake_case, 기능 접두어 + `_title`/`_desc` 같은 접미어)에 맞춰 제안한다.
- 결과는 `inbox/*.md`에 남고 메일 본문으로 전송된다.
- 프로젝트에 반영하지는 않는다. 반영 요청이 오면 이 스킬 본문의 규칙(원문 그대로, 애매하면 질문)을 따른다.

## 사후 커밋 메시지

작업이 끝나면 `commit-message` 스킬 규칙에 따라 커밋 메시지를 텍스트로 제공한다.
`.claude/current_issue.md`가 있으면 그 `commit_prefix`를 첫 줄로 고정한다.

---
name: play-vitals-query
description: Google Play Developer Reporting API로 Android Vitals의 크래시율, ANR율, LMK율을 직접 조회한다. "Play Vitals 조회해줘", "크래시율 추이 봐줘", "ANR 비율 확인해줘" 같은 요청 시 사용한다.
---

# Play Vitals 조회

Play Console 화면 대신 Play Developer Reporting API로 Vitals 지표를 기간별로 조회한다.

## 준비

placeholder:
- `<PACKAGE_NAME>`: 앱의 applicationId
- `<QUOTA_PROJECT>`: API를 활성화한 GCP 프로젝트 ID

1. `<QUOTA_PROJECT>`에서 `playdeveloperreporting.googleapis.com`을 활성화한다.
2. Application Default Credentials로 로그인한다.

```bash
gcloud auth application-default login \
  --scopes=https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/playdeveloperreporting
```

- 로그인 URL은 브라우저로 직접 연다.
- 토큰이 만료되면 사용자가 `gcloud auth login`과 위 명령을 다시 실행해야 한다. 에이전트가 대신할 수 없으므로 만료 오류가 나면 이 명령을 안내한다.

## 호출

```
POST https://playdeveloperreporting.googleapis.com/v1beta1/apps/<PACKAGE_NAME>/{metricSet}:query
```

| 지표 | metricSet |
|---|---|
| 크래시 | `crashRateMetricSet` |
| ANR | `anrRateMetricSet` |
| LMK(low memory kill) | `lmkRateMetricSet` |

헤더:
- `Authorization: Bearer $(gcloud auth application-default print-access-token)`
- `x-goog-user-project: <QUOTA_PROJECT>`
- `Content-Type: application/json`

본문 구성:
- `timelineSpec`: 집계 단위 `DAILY`, 타임존 `America/Los_Angeles`, 시작일과 종료일
- `metrics`: `userPerceived{Crash|Anr|Lmk}Rate28dUserWeighted`(사용자 인식 28일 가중 비율), `distinctUsers`

예시(크래시):

```bash
curl -s -X POST \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "x-goog-user-project: <QUOTA_PROJECT>" \
  -H "Content-Type: application/json" \
  "https://playdeveloperreporting.googleapis.com/v1beta1/apps/<PACKAGE_NAME>/crashRateMetricSet:query" \
  -d '{
    "timelineSpec": {
      "aggregationPeriod": "DAILY",
      "startTime": {"year": 2026, "month": 4, "day": 1, "timeZone": {"id": "America/Los_Angeles"}},
      "endTime":   {"year": 2026, "month": 4, "day": 2, "timeZone": {"id": "America/Los_Angeles"}}
    },
    "metrics": ["userPerceivedCrashRate28dUserWeighted", "distinctUsers"]
  }'
```

ANR, LMK는 metricSet과 지표 이름의 `Crash`만 `Anr`, `Lmk`로 바꾼다.

## 참고

- 약 1년 전까지 조회할 수 있다.
- 추이를 볼 때는 몇 개 시점(예: 6개월 간격)의 하루치를 조회해 28일 가중 비율을 비교하면 호출 수가 적다.
- 결과를 보고할 때는 기간, 지표 이름(사용자 인식 28일 가중), 일 사용자 수를 같이 적는다.

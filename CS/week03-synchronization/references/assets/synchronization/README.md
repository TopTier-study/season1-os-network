# week03-synchronization 이미지 가이드

아래 파일명을 기준으로 이미지를 저장하면 `[01] race-condition.md`에 바로 연결할 수 있습니다.

1. `race-condition.svg`
- 권장 출처: https://commons.wikimedia.org/wiki/File:Race_condition.svg
- 사용 위치: `## 1. 핵심 개념`의 `### 1) Race Condition이란?` 아래

2. `toctou-race.svg`
- 권장 출처: CWE-367 예시를 바탕으로 직접 도식화(검사 시점 vs 사용 시점)
- 참고: https://cwe.mitre.org/data/definitions/367.html
- 사용 위치: `### 4) 실제 버그 사례`의 `사례 B. TOCTOU 파일 접근 취약점` 아래

3. `thread-sanitizer-warning.png` (선택)
- 권장 출처: Xcode 실행 화면 캡처(보라색 Thread Sanitizer 경고)
- 사용 위치: `## 2. 탐구하기 / iOS 연결지점`의 `### 2) iOS 예제 코드` 아래
- 현재 문서는 GitHub 첨부 이미지 링크를 직접 사용 중

4. `instruments-signpost.png`
- 권장 출처: Instruments > Points of Interest에서 `unsafeRun`/`safeRun` 또는 `queueWait`/`cpuWork` 구간 캡처
- 사용 위치: `### 3) 분석 지표를 보는 방법` 아래

참고: 기존 주차 문서 스타일을 맞추기 위해 이미지 아래에 `[출처](URL)` 줄을 같이 두는 것을 권장합니다.

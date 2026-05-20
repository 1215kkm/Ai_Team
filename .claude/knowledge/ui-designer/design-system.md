# 글로벌 디자인 시스템 (Crowny 베이스)

> **적용 범위**: Ai팀이 작업하는 *모든* 프로젝트의 디폴트 디자인 시스템.
> **오버라이드**: 프로젝트별로 다른 디자인이 필요하면 그 프로젝트의 `./.claude/knowledge/ui-designer/`에 별도 파일을 두면 그것이 우선.
> **UI/UX 모두 참조**: UI는 색·타이포·컴포넌트 명세로, UX는 레이아웃·간격·인터랙션 패턴으로.

---

## 1. 색상

### 메인 팔레트
| 이름 | HEX |
|---|---|
| 메인 보라 | `#6C3CE1` |
| 핑크 | `#D63384` |
| 오렌지 | `#E8590C` |
| 시안 | `#0EA5E9` |
| 초록 | `#059669` |

### 배경 그라데이션 (메인 화면 상단)
- 시작: `#5B2FD6`
- 중간: `#7C4DFF`
- 끝: `#9B72FF`
- 방향: **165도** (좌상 → 우하)

### 텍스트
| 이름 | HEX | 용도 |
|---|---|---|
| 기본 | `#1E1B4B` | 거의 검정 |
| 보조 | `#4B5563` | 회색 |
| 흐린 | `#9CA3AF` | 연한 회색 / placeholder |
| 아주 흐린 | `#D1D5DB` | 비활성 |

### 카드/배경
- 카드 배경: `#F9F7FF` (연보라)
- 연보라 배경: `#F3F0FF`
- 보라 테두리: `#EDE9FE`

### 그라데이션 아이콘박스 4종
```css
핑크:   linear-gradient(135deg, #F43F5E, #E8590C)
블루:   linear-gradient(135deg, #0EA5E9, #2563EB)
오렌지: linear-gradient(135deg, #F59E0B, #E8590C)
퍼플:   linear-gradient(135deg, #7C4DFF, #5B2FD6)
```

### 메인 버튼
- 배경: `linear-gradient(135deg, #6C3CE1, #D63384)`
- 그림자: `0 4px 16px rgba(108,60,225,0.4)`

---

## 2. 폰트

| 용도 | 폰트 |
|---|---|
| 기본 | `'Noto Sans KR', -apple-system, sans-serif` |
| 아이콘 | `Material Icons Round` (Google Fonts CDN) |
| 타이틀 (선택) | `'Paperlogy'` (홈 화면 로고용) |

### 크기 체계
| 용도 | 크기 / weight |
|---|---|
| 타이틀 | 48px / 900 |
| 페이지 제목 | 18px / 800 |
| 섹션 제목 | 17px / 800 |
| 본문 | 14px / 400~600 |
| 보조 텍스트 | 12px / 400 |
| 작은 텍스트 | 10px / 500 |
| 독바 라벨 | 10px / 600 |

### 글자 크기 전역 조절
- CSS 변수 `--fs`로 전역 조절
- 각 요소: `calc(기본px + var(--fs) * 1px)`
- 기본값: **+3** (30대 기준)
- 범위: **-3 ~ +6**

---

## 3. 둥글기 (Border Radius)

| 요소 | 값 |
|---|---|
| 작은 (칩, 배지) | 8~10px |
| 중간 (버튼, 입력, 아이콘박스) | 12~14px |
| 카드 (목록 아이템) | 16~18px |
| 큰 카드 (팝업, 아바타) | 20~24px |
| 시트 (바텀시트 상단) | `32px 32px 0 0` |

---

## 4. 그림자 (Box Shadow)

```css
약한:    0 2px 8px rgba(0,0,0,0.06)
보통:    0 4px 16px rgba(108,60,225,0.1)
강한:    0 4px 16px rgba(108,60,225,0.4)   /* 메인 버튼 */
네비바:  0 -2px 20px rgba(0,0,0,0.04)
```

---

## 5. 레이아웃 (모바일 앱 기준)

| 항목 | 값 |
|---|---|
| 최대 너비 | 390px |
| 페이지 패딩 | 24px 좌우 |
| 시트 패딩 | 28px 24px 100px (하단 네비 공간) |
| 아이템 간격 | 14~16px |
| 섹션 간격 | 24~28px |

---

## 6. 핵심 컴포넌트

### 바텀 네비게이션 (4탭)
- 배경: `white`
- 높이: 자동 (safe-area 포함)
- 그림자: `0 -2px 20px rgba(0,0,0,0.04)`
- **활성 탭**: 보라색 + 아이콘에 연보라 pill 배경
  - pill 배경: `linear-gradient(135deg, rgba(123,97,255,0.12), rgba(232,69,160,0.08))`
  - pill 둥글기: 12px
  - pill 패딩: 4px 16px
- **비활성 탭**: `#C4B5FD` (연보라)
- 라벨: 10px / 600
- 아이콘: 24px

### 보라 배경 + 흰색 시트 구조
- **상단**: 보라 그라데이션 배경 (165deg)
  - 헤더: 제목(18px/800) + 좌우 아이콘 버튼(40x40)
  - 아이콘 버튼: `rgba(255,255,255,0.2)` 배경, 14px 둥글기
- **하단**: 흰색 시트
  - `border-radius: 32px 32px 0 0`
  - handle: 36x4px, `#E5E7EB`, 둥글기 2px, 가운데 정렬

### 글래스 카드
```css
background: rgba(255,255,255,0.18);
backdrop-filter: blur(10px);
border: 1px solid rgba(255,255,255,0.15);
border-radius: 16px;
```

### 입력 필드
- 테두리: `1px solid #D1D5DB`
- 둥글기: 12px (일반) / 20px (채팅 입력)
- 포커스: `border-color: #6C3CE1`
- 패딩: 12px 14px
- placeholder 색: `#9CA3AF`

### 칩 (필터)
**비활성**
- 배경: `rgba(255,255,255,0.1)`
- 테두리: `1px solid rgba(255,255,255,0.3)`
- 색상: `rgba(255,255,255,0.8)`

**활성**
- 배경: `white`
- 테두리: `white`
- 색상: `#6C3CE1` (보라)

공통: 둥글기 20px, 패딩 8px 16px, 12px / 600

### 채팅 말풍선
**상대방**
- 배경: `#F3F4F6`
- 둥글기: `18px 18px 18px 4px` (좌하단만 각진)
- 글자: 13px / `#1E1B4B`

**내 메시지**
- 배경: `linear-gradient(135deg, #6C3CE1, #D63384)`
- 둥글기: `18px 18px 4px 18px` (우하단만 각진)
- 글자: 13px / white

**시스템 메시지**
- 배경: `#F3F4F6`
- 둥글기: 20px
- 글자: 11px / `#6B7280`
- 가운데 정렬

### 매너 태그 (3색)
| 종류 | 배경 | 색상 |
|---|---|---|
| 빨강 | `rgba(244,63,94,0.1)` | `#E11D48` |
| 보라 | `rgba(123,97,255,0.08)` | `#6C3CE1` |
| 시안 | `rgba(54,209,220,0.08)` | `#0EA5E9` |

공통: 둥글기 12px, 패딩 7px 12px, 11px / 600, 아이콘 14px

### 한강 온도 바
- 배경 바: `#EDE9FE`
- 진행 바: `linear-gradient(90deg, #6C3CE1, #D63384)`
- 높이: 5px
- 둥글기: 3px
- 온도 숫자: 18px / 800 / `#E8590C` (오렌지)

### 모임 상태 배지
| 상태 | 배경 | 색상 |
|---|---|---|
| 🟢 모집중 | `#ECFDF5` | `#059669` |
| 🟡 곧시작 | `#FFFBEB` | `#D97706` |
| 🔴 진행중 | `#FEF2F2` | `#DC2626` |
| ⚫ 종료 | `#F3F4F6` | `#6B7280` |

공통: 둥글기 6px, 패딩 2px 8px, 10px / 700

### 레이더 뷰 (모집 상황)
**원형 레이더**
- 크기: 280x280px
- 배경: `radial-gradient(circle, rgba(108,60,225,0.03) → 0.08 → 0.15)`
- 테두리: `2px solid rgba(108,60,225,0.2)`
- 동심원: `1px solid rgba(108,60,225,0.1)`

**Sweep 애니메이션**
```css
background: conic-gradient(transparent 0deg, rgba(108,60,225,0.15) 30deg, transparent 60deg);
animation: rotate 3s linear infinite;
```

**중앙 점**: 20px, `#6C3CE1`, 흰 테두리 3px, 그림자
**참여 아이콘**: 👋 / 배경 `rgba(108,60,225,0.12)` / 32x32
**관심 아이콘**: ❤️ / 배경 `rgba(214,51,132,0.12)` / 32x32

---

## 7. 애니메이션

| 종류 | 정의 |
|---|---|
| 페이지 전환 | `fadeIn 0.25s ease` (opacity 0→1, translateY 6→0) |
| 카운트다운 | `scale(2) → scale(1)` + opacity, 0.8s |
| 결과 바운스 | `scale(0) → scale(1.1) → scale(1)`, `cubic-bezier(0.68, -0.55, 0.27, 1.55)` |
| 레이더 sweep | `rotate 360deg`, 3s linear infinite |

---

## 8. CDN 링크

```html
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/icon?family=Material+Icons+Round" rel="stylesheet">
```

### Material Icons 사용법
```html
<span class="mi">icon_name</span>
```
```css
.mi {
  font-family: 'Material Icons Round';
  font-size: 22px;
  font-weight: normal;
  font-style: normal;
  line-height: 1;
  display: inline-block;
  -webkit-font-smoothing: antialiased;
}
```

---

## 9. Flutter 테마 코드 (theme.dart)

```dart
class CrownyTheme {
  static const Color primary = Color(0xFF6C3CE1);
  static const Color secondary = Color(0xFFD63384);
  static const Color accent = Color(0xFFE8590C);
  static const Color textPrimary = Color(0xFF1E1B4B);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color bgCard = Color(0xFFF9F7FF);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B2FD6), Color(0xFF7C4DFF), Color(0xFF9B72FF)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C3CE1), Color(0xFFD63384)],
  );

  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusSheet = 32.0;
  static const double pagePadding = 24.0;
}
```

---

## 디자이너 에이전트가 이 문서를 사용하는 방법

- **새 화면을 디자인할 때**: 위 색상·간격·컴포넌트 명세에서 *기존 토큰을 먼저* 사용. 새 값이 필요하면 *왜* 새로 정의해야 하는지 한 줄로 근거 제시.
- **프로젝트별 오버라이드 확인**: `./.claude/knowledge/ui-designer/design-system.md`(프로젝트 로컬)가 있으면 그것이 우선. 없으면 이 글로벌 문서 사용.
- **모바일이 아닌 프로젝트**: 모바일 컴포넌트(바텀 네비, 시트, 한강 온도 바, 매너 태그 등)는 *그대로 적용하지 말고* 데스크탑/태블릿용으로 변환해서 사용. 색·타이포·둥글기·그림자 토큰은 그대로.
- **요청자가 "다른 디자인"이라고 명시하면**: 이 문서를 *참고용으로만* 두고 별도 안 제안.

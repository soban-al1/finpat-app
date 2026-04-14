# FinPat Design System (Frontend)

This document defines the UI/UX foundation for the frontend app.

## 1. Design Principles

- Clarity first: financial information should be scannable in under 3 seconds.
- Progress over perfection: highlight what to do next, not only current totals.
- Calm confidence: avoid alarmist visuals unless user is at risk.
- Accessibility by default: readable typography, sufficient contrast, clear states.

## 2. Visual Identity

- Brand accent: deep teal primary.
- Semantic colors:
  - Success: green/teal tones
  - Warning: amber/orange tones
  - Critical/error: red tones
- Surfaces:
  - Elevated cards for key financial blocks
  - Muted secondary backgrounds for grouped controls

## 3. Typography

- Display heading: page titles and total amounts.
- Body text: readable, medium contrast.
- Meta text: small uppercase labels for context (`Spent Breakdown`, `Due Next`).

Guidelines:
- Use strong hierarchy (`H1 > H2 > section labels > meta`).
- Keep labels short and consistent across screens.

## 4. Spacing and Layout

- Use 8px spacing system.
- Mobile-first widths and touch targets:
  - Minimum tap area: 44x44 px
- Card rhythm:
  - Outer section spacing: large
  - Inner card spacing: medium
  - Metrics inside card: tight, aligned baseline

## 5. Components

### Core
- Button (primary, secondary, destructive, ghost)
- Input (text, number, date, select)
- Modal / bottom sheet
- Card / panel
- Badge / status pill
- Toast / inline error
- Empty state block

### Finance-specific
- Currency amount display
- Progress bar (goal/pressure)
- Obligation item row
- Remittance log item row
- Savings log row
- KPI summary tile

## 6. States

Every interactive component must support:
- Default
- Hover/pressed (if platform supports)
- Focus
- Disabled
- Loading
- Error

Data screens must support:
- Loading skeleton
- Empty state
- Partial data fallback
- Retry action on error

## 7. Iconography

- Use a consistent stroke icon set.
- Icons support labels; avoid icon-only controls unless obvious.
- Examples:
  - Dashboard: grid/gauge
  - Obligations: target/check
  - Remittances: send/arrow
  - Savings: wallet/trending up

## 8. Motion

- Keep transitions subtle and purposeful.
- Animate:
  - Screen transitions
  - Progress updates
  - Modal open/close
- Avoid long or distracting animations in financial contexts.

## 9. Data Formatting Rules

- Currency: always use currency formatter with code/symbol.
- Date: use locale-aware short format for lists; full for details.
- Percentages: rounded where needed, but retain precision in calculations.

## 10. Accessibility

- Color contrast: WCAG-compliant for text and controls.
- Keyboard/assistive support for all actions.
- Semantic labels for all inputs and icons.
- Do not rely only on color to indicate status.



# London Platforms - Feature Opportunities (Client-Only)

Status: Draft proposal  
Last updated: 2026-04-14

This document captures potential product features that can be implemented using existing RealTime Trains responses already consumed by the app.  
No custom backend, no server-side processing, and no additional datastore are required.

---

## 1) Scope and constraints

### 1.1 In scope

- Features derived from existing RTT payload fields.
- On-device processing only.
- Optional local persistence using existing app settings mechanisms.

### 1.2 Out of scope

- Running custom APIs.
- Introducing cloud storage.
- Requiring server-side analytics pipelines.

### 1.3 Data sources assumed available

- Board/location responses (`services`, `temporalData`, `locationMetadata`, `reasons`, `systemStatus`)
- Service detail responses (`locations`, `associatedServices`, `reasons`)
- Stops catalog response (`stops`)

---

## 2) Prioritization framework

Each feature below includes:

- **User value** (why it helps passengers)
- **Signal inputs** (which existing fields are used)
- **Decision rules** (deterministic logic)
- **UX surfaces** (where to present)
- **Risk notes** (misleading states, ambiguity)

Priority definitions:

- **P1**: High value, low implementation risk
- **P2**: High value, moderate complexity
- **P3**: Nice-to-have polish

---

## 3) P1 feature: Platform confidence + change warning

### 3.1 Problem statement

Passengers need confidence about whether a shown platform is safe to act on.  
Current planned/confirmed status is useful but can be made more explicit.

### 3.2 User value

- Faster decision-making near departure.
- Reduced missed trains from late platform changes.
- Clearer distinction between expected and operationally confirmed platform.

### 3.3 Signal inputs (existing API fields)

- `locationMetadata.platform.planned`
- `locationMetadata.platform.actual`
- Derived `platformConfirmed = actual != nil`
- Derived `platformChanged = actual != nil && planned != nil && actual != planned`
- `temporalData.departure.scheduleAdvertised`
- `temporalData.departure.realtimeForecast` / `realtimeActual`
- `temporalData.departure.status` (`APPROACHING`, `AT_PLATFORM`, `DEPART_PREPARING`, `DEPARTING`, etc.)
- `temporalData.displayAs` (for cancellations)

### 3.4 Derived values

- `minutesToDeparture` from booked/realtime departure (prefer scheduled when comparing urgency).
- `hasPlatform` when either planned or actual exists.

### 3.5 Confidence states (normative proposal)

1. **Changed** (warning state; highest precedence)
   - Condition: `platformChanged == true`
   - Label: `Platform changed`
   - Tone: warning

2. **Confirmed** (high confidence)
   - Condition: `platformConfirmed == true` and service not cancelled
   - Label: `Platform confirmed`
   - Tone: positive

3. **Expected** (medium confidence)
   - Condition: planned exists, not confirmed, and `minutesToDeparture > 10`
   - Label: `Expected platform`
   - Tone: neutral

4. **Pending** (low confidence)
   - Condition: planned exists, not confirmed, and `minutesToDeparture <= 10`
   - Label: `Platform pending`
   - Tone: caution

5. **Unavailable**
   - Condition: no planned/actual platform
   - Label: `Platform not yet available`
   - Tone: muted

6. **Cancelled override**
   - Condition: `displayAs == CANCELLED`
   - Behavior: suppress confidence chip and show cancellation-first status.

### 3.6 Optional "at risk" warning

If not changed yet, show `May change` when:

- `platformConfirmed == false`
- `minutesToDeparture <= 5`
- and status indicates active movement (`APPROACHING` or `ARRIVING`)

Purpose: warn users that the currently shown planned platform may still change.

### 3.7 UX surfaces

- Board row trailing area (near platform badge).
- Optional detail view summary line.
- Accessibility label should include confidence state.

### 3.8 Accessibility requirements

Example label:

- `Platform 9. Platform changed from 8. Confirm before boarding.`

### 3.9 Risks and mitigations

- Risk: over-warning users with noisy alerts.
  - Mitigation: keep thresholds conservative and test with live data.
- Risk: stale data briefly shown.
  - Mitigation: tie confidence to existing refresh cadence and show last-refresh time.

### 3.10 Rollout suggestion

- Phase 1: state chip only.
- Phase 2: optional `May change` heuristic after observing false-positive rate.

---

## 4) P1 feature: Boarding-now highlight

### 4.1 Goal

Help users quickly identify services they should act on immediately.

### 4.2 Signals

- `minutesToDeparture`
- `departure.status`
- `platformConfirmed`
- `displayAs`

### 4.3 Rule proposal

`Boarding now` when all are true:

- not cancelled
- platform known
- and one of:
  - status is `AT_PLATFORM` or `DEPART_PREPARING`
  - `minutesToDeparture` in `[0, 3]`

### 4.4 UX

- Accent row with subtle highlight + chip.
- Priority sort option (optional): float boarding-now rows to top.

---

## 5) P1 feature: Association warnings (join/divide/form)

### 5.1 Goal

Prevent passengers boarding the wrong portion where services join/divide.

### 5.2 Signals

- `associatedServices[]`
- `associationData.associationType`
- `associationData.isPublic`
- linked headcode/operator/date fields

### 5.3 Rule proposal

- Surface only public associations.
- De-duplicate by type + identity + date.
- For row/detail:
  - `JOIN_FROM`: `Joins from {headcode}`
  - `JOIN_INTO`: `Joins into {headcode}`
  - `DIVIDE_INTO`: `Divides into {headcode}`
  - `DIVIDE_FROM`: `Divides from {headcode}`
  - `FORM_INTO`: `Forms into {headcode}`
  - `FORM_FROM`: `Forms from {headcode}`

### 5.4 UX

- Detail view association section (already present) can gain stronger warning copy.
- Optional board icon to indicate "portion working".

---

## 6) P2 feature: Delay reason intelligence

### 6.1 Goal

Make delay causes understandable at a glance.

### 6.2 Signals

- `reasons[].shortText`
- delayed/cancelled states

### 6.3 Rule proposal

- Normalize common phrases into categories:
  - inbound late
  - signalling
  - staff/crew
  - congestion/pathing
- Show concise badge + full text in expanded detail.

### 6.4 UX

- Badge on row when delayed/cancelled.
- Full reason line in detail/cell subtitle.

---

## 7) P2 feature: Mode filters (rail vs replacement bus)

### 7.1 Goal

Let passengers hide replacement bus services if desired.

### 7.2 Signals

- `modeType` values:
  - `TRAIN`
  - `REPLACEMENT_BUS`
  - `BUS`
  - `SCHEDULED_BUS`
  - other RTT-supported modes

### 7.3 Rule proposal

User setting:

- `All`
- `Rail only`
- `Replacement bus only` (optional advanced)

Persist locally in app settings.

---

## 8) P2 feature: System health-aware UX mode

### 8.1 Goal

Set user expectations when realtime data degrades.

### 8.2 Signals

- `systemStatus.rttCore`
- `systemStatus.realtimeNetworkRail`

### 8.3 Rule proposal

- `SCHEDULE_ONLY`: emphasize scheduled times and caution copy.
- `REALTIME_DEGRADED` / `REALTIME_DATA_LIMITED`: keep live UI but add warning banner.
- `REALTIME_DATA_NONE`: suppress realtime-specific chips where misleading.

---

## 9) P3 feature: Session-only operator punctuality snapshot

### 9.1 Goal

Provide lightweight context without backend analytics.

### 9.2 Signals

- `atocName`
- delayed/on-time evaluation per visible rows

### 9.3 Rule proposal

In-memory counters reset on app restart:

- `onTimeCountByOperator`
- `delayedCountByOperator`

Display compact summary in optional sheet.

---

## 10) P3 feature: Smart advanced filters

Examples:

- Confirmed platform only
- Hide pass-through
- Departing within next 30 minutes
- Show only delayed/cancelled

All are computable from existing row fields.

---

## 11) Suggested implementation order (no code in this doc)

1. Platform confidence + change warning (P1)
2. Boarding-now highlight (P1)
3. Association warnings (P1)
4. Mode filters (P2)
5. System health-aware UX (P2)
6. Delay reason intelligence (P2)
7. Advanced filters + operator snapshot (P3)

---

## 12) Acceptance criteria template (for any selected feature)

- Uses only existing RTT fields.
- Does not require backend or cloud datastore.
- Degrades gracefully on missing/null fields.
- Does not regress accessibility labels.
- Includes user-facing copy for normal + degraded states.
- Includes deterministic test cases for edge conditions.

---

## 13) Open questions to resolve before implementation

- Should confidence thresholds be static (10 min/5 min) or user-tunable?
- Should `Boarding now` be purely informational or affect row sorting?
- Should "May change" warning be shown only in departures mode?
- How much warning color emphasis is acceptable without inducing alarm fatigue?


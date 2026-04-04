# London Platforms — Service specification

Language-agnostic specification for clients (e.g. native iOS/Android) that reproduce the behaviour of the London train departure/arrival platforms product. This document describes **product behaviour**, **external HTTP integration**, and **JSON data contracts**. It does not prescribe implementation language or UI framework.

---

## 1. Product overview

**Purpose:** Help travellers see **departure platforms** (and optionally **arrivals**) for selected **London main-line stations**, using data from **RealTime Trains** (RTT).

**Core value:** Fast view of “which platform, when” with clear distinction when a platform is **confirmed** versus **expected / pending**.

---

## 2. Functional requirements

### 2.1 Main list

- Load services for the **selected station** (UK CRS code).
- **Default mode:** departures for “now” (no time segment on the search request; see §4).
- **Optional time filter:** User chooses a **time on the current local calendar day**. Requests include that time in the path (see §4). Date parts use **device local** “today”.
- **Mode toggle:** Switch between **departures** and **arrivals** for the same station and time selection.
- **Manual refresh:** Reload data; display **last successful refresh** as local time `HH:mm`.
- **Empty state:** When there are no services to show, display a clear “no services at this time” (or equivalent) message.
- **Row activation:** Open **service detail** for the selected service using `serviceUid` and `runDate` from the list item.

### 2.2 Departure row (presentation rules)

| Element | Source |
|--------|--------|
| Scheduled departure time (leading) | `locationDetail.gbttBookedDeparture`, displayed as `HH:mm` from a four-digit `HHmm` string |
| Primary label (title) | `locationDetail.destination[0].description` |
| Secondary label (subtitle) | `atocName`; append platform status per below |
| Platform (trailing) | `locationDetail.platform` when relevant; emphasize when confirmed |

**Platform confirmed** when `locationDetail.platformConfirmed` is true:

- Visually emphasize the row (e.g. distinct background colour).
- Subtitle includes text equivalent to: “Platform Confirmed”.
- Show platform identifier **prominently** (e.g. large, bold type).

**Platform not confirmed:**

- If `locationDetail.platform` is present: subtitle includes text equivalent to: “Platform Pending (expected {platform})”.
- Otherwise: subtitle is `atocName` only.

### 2.3 Arrival row (presentation rules)

| Element | Source |
|--------|--------|
| Time (leading) | `locationDetail.destination[0].publicTime` as `HH:mm` |
| Primary label | `locationDetail.origin[0].description` |
| Secondary label | `atocName` |
| Platform (trailing) | `locationDetail.platform` (prominent sizing is acceptable) |

Note: Arrival rows do not use the same “confirmed vs pending” branching as departures in the reference product.

### 2.4 Service detail (“calling points”)

- Fetch the **service** resource by `serviceUid` and date derived from `runDate` (see §4).
- Show identifying line: `trainIdentity` and `atocName`.
- Show headline: first origin public time (as `HH:mm`) + “ to ” + `destination[0].description`.
- Section title equivalent to: “Calling points:”
- Build the calling-point list from `locations` with **all** of the following true for an entry to be shown:

  1. `isPublicCall` is true  
  2. `origin[0].description` ≠ `description`  
  3. `gbttBookedArrival` is non-null  

- **Line format:** `{description} ({formatted gbttBookedArrival})` where the time uses the same `HH:mm` rule. If `destination[0].description` ≠ `description`, append `", "` after the closing parenthesis; otherwise end after `)`.

### 2.5 Station catalogue

Persist user’s choice. Default station: **EUS** / **Euston**.

| CRS | Display name |
|-----|----------------|
| BFR | Blackfriars |
| CST | Cannon Street |
| CHX | Charing Cross |
| CTK | City Thameslink |
| EUS | Euston |
| FST | Fenchurch Street |
| KGX | Kings Cross |
| LST | Liverpool Street |
| LBG | London Bridge |
| MYB | Marylebone |
| MOG | Moorgate |
| OLD | Old Street |
| PAD | Paddington |
| STP | St Pancras (Domestic) |
| VXH | Vauxhall |
| VIC | Victoria |
| WAT | Waterloo |
| WAE | Waterloo East |

### 2.6 About, attribution, and policy

- App name shown to user: **London Platforms** (or successor branding).
- Attribution: **Data used with the kind permission of RealTimeTrains.**
- Feedback contact: **platformfeedback@icloud.com**
- Privacy policy URL (open in system browser):  
  `https://platformsapp.wordpress.com/london-platforms-privacy-notice/`

### 2.7 Client-side persistence

| Key | Meaning |
|-----|--------|
| `savedStation` | CRS code (string) |
| `savedStationDesc` | Human-readable station name matching the catalogue |

Default when unset: `EUS` and `Euston`.

### 2.8 Theming (parity with reference product)

- Support **light** and **dark** appearance at application level.
- Light theme primary accent: **blue grey** family (exact colour values are implementation-defined).

---

## 3. External dependency: RealTime Trains API

### 3.1 Base URL

`https://api.rtt.io`

### 3.2 Authentication

HTTP **Basic** authentication: header `Authorization: Basic <base64(username:password)>` using credentials issued by RealTime Trains.

**Security:** Do not embed long-lived API credentials in shipped app binaries where they can be extracted. Prefer a backend proxy, rotating secrets, or arrangements compliant with RTT terms of use.

### 3.3 Resources used

All JSON under `/api/v1/json/`.

| Operation | Method | Path pattern |
|-----------|--------|--------------|
| Station departures (current) | GET | `/api/v1/json/search/{crs}` |
| Station departures at time | GET | `/api/v1/json/search/{crs}/{yyyy}/{MM}/{dd}/{HHmm}` |
| Station arrivals (current) | GET | `/api/v1/json/search/{crs}/arrivals` |
| Station arrivals at time | GET | `/api/v1/json/search/{crs}/{yyyy}/{MM}/{dd}/{HHmm}/arrivals` |
| Service detail | GET | `/api/v1/json/service/{serviceUid}/{yyyy}/{MM}/{dd}` |

- `{crs}`: uppercase CRS (e.g. `EUS`).
- `{yyyy}`, `{MM}`, `{dd}`: calendar components for **local today** on the search requests; for **service detail**, derived from the service’s `runDate` (§3.4).
- `{HHmm}`: four-digit 24-hour time, no colon (e.g. `0930`, `1430`).

### 3.4 Path construction rules

**Search (departures or arrivals):**

- If the user has **not** chosen a time of day: use the path **without** the `/{yyyy}/{MM}/{dd}/{HHmm}` segment (only `/search/{crs}` or `/search/{crs}/arrivals`).
- If the user **has** chosen a time: append `/{yyyy}/{MM}/{dd}/{HHmm}` using **today’s local date** and the stored `HHmm` value.

**Service detail:**

- `runDate` from the API is expected in form `yyyy-MM-dd`.
- Convert to path segments: `/` + year + `/` + month + `/` + day (e.g. `2026-04-04` → `/2026/04/04`).

### 3.5 HTTP semantics

- **200:** Parse body as JSON per §4.
- **Non-success:** Treat as failure; dismiss loading state and show a user-appropriate error. Retry policy is implementation-defined.

---

## 4. JSON data contracts

Field names match RTT JSON. Types below are logical; nullability follows real payloads (clients should tolerate omitted or null fields where reasonable).

### 4.1 Search response root (`Departures`)

| Field | Type | Notes |
|-------|------|--------|
| `location` | object | See **Location** |
| `filter` | any | Optional; not required for UI |
| `services` | array of **ServiceSummary** | Absent or null → treat as no services |

**Location**

| Field | Type |
|-------|------|
| `name` | string |
| `crs` | string |
| `tiploc` | string or null |

**ServiceSummary**

| Field | Type |
|-------|------|
| `locationDetail` | **LocationDetail** |
| `serviceUid` | string |
| `runDate` | string (`yyyy-MM-dd`) |
| `trainIdentity` | string |
| `runningIdentity` | string |
| `atocCode` | string |
| `atocName` | string |
| `serviceType` | string |
| `isPassenger` | boolean |

**LocationDetail**

| Field | Type |
|-------|------|
| `realtimeActivated` | boolean |
| `tiploc` | string |
| `crs` | string |
| `description` | string |
| `gbttBookedDeparture` | string |
| `origin` | array of **CallPointRef** |
| `destination` | array of **CallPointRef** |
| `isCall` | boolean |
| `isPublicCall` | boolean |
| `realtimeDeparture` | string |
| `realtimeDepartureActual` | boolean |
| `platform` | string |
| `platformConfirmed` | boolean |
| `platformChanged` | boolean |
| `serviceLocation` | string |
| `displayAs` | string |

**CallPointRef** (used under `origin` / `destination`)

| Field | Type |
|-------|------|
| `tiploc` | string |
| `description` | string |
| `workingTime` | string |
| `publicTime` | string |

### 4.2 Service detail response root (`ServiceDetail`)

| Field | Type |
|-------|------|
| `serviceUid` | string |
| `runDate` | string |
| `serviceType` | string |
| `isPassenger` | boolean |
| `trainIdentity` | string |
| `powerType` | string |
| `trainClass` | string |
| `atocCode` | string |
| `atocName` | string |
| `performanceMonitored` | boolean |
| `origin` | array of **CallPointRef** |
| `destination` | array of **CallPointRef** |
| `locations` | array of **ServiceLocation** |
| `realtimeActivated` | boolean |
| `runningIdentity` | string |

**ServiceLocation** (extends the same core idea as LocationDetail for calling points)

| Field | Type |
|-------|------|
| `realtimeActivated` | boolean |
| `tiploc` | string |
| `crs` | string |
| `description` | string |
| `gbttBookedDeparture` | string |
| `origin` | array of **CallPointRef** |
| `destination` | array of **CallPointRef** |
| `isCall` | boolean |
| `isPublicCall` | boolean |
| `realtimeDeparture` | string |
| `realtimeDepartureActual` | boolean |
| `platform` | string |
| `platformConfirmed` | boolean |
| `platformChanged` | boolean |
| `line` | string |
| `lineConfirmed` | boolean |
| `displayAs` | string |
| `gbttBookedArrival` | string |
| `realtimeArrival` | string |
| `realtimeArrivalActual` | boolean |

### 4.3 Display time rule

For values stored as at least four characters representing `HHmm`, display as `HH:mm` (first two digits, colon, next two digits). Behaviour for shorter or malformed strings is implementation-defined (reference product assumes valid `HHmm`).

---

## 5. Non-functional expectations

- Use TLS for all API traffic.
- Respect device **local time zone** for “today” in search URLs.
- Loading indicator while requests are in flight.
- Network failure and timeout handling are required; specifics are implementation-defined.

---

## 6. Versioning

- **Document version:** 1.0  
- **Reference product version label (historical):** 2.0.2+7  

Changes to this spec should bump the document version and record a short changelog in the repository commit message or a `CHANGELOG` entry if the project maintains one.

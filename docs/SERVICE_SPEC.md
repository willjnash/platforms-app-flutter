# London Platforms - Service Specification

Version: 2.1  
Status: Current  
Last updated: 2026-04-14

This document is the canonical, language-agnostic product and integration specification for London Platforms clients. It is intentionally detailed so native iOS, future native Android, and any backend/proxy components can implement identical behavior.

This version reflects the active native client integration with `https://data.rtt.io` (RTT v2 style APIs) and supersedes earlier v1-style path examples.

---

## 0) Normative language

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 / RFC 8174.

Conformance:

- A client is conformant only if all REQUIRED/MUST statements are implemented.
- SHOULD statements are strongly recommended and SHOULD only be violated with an explicit, documented reason.
- MAY/OPTIONAL statements are implementation choices and must not break REQUIRED behavior.

---

## 1) Purpose and scope

London Platforms helps passengers quickly answer:

- Which services are relevant for a selected station?
- What time are they planned to run?
- Are they on time, delayed, cancelled, or pass-through?
- Which platform is expected or confirmed?
- What are the calling points for a selected service?

This spec covers:

- User-facing functional behavior
- Data contracts used by clients
- RealTime Trains (RTT) integration semantics
- Presentation and decision rules
- Persistence keys
- Error handling requirements

This spec does not prescribe:

- A specific UI toolkit
- Concrete architecture patterns
- Color hex values or exact spacing constants

---

## 2) Product behavior

### 2.1 Main board (station list)

The board presents live or time-filtered services for a selected station CRS.

Required capabilities:

- Select a station (default `EUS` / `Euston`).
- Toggle departures vs arrivals.
- Optional time filter (same local calendar day as the device).
- Optional "towards" station filter.
- Pull-to-refresh/manual refresh.
- Auto-refresh for live mode only.
- Last refresh indicator.
- Clear empty state when no rows render.
- Tap row to open service detail.

### 2.2 Live vs time-filtered mode

- Live mode: no explicit time filter selected.
- Time-filtered mode: `HHmm` selected by user.
- Auto-refresh runs in live mode and pauses in time-filtered mode.

### 2.3 Board row eligibility rules

A row is renderable only when all required data exists and business filters allow it.

Common exclusion:

- `inPassengerService == false` -> do not render.

Departures render when either:

- It is a stopping service with a scheduled departure time and destination.
- It is a pass-through service (non-stopping) and pass-through display is enabled by user preference.

Arrivals render when:

- Destination public time for current station exists, and
- Origin exists.

### 2.4 Departure row behavior

Primary sources:

- Scheduled time: `locationDetail.gbttBookedDeparture` (or `passHHmm` for pass-through rows)
- Title: first destination description
- Operator/headcode metadata
- Platform: planned/actual platform fields
- Delay/cancellation/reason data from temporal and reason blocks

Rules:

- If cancelled (`displayAs == CANCELLED`), visually de-emphasize and strike through key text.
- If delayed (`lateness > 0` or realtime differs), show delay badge and expected time.
- If platform is confirmed (actual platform present), apply confirmed visual treatment and confirmed wording.
- If platform changed (actual differs from planned), show "changed" indicator.
- Pass-through service should show pass-through status and no platform emphasis.

### 2.5 Arrival row behavior

Primary sources:

- Scheduled time: destination public time at current location
- Title: origin description
- Platform and realtime arrival fields

Rules:

- Similar delayed/cancelled handling as departures.
- No special confirmed-vs-pending branch required for platform wording parity unless product decides to align with departures.

### 2.6 Service detail behavior

When user opens a service:

- Client requests service detail by service identity + run date.
- Header should show headcode/identity and operator.
- Headline should include first origin public time plus destination summary when available.
- Calling points list is generated from service locations using strict filters (see section 7).
- Public associations (join/divide/form) are listed and navigable.

### 2.7 System status banner

Board may display degraded-data/system-state banner from `systemStatus` payload:

- `SCHEDULE_ONLY`
- `REALTIME_DEGRADED`
- `REALTIME_DATA_NONE`
- `REALTIME_DATA_LIMITED`

Only one highest-priority message should display at once.

---

## 3) Station catalog behavior

### 3.1 Default and persistence

Default station:

- CRS: `EUS`
- Name: `Euston`

Persist:

- `savedStation`
- `savedStationDesc`

### 3.2 Fallback catalog (must exist offline)

Clients must include fallback London stations:

- BFR Blackfriars
- CST Cannon Street
- CHX Charing Cross
- CTK City Thameslink
- EUS Euston
- FST Fenchurch Street
- KGX Kings Cross
- LST Liverpool Street
- LBG London Bridge
- MYB Marylebone
- MOG Moorgate
- OLD Old Street
- PAD Paddington
- STP St Pancras (Domestic)
- VXH Vauxhall
- VIC Victoria
- WAT Waterloo
- WAE Waterloo East

### 3.3 Dynamic catalog refresh

Client may refresh station catalog from RTT stops endpoint and cache results.  
If network fetch fails, fallback list remains valid.

---

## 4) External dependency and security

### 4.1 API base

- Base URL: `https://data.rtt.io`

### 4.2 Authentication model

RTT uses a two-token flow:

1. Long-lived bearer refresh token (app configuration secret)
2. Short-lived access token returned by `/api/get_access_token`

Client behavior:

- Retrieve refresh token from secure app configuration (for local dev, injected via xcconfig/plist).
- Call `/api/get_access_token` with `Authorization: Bearer <refresh-token>`.
- Cache short-lived token with expiry.
- Reuse until close to expiry (recommended safety margin: 60 seconds).
- Use short-lived token for subsequent API calls:
  - `Authorization: Bearer <access-token>`

Security requirements:

- Do not commit secrets.
- Do not hardcode production credentials in source.
- Prefer proxy or rotation strategy for public releases.

---

## 5) HTTP resources and semantics

### 5.1 Access token exchange

- Method: `GET`
- Path: `/api/get_access_token`
- Auth: refresh token in `Authorization` header
- Success: `200` with token body
- Client MUST treat missing/empty `token` as an authentication failure.
- Client SHOULD use `validUntil` when supplied to manage cache expiry.

### 5.2 Board/location query

- Method: `GET`
- Path: `/gb-nr/location`
- Query parameters:
  - `code` (required): station CRS
  - `timeFrom` (optional): ISO local datetime, seconds included
  - `filterTo` (optional): CRS for "towards" filtering
  - `arrivals` (optional/implementation-specific): explicit arrivals mode selector if required by RTT response behavior

Expected status handling:

- `200`: parse board payload
- `204`: treat as success with empty services
- Other non-2xx: failure
- Client MUST include `code`.
- Client MUST uppercase CRS values before dispatch.
- Client MUST ensure arrivals mode is explicitly represented in request semantics supported by the backend.

### 5.3 Service detail query

- Method: `GET`
- Path: `/gb-nr/service`
- Query parameters:
  - `identity`: service UID/identity
  - `departureDate`: run date (`yyyy-MM-dd`)

Status handling:

- `200`: parse service payload
- Other non-2xx: failure
- Client MUST provide both `identity` and `departureDate`.

### 5.4 Stops catalog query (optional)

- Method: `GET`
- Path: `/data/stops`
- Success: parse stop list and cache station pairs
- Failure: ignore and continue with fallback catalog
- Clients MAY skip this request entirely and remain conformant if fallback catalog is present.

---

## 6) Request construction rules

### 6.1 CRS handling

- Uppercase CRS before sending.
- Reject or sanitize empty CRS.

### 6.2 Time filter formatting

Input:

- `HHmm` (4-digit 24h local time), stored in user settings

Request conversion:

- Build local "today" date parts from device local timezone.
- Construct `timeFrom` as:
  - `yyyy-MM-ddTHH:mm:00`

Example:

- Local date `2026-04-14`, filter `0930` -> `2026-04-14T09:30:00`

### 6.3 Arrivals mode

Clients must ensure arrivals mode is explicitly represented in request semantics supported by API (query parameter or endpoint behavior) so arrivals are not accidentally resolved as departures.

Normative requirement:

- Arrivals toggle MUST alter request behavior in a backend-recognized way.
- If backend semantics change, clients MUST include a compatibility shim so user-visible arrivals behavior remains correct.

### 6.4 Service detail date

- Use `runDate` from board item directly as `departureDate`.
- Expected format: `yyyy-MM-dd`.

---

## 7) Data contracts (logical model)

Field names follow RTT payload naming where possible.  
Clients must tolerate omitted/null fields where safe.

### 7.1 Board response root

`DeparturesResponse` (name retained for legacy parity):

- `services`: array of service lineups (nullable)
- `systemStatus`: optional system-state object

Logical system status:

- `rttCore`: `OK | REALTIME_DEGRADED | SCHEDULE_ONLY`
- `realtimeNetworkRail`: `OK | REALTIME_DATA_LIMITED | REALTIME_DATA_NONE`

### 7.2 Service summary model

Per row:

- `serviceUid` (identity)
- `runDate` (`yyyy-MM-dd`)
- `trainIdentity` (headcode/reporting identity preferred)
- `atocName`
- `modeType` (e.g. `TRAIN`, `REPLACEMENT_BUS`, `BUS`, `SCHEDULED_BUS`)
- `inPassengerService`
- `locationDetail` (derived detail block)

### 7.3 Location detail model

Core fields:

- Scheduled HHmm values:
  - `gbttBookedDeparture`
  - `gbttBookedArrival`
  - `passHHmm`
- Realtime HHmm values:
  - `realtimeDeparture`
  - `realtimeArrival`
- Actual flags:
  - `realtimeDepartureActual`
  - `realtimeArrivalActual`
- Lateness:
  - `departureLatenessMinutes`
  - `arrivalLatenessMinutes`
- Live statuses:
  - `departureStatus`
  - `arrivalStatus`
- Platform:
  - `platform`
  - `platformConfirmed`
  - `platformChanged`
- Display metadata:
  - `displayAs` (e.g. `CALL`, `CANCELLED`, `DIVERTED`, `STARTS`, `TERMINATES`)
  - `delayReason`
- Capacity metadata:
  - `numberOfVehicles`
- Row text sources:
  - `origin[]`
  - `destination[]`

### 7.4 Service detail response model

- `serviceUid`
- `runDate`
- `trainIdentity`
- `atocName`
- `origin[]`
- `destination[]`
- `locations[]`
- `delayReason`

`locations[]` (service location):

- `description`
- `isPublicCall`
- `gbttBookedArrival`
- `gbttBookedDeparture`
- `realtimeArrival`
- `realtimeDeparture`
- `platform`
- `platformConfirmed`
- `displayAs`
- `isRequestStop`
- `delayReason`
- `associations[]`

Association:

- `type` (`JOIN_FROM`, `JOIN_INTO`, `DIVIDE_INTO`, `DIVIDE_FROM`, `FORM_INTO`, `FORM_FROM`)
- `isPublic`
- `serviceUid`
- `runDate`
- `headcode`
- `operatorName`

---

## 8) Mapping and display rules

### 8.1 Time extraction

RTT temporal values may arrive as ISO datetimes.  
Client converts to display-ready HHmm:

- Extract local/hour-minute portion -> `HHmm`
- Display as `HH:mm`

Malformed/short values:

- Implementation may return placeholder (`-`) or suppress expected time.

### 8.2 Delay determination

Preferred source:

- Server-provided lateness minutes.

Fallback:

- Compute delta between booked HHmm and realtime HHmm when both present.

### 8.3 Platform determination

- Planned platform from `platform.planned`.
- Confirmed platform when `platform.actual` exists.
- Changed platform when both exist and differ.

### 8.4 Cancellation

- Service/location cancelled when `displayAs == CANCELLED`.
- Cancelled rows should show cancellation status and not imply confirmed platform certainty.

### 8.5 Bus replacement

Treat `modeType` values:

- `REPLACEMENT_BUS`
- `BUS`
- `SCHEDULED_BUS`

as non-rail replacement modes and display corresponding badge/copy.

### 8.6 Calling point inclusion

A location is a calling point row when:

1. It is a public call.
2. Description exists.
3. Description is not same as service origin description (to avoid duplicate origin headline semantics).
4. Scheduled arrival exists (for time display).

Optional additions:

- Show expected arrival when realtime differs.
- Show request-stop badge.
- Show reason text for delayed/cancelled points.

### 8.7 Associations inclusion

Flatten associations from all locations and include only:

- `isPublic == true`

De-duplicate by stable ID:

- `<type>-<serviceUid>-<runDate>`

---

## 9) Persistence keys

Required user defaults keys:

- `savedStation` (CRS)
- `savedStationDesc` (station display name)
- `savedShowingArrivals` (bool)
- `savedTimeFilterHHmm` (optional HHmm)
- `savedFilterToCRS` (optional CRS)
- `savedShowNonStoppingTrains` (bool)
- `cachedStations` (optional cached catalog payload)

---

## 10) Error handling requirements

### 10.1 Credential/configuration errors

When refresh token is missing/blank:

- Fail fast with explicit configuration error copy.
- App remains usable for local navigation but network data operations fail gracefully.

### 10.2 HTTP failures

- Non-success responses (except approved empty statuses like `204`) must produce user-visible error state.
- Keep existing data visible where possible; avoid blanking prior successful board unless design requires.
- Authentication failures MUST produce credential/configuration specific error messaging where possible.

### 10.3 Decoding failures

- Report as data/parsing error.
- Do not crash on unexpected nullable fields.

### 10.4 Retry behavior

- Manual retry always available.
- Auto-refresh acts as periodic retry in live mode.

---

## 11) Non-functional requirements

- TLS for all RTT traffic.
- Respect device local timezone for date/time filtering.
- Responsive UI with explicit loading indicators.
- Accessibility labels for status, platform, and key row summaries.
- Localization-ready strings (no hardcoded user-facing copy in business logic).
- No tracking declaration in privacy manifest unless functionality changes.
- Clients MUST avoid logging secrets/tokens in plaintext application logs.

---

## 12) Compatibility and migration notes

- Previous repository docs referenced RTT v1 (`api.rtt.io`) path-style search and HTTP Basic auth.
- Current native clients use RTT v2-style data endpoints (`data.rtt.io`) with bearer token exchange.
- New implementations must follow this v2 document unless a platform is explicitly pinned to legacy behavior.

If a platform must support both integration modes, maintain a documented compatibility layer and explicit config toggle.

---

## 13) Test checklist (implementation conformance)

Minimum acceptance tests:

1. Board loads for default station in live departures mode.
2. Arrivals mode issues distinct arrivals request semantics and produces arrival rows.
3. Time filter applies local-date `timeFrom` correctly.
4. Towards filter constrains services.
5. 204 board response renders empty-state without error.
6. Missing credentials surface configuration error.
7. Confirmed platform and changed platform visual states are distinct.
8. Cancelled services show cancellation state and reason text when present.
9. Service detail calling points obey inclusion rules.
10. Associations list contains only public associations and no duplicates.
11. Station fallback works with no network.
12. Station cache updates after successful stops fetch.

---

## 14) Future extensions (non-breaking)

Potential additive enhancements:

- Occupancy/capacity-level indicators.
- Service disruption grouping by reason category.
- Platform confidence tiers beyond planned/actual.
- Backend proxy mode for stronger credential protection.
- Multi-region station presets beyond London focus.

Any additions should remain backward compatible with section 7 contracts or version-bump with migration notes.

---

## 15) Example payloads and requests

The examples in this section are illustrative, redacted, and non-authoritative for value ranges.  
Field presence and structural shape are authoritative.

### 15.1 Token exchange

Request:

```http
GET /api/get_access_token HTTP/1.1
Host: data.rtt.io
Authorization: Bearer eyJhbGciOi...<refresh-token>...abc
Accept: application/json
```

Response (`200`):

```json
{
  "token": "eyJhbGciOi...<short-lived-access-token>...xyz",
  "validUntil": "2026-04-14T16:10:22+01:00"
}
```

### 15.2 Board request (live departures)

Request:

```http
GET /gb-nr/location?code=EUS HTTP/1.1
Host: data.rtt.io
Authorization: Bearer eyJhbGciOi...<access-token>...xyz
Accept: application/json
```

Representative response (`200`):

```json
{
  "systemStatus": {
    "rttCore": "OK",
    "realtimeNetworkRail": "OK"
  },
  "services": [
    {
      "scheduleMetadata": {
        "identity": "C12345",
        "departureDate": "2026-04-14",
        "trainReportingIdentity": "1A23",
        "operator": {
          "name": "Avanti West Coast"
        },
        "modeType": "TRAIN",
        "inPassengerService": true
      },
      "temporalData": {
        "displayAs": "CALL",
        "departure": {
          "scheduleAdvertised": "2026-04-14T16:40:00+01:00",
          "realtimeForecast": "2026-04-14T16:44:00+01:00",
          "realtimeAdvertisedLateness": 4,
          "status": "AT_PLATFORM"
        },
        "arrival": {
          "scheduleAdvertised": "2026-04-14T18:22:00+01:00"
        }
      },
      "locationMetadata": {
        "platform": {
          "planned": "8",
          "actual": "9"
        },
        "numberOfVehicles": 9,
        "isRequestStop": false
      },
      "origin": [
        {
          "location": {
            "description": "London Euston"
          }
        }
      ],
      "destination": [
        {
          "location": {
            "description": "Manchester Piccadilly"
          }
        }
      ],
      "reasons": [
        {
          "type": "DELAY",
          "shortText": "Late inbound service"
        }
      ]
    }
  ]
}
```

### 15.3 Board request (time-filtered arrivals)

Request:

```http
GET /gb-nr/location?code=EUS&timeFrom=2026-04-14T09:30:00&arrivals=true HTTP/1.1
Host: data.rtt.io
Authorization: Bearer eyJhbGciOi...<access-token>...xyz
Accept: application/json
```

Notes:

- The exact arrivals selector (`arrivals=true`, alternate query key, or endpoint behavior) is backend-dependent.
- Clients MUST use whichever explicit selector yields true arrivals behavior.

### 15.4 Board empty response

Response (`204`):

- No body expected.
- Client treats as successful empty services list.

### 15.5 Service detail request

Request:

```http
GET /gb-nr/service?identity=C12345&departureDate=2026-04-14 HTTP/1.1
Host: data.rtt.io
Authorization: Bearer eyJhbGciOi...<access-token>...xyz
Accept: application/json
```

Representative response (`200`):

```json
{
  "service": {
    "scheduleMetadata": {
      "identity": "C12345",
      "departureDate": "2026-04-14",
      "trainReportingIdentity": "1A23",
      "operator": {
        "name": "Avanti West Coast"
      },
      "inPassengerService": true
    },
    "origin": [
      {
        "location": {
          "description": "London Euston"
        },
        "temporalData": {
          "scheduleAdvertised": "2026-04-14T16:40:00+01:00"
        }
      }
    ],
    "destination": [
      {
        "location": {
          "description": "Manchester Piccadilly"
        }
      }
    ],
    "reasons": [
      {
        "type": "DELAY",
        "shortText": "Late inbound service"
      }
    ],
    "locations": [
      {
        "location": {
          "description": "Milton Keynes Central"
        },
        "temporalData": {
          "scheduledCallType": "PUBLIC",
          "displayAs": "CALL",
          "arrival": {
            "scheduleAdvertised": "2026-04-14T17:10:00+01:00",
            "realtimeForecast": "2026-04-14T17:12:00+01:00"
          },
          "departure": {
            "scheduleAdvertised": "2026-04-14T17:12:00+01:00",
            "realtimeForecast": "2026-04-14T17:14:00+01:00"
          }
        },
        "locationMetadata": {
          "platform": {
            "planned": "4",
            "actual": "4"
          },
          "isRequestStop": false
        },
        "reasons": [
          {
            "type": "DELAY",
            "shortText": "Waiting for path"
          }
        ],
        "associatedServices": [
          {
            "associationData": {
              "associationType": "JOIN_FROM",
              "isPublic": true
            },
            "scheduleMetadata": {
              "identity": "C67890",
              "departureDate": "2026-04-14",
              "trainReportingIdentity": "1B45",
              "operator": {
                "name": "London Northwestern Railway"
              }
            }
          }
        ]
      }
    ]
  }
}
```

### 15.6 Stops catalog response

Representative response (`200`):

```json
{
  "stops": [
    {
      "shortCode": "EUS",
      "description": "Euston"
    },
    {
      "shortCode": "KGX",
      "description": "Kings Cross"
    }
  ]
}
```

Parsing rule:

- Rows lacking `shortCode` or `description` are ignored.


# Walk With Thooly

A social walking tracker that turns daily steps into shared moments.  
Users log walks, see paths on a live map, pin places with photos, chat with friends, and climb a friendly ranking — backed by real-time Firebase and GetX state.

---

## 🏃 Purpose

- Motivate consistent walking through light social mechanics (friends, chat, rankings).  
- Keep a private, low-friction journal of walks (steps, distance, kcal, route, photos).  
- Make it effortless: automatic step counting and background GPS with battery-aware updates.

---

## ⚙️ Core Algorithms & App Logic

### 1. Session Engine (steps, distance, calories)

- **Step counting (pedometer):** subscribe to device step stream; set a **baseline** at session start and compute  
  `sessionSteps = totalStepsNow − baseline`.  
  A short **debounce window** prevents bursty writes.

- **Distance (GPS):** sample GPS fixes and accumulate path length using the **haversine** formula between consecutive valid points; reject **outliers** via simple speed/accuracy gates.

  \[
  d = 2R\arcsin\sqrt{\sin^2\frac{\Delta\varphi}{2} + \cos\varphi_1\cos\varphi_2\sin^2\frac{\Delta\lambda}{2}}
  \]

- **Calories:** lightweight estimate `kcal = walkingFactor × distance_km`  
  (factor configurable; default from `kConstant.dart`).

- **State machine:**  
  `IDLE → STARTING → RUNNING → STOPPING → IDLE`

  | State | Action |
  |--------|--------|
  | STARTING | set baselines, create `WALKING` doc (`timeStartAt`) |
  | RUNNING | batch updates (steps/distance/kcal) on timer to reduce Firestore writes |
  | STOPPING | set `timeEndAt`, finalize stats, write summary |

---

### 2. Maps & Places

- **Live route:** show current position and route polyline from GPS samples.  
- **Places (journal pins):** upload photo → Firebase Storage → store URL with `{title, lat, lon, note}`; cache images with `cached_network_image`.

---

### 3. Social Layer

- **Authentication:** Kakao OAuth → create/update `USERS/{uid}` idempotently; session cached with GetStorage.  
- **Friends:** directed/mutual edges in `FRIENDS`.  
- **Chat:** append-only docs in `MESSAGE` `{from, to, text|imageUrl, createdAt}`; real-time updates via Firestore streams.  
- **Ranking:** top-N query over user aggregates (`orderBy(metric, desc).limit(10)`).

---

### 4. App Architecture Highlights

- **Reactive state:** GetX controllers subscribe to Firestore; UI auto-updates.  
- **Resilience:** guarded session transitions, idempotent user creation, throttled writes.  
- **Offline-aware:** local profile/session cache; syncs when online.  
- **Config-first:** constants (collections, calorie factor, default coords) in `kConstant.dart`.

---

## 🧠 Tech Stack

- **Framework:** Flutter (Dart)  
- **State:** GetX, GetStorage  
- **Backend:** Firebase (Firestore, Storage)  
- **Location:** Google Maps (`google_maps_flutter`), `location`  
- **Sensors:** `pedometer`  
- **Media:** `image_picker`, `permission_handler`, `cached_network_image`  
- **Auth:** Kakao SDK  
- **Utils:** `uuid`, `path_provider`

---

## 🗂️ Data Model (Firestore)

| Collection | Description |
|-------------|-------------|
| `USERS/{uid}` | profile, avatarUrl, totals (steps, distance, kcal), createdAt |
| `FRIENDS/{edgeId}` | fromUid, toUid, createdAt |
| `WALKING/{sessionId}` | uid, timeStartAt, timeEndAt, steps, distanceMeters, kcal |
| `MESSAGE/{msgId}` | fromUid, toUid, text / imageUrl, createdAt |
| `PLACES/{placeId}` | uid, title, lat, lon, imageUrl, note, createdAt |

> Firebase Storage: user uploads (avatars, place photos).  
> Indexed queries: `createdAt`, `uid`, ranking metrics.

---

## 🧱 Project Structure


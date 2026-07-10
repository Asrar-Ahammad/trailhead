# Agent Build Instructions: Running Tracker (Flutter, Android-first)

## Project overview
Native Android app (Flutter) for tracking runs via live GPS, true background tracking through locked screen. Backend unchanged from original PWA plan — Next.js API routes, Prisma, Supabase Postgres. AI layer (OpenAI) for summaries, coaching, chat-based stats queries. Personal record (PR) leaderboard with auto-detected best-effort segments. iOS deferred — build Android-only for now, keep platform-specific code isolated so iOS is addable later without a rewrite.

## Tech stack
- Frontend: Flutter (Dart), Android target only for now (`flutter build apk` / `appbundle`)
- State management: Riverpod
- Local storage: Isar (fast, typed, good for run/point records) or sqflite if team prefers raw SQL — pick Isar unless a reason emerges not to
- Background location: `flutter_background_geolocation` (transistorsoft) — handles Android foreground service, persistent notification, motion-aware tracking. Paid license above free tier usage — evaluate against free stack (`geolocator` + `flutter_foreground_task` + manual foreground service setup) if budget matters. Recommend starting with the paid plugin: reliability on background location is exactly the problem being solved, worth not fighting the free stack's rough edges.
- Step tracking: `pedometer` package — device step-counter sensor, feeds stride length/cadence calc (separate from GPS/location stack above)
- Maps: `flutter_map` (OpenStreetMap/CartoDB tiles — same dark/light tile sources as original web plan, visual continuity)
- Charts: `fl_chart`
- Animations: Flutter's native animation system — `AnimatedContainer`/`AnimatedOpacity`/implicit animations for simple transitions, `AnimationController` + `Tween` for custom sequences (route draw, count-up, completion sequence), `Hero` for shared-element transitions (icon morphs), optionally `flutter_animate` package for cleaner declarative syntax over raw controllers. This replaces the old Framer Motion + GSAP web-only rule — those don't apply in Flutter, this is the Flutter-native equivalent, same design intent (spring-like, purposeful, sequenced).
- Backend: unchanged — Next.js API routes (route handlers), hit over HTTPS from Flutter via `dio` or `http` package
- DB: Prisma ORM + Supabase Postgres (unchanged)
- Auth: **Supabase Auth** (switched from Clerk — Clerk has no official Flutter SDK; Supabase Auth has a proper Flutter package and you're already on Supabase Postgres, one less integration to bridge)
- AI: OpenAI API, called from backend only (unchanged — Flutter app never holds the OpenAI key, always goes through your Next.js API routes)
- Icons: `pixelarticons` (primary, pixel-art style) + `phosphor_flutter` (supplementary, for icons pixelarticons doesn't cover) — used together, judgment call on which fits each spot rather than a rigid per-context split
- Deployment: Play Store (internal testing track first, production later). Backend stays on Vercel.

## Non-negotiable constraints
- Modular code, strictly. No god files, no god widgets, no dumping logic into `main.dart` or single massive screen files. Enforce structure:
  - Feature-based folders (`lib/features/run_tracking/`, `lib/features/history/`, `lib/features/records/`, `lib/features/ai/`, etc.), not type-based dumping (`lib/screens/`, `lib/widgets/` as flat catch-alls)
  - Each feature folder: its own `data/` (models, repositories, API clients), `application/` (Riverpod providers/controllers), `presentation/` (screens, widgets) — consistent layering across every feature
  - One class/widget per file, file named after the class. No multi-widget files "for convenience."
  - Business logic never lives inside a widget's `build()` method — widgets stay presentational, logic lives in controllers/providers/services, widget just reads state and calls methods
  - Shared/reusable widgets (buttons, cards, the `PressableScale` wrapper, etc.) live in `lib/shared/widgets/`, not duplicated per feature
  - API/networking layer isolated behind a repository interface per feature — screens and controllers never call `dio`/`http` directly, always through a repository, so backend changes or testing/mocking don't ripple through UI code
  - Constants (colors, spacing, durations, API base URLs) centralized, never hardcoded inline in widgets — this also enforces the existing "one token set reused everywhere" design rule
  - If any single file exceeds ~200-300 lines, that's a signal to split it — flag and refactor rather than let it grow
  - This applies from Phase 1 onward, not retrofitted later — establishing folder structure and layering conventions is part of the Phase 1 setup task, before any tracking logic is written
- Physical Android device only, for all development, preview, and testing. No emulator/simulator at any point — development machine hardware isn't capable enough to run an Android emulator usably, and background location behavior doesn't replicate accurately in an emulator anyway (double reason, not just a preference). Connect device via USB (`flutter run` with device attached) or wireless ADB debugging. Every "test on real device" note elsewhere in this doc is not optional — treat it as the only testing method available, not one option among several.
- No emojis anywhere in UI. Not in buttons, labels, toasts, notifications, AI-generated text, empty states. Text and icons (`pixelarticons` + `phosphor_flutter`) only. Strip emojis from AI outputs before render if model adds them despite instruction.
- Background GPS tracking must survive locked screen and backgrounded app (not force-closed/removed from recents). This is the whole point of the native switch — foreground service + persistent notification, not a Wake Lock workaround.
- All run data written to local DB (Isar) first. Backend sync is best-effort, retried, never blocking the live tracking UI.
- No GPS point sent to backend individually — batch insert only.
- Every AI feature: define exact input schema, exact output schema (JSON mode), before writing the prompt. No free-text parsing of AI output beyond JSON.parse equivalent.
- No AI feature blocks core tracking flow. AI calls always async, always have graceful fallback (e.g., if summary generation fails, just show raw stats, no error state on run completion screen).
- OpenAI API key never touches the Flutter app or its bundle — server-side only, called via your own backend API routes.

---

## Screen inventory

Full list of screens/states the app needs. Cross-reference against User interaction flow (below) for sequencing, and Design system spec for visual treatment.

- **Auth**: login/signup via Supabase Auth, gate before Home.
- **Permission gate**: shown on first Record visit or on Start tap if background location was revoked. Explains why background location is required, requests foreground then background permission (Android 10+ two-step). Blocks past this point on denial, links to Android app settings.
- **Home**: greeting, weekly summary widget (distance/time/pace, PR banner if applicable, progress delta, AI coach line), streak indicator (single consistent unit), quick-start Run/Walk buttons, most recent activity card (→ Run Detail). Bottom nav: Home / Record / You.
- **Record — pre-run**: map centered on current location, GPS lock status, Run/Walk mode toggle, Start button (disabled until GPS lock acquired).
- **Record — active run**: live map + drawing polyline, time/pace/distance stats, stride length/cadence (live, optional), "GPS signal weak" banner (conditional), Pause/Resume + Stop controls. Persistent notification mirrors live stats while backgrounded.
- **Finish confirm dialog**: triggered by Stop tap (timer halted immediately) — Finish & Save / Discard / Resume.
- **Completion screen**: sequenced animation (route draw → stats count-up, including stride/cadence/calories/elevation → PR banner if applicable → AI comment fade-in), save/discard bottom sheet anchored throughout.
- **Run Detail**: full map + static route, full stat grid (same set as completion screen), splits table (per km: time, pace), AI summary, edit/delete actions.
- **You — Progress sub-tab**: this-week stats, 12-week bar chart, monthly calendar with streak highlighting.
- **You — Activities sub-tab**: searchable list of past runs, each row → Run Detail.
- **You — Records sub-tab**: Best Efforts (automatic, GPS-derived) and All-Time PRs (manual entry, race-certified) shown separately — toggle/tab between the two, not merged. Categories: 100m/1k/5k/10k/half/marathon, plus longest run, longest duration, max elevation (Best Efforts only, no manual equivalent for these). "Add PR" action for manual All-Time PR entry.
- **Settings**: theme toggle (system/dark/light), units (km/mi), weight (for calorie calc), streak rest-day config, UI Sounds toggle (see Retro UI Sounds section), sign out.
- **Empty/error states**: not standalone pages — states within Activities/history/no-internet — off-route visual motif, short text, single action button.

### Open gaps — not yet assigned a screen
- **Training plan (9.14)**: AI feature speced, no screen defined for viewing/starting/tracking against a generated plan. Needs a decision — dedicated tab, or a card/entry point off Home or You — before Phase 9 build reaches this feature.
- **Chat interface (9.3)**: stats-query AI feature speced, no entry point defined — dedicated tab, floating action button, or entry from You screen. Needs a decision before Phase 9 build reaches this feature.
Both deferred intentionally — revisit when Phase 9 build order reaches these specific sub-features, not before.

---



### App launch
Cold start → check Supabase Auth session. Logged in → Home. Not logged in → auth screen.
If a run was in-progress when app was last killed: recover draft from Isar, reconnect to foreground service if still alive, resume straight to active-run screen (not Home) — user shouldn't have to re-navigate to their own in-progress run.

### Home screen
Weekly summary widget, streak indicator (single consistent unit, no days/weeks mismatch), quick-start Run/Walk buttons, most recent activity card (tap → Run Detail). Bottom nav: Home / Record / You.

### Starting a run — permission gate
Background location permission is required before a run can start, not optional. On first Record-tab visit (or first Start tap): request foreground location → explain why → request background location (`ACCESS_BACKGROUND_LOCATION`). If denied: **block run start entirely**, show a blocking screen explaining background tracking is required for the app to work, with a direct link to Android app settings to grant it. No foreground-only fallback mode — half-working tracking that silently stops when the screen locks is worse than a clear upfront block, given this was the exact problem the native rewrite exists to solve. Re-check permission status every time Start is tapped, not just once at first launch — user could have revoked it since.

### Active run
Map screen, GPS acquiring lock (Finish/Start button disabled until lock acquired). Tap Run/Walk mode → tap Start. Foreground service starts, persistent notification appears. Live screen: map + polyline, time/pace/distance stats, pause/stop controls. Tracking continues through lock/background — notification shows live stats, reopening the app resumes the live screen exactly where it left off.

### Finishing a run
Tap Stop → **timer halts immediately** (no ambiguity about whether it's still running), then a confirm dialog appears: Finish & Save / Discard / Resume. This order matters — stopping the clock first means an accidental tap costs nothing (time isn't still ticking while they decide), and Resume un-stops cleanly since no time was lost. Only on explicit "Finish & Save" does the completion sequence fire: route draws → stats count up → PR banner (if any) → AI comment fades in, save/discard bottom sheet anchored throughout. Save → instant local write (Isar), background sync queued silently.

### Post-save
Lands on Run Detail (map, splits, AI summary) or back to Home. Sync happens silently; a "pending sync" indicator only appears if sync actually fails after retries.

### You tab
Progress / Activities / Records sub-tabs. Records: Best Efforts / All-Time PRs (see Phase 5 for the distinction — separate systems, not merged). Settings (gear icon): theme toggle, units, streak rest-day config, UI Sounds toggle.

### Empty/error states
No internet, empty history, run-not-found: consistent off-route visual motif (per Design system spec), short text, single clear action button — no dead ends.

### Force-kill recovery
If the app/service is force-killed mid-run (swiped from recents, not just locked/backgrounded) — tracking stops, foreground service dies, no way around this on Android. On next app open: detect the orphaned draft in Isar (status still "running" but service no longer alive), auto-save it as a completed run using whatever data was captured up to the kill point, surface it in history. No prompt, no discard option — treat it the same as a normal finished run (marked/flagged internally as force-terminated if useful for the AI summary to phrase honestly, e.g. "run ended early"). User shouldn't lose data or face a decision dialog for something outside their control.

### Pause behavior
Pause does not stop the location stream — GPS keeps recording in the background at the same rate. Points captured while paused are tagged (`isPaused: true` or excluded via a paused-interval range) and excluded from distance/duration/pace calculations, but retained in raw data. Rationale: resuming tracking from a cold GPS stream is slower/less accurate than keeping the stream warm; simpler to filter paused-interval points at calculation and map-render time than to stop/restart the location subscription.

### GPS signal loss mid-run
No auto-pause, no silent gap. If accuracy readings degrade or updates stop arriving for a sustained interval (needs a threshold, e.g. no accepted point in 15-20s), show a subtle non-blocking banner: "GPS signal weak." Recording continues best-effort with whatever the OS provides. Banner clears automatically once accuracy/update frequency recovers. Doesn't block or alter Finish/Pause controls.

---



Set up `flutter_background_geolocation` (or free-stack equivalent):
- Android manifest: `ACCESS_FINE_LOCATION`, `ACCESS_BACKGROUND_LOCATION` (Android 10+ requires separate runtime request, cannot be requested in the same dialog as foreground permission — request foreground first, explain why, then request background as a second step with clear in-app copy before the OS prompt). Denial blocks run start entirely — see User interaction flow section above for the exact gate behavior, no foreground-only fallback mode.
- Permission denial policy: hard block. If background location isn't granted, the Start button on the run screen stays disabled, with a persistent explanation card ("Background location required to track your run — grant access to continue") and a button linking straight to the permission request flow (or Android app settings if permanently denied). No foreground-only fallback mode, no degraded tracking option — the app's core purpose depends on this permission, don't build a lesser experience around its absence.
- Foreground service with persistent notification ("Run in progress — 3.2 km, 22:14") — required by Android for continuous location access during a run, cannot be avoided, make the notification itself useful (live stats) rather than a dead requirement.
- Configure plugin: distance filter (~5-10m between updates, not every GPS tick), `enableHighAccuracy`, tracking mode active only during a run session (start/stop the service explicitly, don't run it idle).

Build `RunTrackerController` (Riverpod):
- On each location update: compute delta distance from last accepted point using Haversine formula
- Reject points where computed instantaneous speed > 12 m/s (~43 km/h) — GPS jump filter — or `accuracy` value > 30m
- Maintain running total distance, elapsed time (pause-aware), current pace (rolling 10-second window average, not instantaneous)
- States: idle, running, paused, stopped
- Pause: location stream stays active (don't stop/restart the subscription), points captured during paused intervals tagged and excluded from distance/duration/pace math but retained in raw data — see User interaction flow for rationale.
- Signal loss: track time since last accepted point. If exceeds ~15-20s, surface a "GPS signal weak" state to the UI layer (non-blocking banner, see User interaction flow) — clears once points resume at normal cadence. No auto-pause.
- Step count / stride length: use `pedometer` package (device step-counter sensor, separate stream from GPS) alongside location tracking. Accumulate step count during active (non-paused) intervals only — same paused-exclusion logic as distance/duration. At run finish: `avgStrideLengthM = distanceM / stepCount` (guard divide-by-zero — null both fields if stepCount is 0 or sensor unavailable on device). `avgCadenceSpm = stepCount / (durationS / 60)`, same guard. Live cadence display during run is a nice-to-have (rolling 10s window like pace), not required for v1 — stride length itself is a post-run stat, doesn't need to be live.
- Calories: needs `User.weightKg` — if unset, prompt for it once (Settings, or a one-time non-blocking prompt on first completed run, user's choice which — don't block run start over it, same spirit as the background-location gate is a hard block but this isn't safety-critical). If weight still unknown at calc time: `caloriesKcal` stays null, display "—" not a fabricated number. Formula: MET-based — `calories = MET × weightKg × (durationS / 3600)`. MET value derived from average pace (lookup table, approximate — running MET roughly ranges 6 at very easy pace up to 12-15+ at fast pace, standard published tables exist, use one rather than inventing values). Add a flat elevation adjustment if `elevationGainM` present (climbing costs more energy than flat-pace MET alone accounts for) — small correction, don't over-engineer this, it's an estimate not a lab measurement and should be presented as such in UI copy ("~420 kcal (estimate)").
- Raw GPS data stays untouched (accuracy). Separate display layer: moving average smoothing on coordinates before rendering polyline — reduces zig-zag from urban canyon/tree cover drift without corrupting stored data.

Build UI:
- Start / Pause / Resume / Stop controls
- Live display: distance (km, 2 decimals), pace (min/km), duration (hh:mm:ss) — updates even while app backgrounded, screen shows last-known state on foreground return, notification shows live state while backgrounded
- Test explicitly: start run, lock screen, wait 5+ minutes, unlock — verify distance/route continued accumulating. Physical device only (see Non-negotiable constraints) — background location cannot be meaningfully verified any other way.

Local storage (Isar):
- Collections: `Run` (draft/complete status) and `RunPoint` (lat, lng, timestamp, accuracy, speed)
- Write points in batches (every 5-10 points, not per point) to avoid excessive DB writes
- On stop: mark run complete, trigger sync attempt (Phase 4)
- Corruption check: version field + checksum on run draft object. On app relaunch, validate in-progress draft before resume. If mismatch/corrupt: delete draft, notify user, don't attempt partial recovery.
- Force-kill recovery: on relaunch, if a draft's status is still "running" but its foreground service is no longer alive, don't attempt to resume it — auto-finalize it as a completed run with whatever points were captured, save directly to history. See User interaction flow for full rationale.

Acceptance: full run trackable with app backgrounded and screen locked, 30+ min session, data persists through app relaunch (recover in-progress run from local DB on start, reconnect to running foreground service if still active).

---

## Phase 2: Map + route

- `flutter_map` widget, OpenStreetMap/CartoDB tile source (dark tiles default, light tiles for light theme — same tile provider choice as original web plan for visual continuity)
- During run: polyline updates live from accepted GPS points, rendered on map even while foregrounded (map view only needed in foreground — background tracking doesn't need the map rendering, just the location stream)
- Post-run: static map with full route polyline, start marker (green), end marker (red)
- Map tile caching: cache viewed tiles locally (`flutter_map_tile_caching` or similar) so previously-seen areas render offline

---

## Phase 3: Backend integration (existing API, unchanged)

Backend stays as originally speced — Next.js API routes, Prisma, Supabase Postgres. Flutter app is just a new client hitting the same HTTPS endpoints.

Prisma schema (unchanged from original plan):
```prisma
model User {
  id        String   @id // Supabase Auth user id
  email     String   @unique
  weightKg  Float?   // optional, prompts calorie calc accuracy — see Phase 1 note
  createdAt DateTime @default(now())
  runs      Run[]
}

model Run {
  id            String     @id @default(cuid())
  userId        String
  user          User       @relation(fields: [userId], references: [id])
  startTime     DateTime
  endTime       DateTime
  distanceM     Float      // meters
  durationS     Int        // seconds, excludes paused time
  avgPaceSPerKm Float
  elevationGainM Float?
  stepCount     Int?       // from device pedometer, excludes paused intervals
  avgStrideLengthM Float?  // distanceM / stepCount, null if step data unavailable
  avgCadenceSpm Float?     // steps per minute, optional but cheap once step count exists
  caloriesKcal  Float?     // estimated, see Phase 1 note — null if weight unknown
  title         String?
  aiSummary     String?
  lastModifiedAt DateTime  @default(now()) // conflict resolution, see Phase 4
  syncedAt      DateTime   @default(now())
  points        RunPoint[]
}

model RunPoint {
  id        String   @id @default(cuid())
  runId     String
  run       Run      @relation(fields: [runId], references: [id])
  lat       Float
  lng       Float
  elevation Float?
  timestamp DateTime
  accuracy  Float?
  sequence  Int      // order within run
}

// PersonalRecord model: see Phase 5 (PR leaderboard) for the current schema —
// includes source (best_effort/manual) and proofUrl fields added there, don't duplicate an older version here.

model Streak {
  id            String   @id @default(cuid())
  userId        String   @unique
  currentCount  Int
  longestCount  Int
  lastRunDate   DateTime
  restDaysUsed  Int      @default(0) // resets weekly
}
```

Auth: Supabase Auth session token attached to every API request (Bearer token header). Backend route handlers validate the Supabase JWT server-side, derive `userId` from it — never trust a client-sent `userId`.

API routes (unchanged surface, same as original plan):
- `POST /api/runs` — create run (metadata only)
- `POST /api/runs/:id/points` — batch insert points (accept array, max 500 per call)
- `GET /api/runs` — list user's runs, paginated
- `GET /api/runs/:id` — single run + points
- `GET /api/records` — PR leaderboard, all categories
- `GET /api/streak` — current + longest streak count
- `GET /api/summary/weekly` — weekly summary widget payload

Flutter networking: `dio` package, base client with auth header interceptor (attaches current Supabase session token to every request, refreshes on 401).

---

## Phase 4: Sync

- On run stop, queue sync job (local job table in Isar — pending/in-progress/failed/complete status per run)
- Sync: POST run metadata → get run ID → POST points in batches, serialized (sequential, not parallel) — long runs won't fire dozens of concurrent requests, easier failure debugging
- Retry: exponential backoff, max 5 attempts, surface non-blocking "sync pending" indicator in UI if all fail. Use `WorkManager` (via `workmanager` Flutter plugin) for retry scheduling that survives app kill — Android-native background job scheduling, more reliable than an in-app timer alone.
- Idempotency: client generates UUID for run at creation, send as `clientRunId`, backend upserts on that key — prevents duplicate runs from double-sync
- Concurrent device conflict: `lastModifiedAt` on Run (already in schema above). Default: first successful sync wins, second gets rejected with "already synced" message — avoids silent data loss from last-write-wins overwriting a different device's data.

---

## Phase 5: History + stats + PR leaderboard

Run list screen:
- Paginated list, sortable by date/distance/pace
- Each row: date, distance, duration, avg pace, thumbnail map (optional, low priority)

Run detail screen:
- Full map + route
- Splits table (per km): time, pace
- Stride length + cadence + calories shown alongside distance/pace/elevation stats (both completion screen and run detail) — null-safe display (show "—" not "0.0m"/"0 kcal" if sensor/weight data unavailable, don't imply a false zero). Calories labeled as an estimate in UI copy, not presented as precise.
- AI summary (if generated)

Aggregate stats screen (`fl_chart`):
- Weekly/monthly total distance, run count, avg pace trend
- Line chart: pace over time, distance over time

**PR leaderboard — build spec, Strava-model (Best Efforts + manual All-Time PRs, two separate systems):**

Add to Prisma schema:
```prisma
model PersonalRecord {
  id         String   @id @default(cuid())
  userId     String
  category   String   // "100m","1k","5k","10k","half","marathon","longest_run","longest_duration","max_elevation"
  runId      String?  // null for manually-added All-Time PRs not tied to a tracked run
  value      Float    // time in seconds for distance categories, meters/seconds for others
  achievedAt DateTime
  rank       Int      // 1, 2, or 3
  source     String   // "best_effort" (auto, GPS-derived) or "manual" (user-entered, e.g. race result)
  proofUrl   String?  // optional link to race results, only relevant for manual entries
}
```

**System 1 — Best Efforts (automatic, GPS-derived):**
- Uses elapsed time, not moving time — matches Strava's model, clock counts continuously through the run the same way a race clock would, distinct from your general pause-handling elsewhere (live pace/duration during a run still excludes paused intervals as speced in Phase 1 — this elapsed-time rule applies specifically to Best Effort PR calculation, not the live tracking stats).
- Sliding-window scan over cumulative distance array: find minimum-elapsed-time window matching each target distance (100m, 1k, 5k, 10k). Two-pointer over points sorted by timestamp/cumulative distance. Expand window until target distance reached, record elapsed time (including any paused time within that window), slide start pointer forward, repeat. O(n) per category per run.
- Only run this scan for runs long enough to contain the segment.
- Data-quality gate before accepting a Best Effort candidate: reject the window if GPS accuracy was poor across it (points flagged low-accuracy per Phase 1/8 filtering) or if the run came up short of the target distance overall — don't silently produce a slightly-short "5k" from a 4.9km run.
- Compare accepted result against existing PersonalRecord rows for that category where `source = "best_effort"`. Insert if beats rank 3 among best-effort entries, re-rank top 3, evict 4th. `runId` set, `source = "best_effort"`.
- Other record categories (single value, still automatic): longest run, longest duration, highest elevation gain — direct comparison against existing top 3 on run completion, same `source = "best_effort"` treatment.
- Trigger: server-side, in the points-insert route handler, after all points saved (unchanged — this logic lives in the backend regardless of client platform).

**System 2 — All-Time PRs (manual entry):**
- Separate from Best Efforts entirely — for race-certified times that won't match GPS-measured distance (course measurement differs from GPS track, a known and expected discrepancy, not a bug to fix).
- "Add PR" action on the Records screen: user picks a distance category, enters a time, optionally attaches a `proofUrl` link (race results page, Strava-equivalent activity, etc.) and a date.
- Stored with `runId = null`, `source = "manual"`.
- Manual and best-effort entries for the same category are tracked and ranked *separately*, not merged into one top-3 — mirrors Strava's actual model where these are genuinely different concepts (GPS-segment best vs. official race time), not competing for the same slots.

UI: leaderboard screen, one card per category, tabbed or toggled between Best Efforts and All-Time PRs (don't silently merge them — user should be able to tell which is which). Best Effort cards show top 3 with rank + run date link (tap → Run Detail). All-Time PR cards show the manual entry with date + proof link if provided, plus the "Add PR" action. In-app notification/toast on run completion if a new Best Effort is set: "New 5k Best Effort! 24:12 (previous: 24:45)" — deliberately not called "PR" in this toast, to keep the terminology distinction visible to the user (Best Effort vs. All-Time PR are different things throughout the UI copy, not interchangeable labels for the same concept).

---

## Phase 5b: Streak tracking

Logic (unchanged from original plan, backend-side):
- On run sync success: check `lastRunDate`. If yesterday or today, increment/maintain. If gap > allowed rest days, reset `currentCount` to 1.
- Update `longestCount` if `currentCount` exceeds it.
- Timezone: use user's local date (not UTC) for day-boundary calc — send device timezone with sync request, store on User model.

UI:
- Streak count on home screen — pick one unit consistently (days, not a mix of "days" and "weeks" across screens — this was an inconsistency flagged in the earlier PWA build, fix it in the native rebuild from day one)
- Milestone markers (7/30/100 days) — text only, no emoji
- Streak-at-risk indicator if no run logged today and day ending soon (local time evening threshold)

---

## Phase 5c: Weekly summary widget (home screen)

Card on home screen, computed on load, cached per week (Monday-Sunday, user local timezone).

Sections, in order:
- Header: "Weekly Summary" + date range. Pixel or Phosphor trophy/chart icon (whichever reads better at this spot), no emoji.
- Stats row: total distance (km), total time (h m), avg pace (min/km) — computed direct from DB, no AI.
- New PR banner: shown only if PersonalRecord `achievedAt` falls within current week. Omit entirely if none.
- Progress delta: current week vs same period last month (or prior week if < 1 month history) — computed direct, no AI.
- AI Coach line: 1-2 sentence text from coaching feedback (9.6), cached per week, else trigger generation.

API: `GET /api/summary/weekly` — returns all fields above in one payload, computed server-side.

Home screen also gets: quick-start Run/Walk buttons (skip navigating to a separate tab to start tracking), addressing the "home screen feels empty" gap flagged during the PWA build.

---

## Design system spec (Strava-inspired, Flutter-native)

Reference points: bottom sheets for secondary actions (Flutter `showModalBottomSheet` / `DraggableScrollableSheet`, not new route pushes for filters/settings/run-details-drawer-style content), route polyline morph on save screen, animated route line-draw as default post-run view. Build original visual identity — don't clone Strava's brand assets/colors/logo.

**Direction: modern Strava-inspired base + 90s pixel accent layer.** Layout, spacing, color system, and card/button shapes stay clean and modern (legibility and usability come first — this is a fitness app people glance at mid-run). The retro/pixel treatment is applied deliberately: icons draw primarily from `pixelarticons`, with `phosphor_flutter` filling gaps where pixelarticons lacks coverage (see Iconography) — used tastefully, not forced into a rigid split. Short punchy UI labels/badges/achievement moments use Pixelify Sans. Body text, hero stat numbers, form fields, and AI-generated copy stay in the modern faces — those need to stay easily/quickly readable, not stylized. See Typography and Iconography subsections below for the exact split.

### Color palette
Semantic tokens, defined once as a `ThemeExtension`, referenced everywhere — no raw hex in widget code.

Dark theme:
- Background (base): `#121212`
- Surface (cards, sheets, elevated panels): `#1C1C1E`
- Surface raised (modals, dialogs): `#242426`
- Primary accent (coral — effort, progress, active states, PRs): `#FF5A3C`
- Primary accent muted (disabled/inactive variant): `#7A2E20`
- Text primary: `#FFFFFF`
- Text secondary: `#A0A0A3`
- Text disabled: `#5C5C5E`
- Border/divider: `#2E2E30`
- Success (sync complete, PR achieved): `#4CD97B`
- Warning (GPS weak, sync pending): `#F2B84B`
- Error (failed sync, denied permission): `#FF5252`

Light theme:
- Background (base): `#FAFAFA`
- Surface: `#FFFFFF`
- Surface raised: `#F0F0F1`
- Primary accent: `#E8492D` (same coral family, shifted for 4.5:1 contrast on light bg — don't reuse dark-mode hex unchanged)
- Primary accent muted: `#F5C4B8`
- Text primary: `#1A1A1A`
- Text secondary: `#6B6B6E`
- Text disabled: `#B8B8BA`
- Border/divider: `#E2E2E4`
- Success: `#2A9D5C`
- Warning: `#C98A2E`
- Error: `#D4342A`

Every color pairing (text on background, accent on surface) checked against WCAG 4.5:1 (body) / 3:1 (large text) before use — verify at build time, not by eye, per existing UI/UX standards section.

### Typography
Three-font system — modern base + retro accent layer, final choice:
- Display face: **Barlow Condensed**, bold weight only — hero numbers (distance, pace, duration, calories on completion/detail screens). Kept modern/clean here deliberately — precise stat numbers need to stay instantly legible, a pixel font at 56sp would hurt readability more than it adds character.
- Body face: **Space Grotesk**, weights 400/500/600/700 — general UI text (body copy, most labels, buttons, navigation).
- Retro accent face: **Pixelify Sans** — used for section labels/small-caps headers (e.g. "WORKOUT STATS", "NEW PR"), nav bar labels, badge/chip text, streak counters, and achievement/celebration copy on the completion screen and PR banners. This is the "90s" layer — applied to short, punchy UI text where the pixel look reads as playful rather than illegible; never applied to body paragraphs, AI-generated summary text, or anything requiring sustained reading.
- All three via `google_fonts` Flutter package (open-source, no licensing cost) — pull once at theme setup, don't re-fetch per widget.
- All numeric stat displays use tabular figures (`FontFeature.tabularFigures()` in Flutter `TextStyle`) so digits don't jitter during count-up/live-update animations. Applies to Barlow Condensed hero numbers; Pixelify Sans counters (e.g. streak day count if styled retro) should use a monospace-adjacent variant of the same font where digit-jitter matters.

Scale (Flutter `TextTheme` mapping):
- Display large (hero stat numbers, e.g. completion screen distance): 56sp, bold, Barlow Condensed
- Display medium (secondary hero stats): 36sp, bold, Barlow Condensed
- Headline (screen titles, "Weekly Summary"): 24sp, bold, Space Grotesk
- Title (card headers, section labels): 18sp, semibold, Space Grotesk
- Body large (primary readable text): 16sp, regular, Space Grotesk
- Body medium (secondary text, timestamps): 14sp, regular, Space Grotesk
- Label (buttons, tags, small caps section headers like "WORKOUT STATS"): 12sp, semibold, Space Grotesk, letter-spacing +0.5, often uppercase
- Retro label (badge text, nav labels, achievement callouts): 11-13sp (pixel fonts need slightly larger sizes than equivalent sans to stay legible), Pixelify Sans, letter-spacing +0.5 to +1, often uppercase — size up rather than down if legibility feels tight, don't shrink a pixel font to fit a space designed for Space Grotesk

### Spacing scale
4px base unit, consistent multiples — no arbitrary padding values in widget code:
- `xs`: 4px — tight icon/text gaps
- `sm`: 8px — internal component padding
- `md`: 16px — standard card/section padding, default gap between stacked elements
- `lg`: 24px — section separation
- `xl`: 32px — major layout breaks (e.g. above bottom nav)
- `xxl`: 48px — screen-top breathing room

### Shape + elevation
- Corner radius: 12px standard (cards, buttons), 20px for bottom sheets (top corners only), 999px (full pill) for chips/badges/streak indicators, 8px for input fields
- Elevation: dark theme uses surface-color layering (lighter surface = "higher") rather than heavy drop shadows — shadows read poorly on near-black backgrounds. Light theme can use subtle shadows (`elevation: 1-2` equivalent, low opacity) in addition to surface layering.
- Cards: no border in dark theme (surface-color contrast does the separation), thin 1px border (`Border/divider` token) in light theme where surface-on-background contrast is weaker

### Iconography — pixelarticons + Phosphor, used tastefully
Two icon sets, no rigid rule dictating which set covers which context — pick whichever fits each specific icon, based on availability and visual fit, not a fixed mapping.
- **`pixelarticons`** (pub.dev, MIT license): pixel-art icon font, primary/default choice — reach for this first. Usage identical to Flutter's built-in `Icons` class: `Icon(Pixel.home)` instead of `Icon(Icons.home)`. Check https://pixelarticons.com/free/ for the ~480-icon set before assuming a gap.
- **`phosphor_flutter`**: supplementary set, used where pixelarticons doesn't have a matching icon (e.g. running-figure, stride/cadence-specific icons) or where a pixel-art rendering genuinely doesn't read well at a given size/context. `regular` weight default, `fill` weight for active/selected states.
- Judgment call, not a formula: don't force a Phosphor icon into pixel style just for consistency if pixelarticons has no equivalent, and don't reach for Phosphor out of convenience if a decent pixelarticons match exists — check pixelarticons first every time, fall back only when it's genuinely missing.
- Within one component instance (e.g. all four stat-card icons on a single screen), prefer icons from the same set where reasonable, so a single card grouping doesn't visibly mix styles — but this is a soft preference for visual coherence within a cluster, not a hard rule blocking Phosphor use elsewhere on the same screen.
- Standard sizes: pixelarticons at 16px/24px/32px (multiples that stay crisp on its pixel grid), Phosphor at 20px/24px/32px.
- Icon color always follows text-secondary token unless conveying accent/status (PR, success, warning, error use their respective semantic color) — applies to both sets equally.
- If a custom icon is ever hand-drawn to fill a gap: match pixelarticons' grid/stroke style by default (it's the primary set), not Phosphor's.
- Pair with `pixelify_flutter` for the achievement/celebration moment styling (retro panel borders, scanline/dither effects) already speced — that package handles broader retro UI treatment, independent of which icon set is used within it.

### Components
- **Primary button**: filled, accent background, white text, 12px radius, 48dp min height (touch target), `PressableScale` micro-interaction (0.97 scale on press)
- **Secondary button**: outlined, accent border + text, transparent/surface background, same sizing
- **Text button**: no background/border, accent text only, for low-emphasis actions (Discard, Cancel)
- **Stat card** (Home workout stats, run detail grid): surface background, 12px radius, `md` padding, label (retro label style, Pixelify Sans, text-secondary, uppercase) above value (Display medium or Body large depending on hierarchy, Barlow Condensed), icon top-right (pixelarticons preferred, Phosphor where needed)
- **Bottom nav**: 3 items fixed (Home/Record/You), icons (pixelarticons preferred, per Iconography) filled/solid variant for active tab + accent color + small dot indicator beneath (matches existing built screens), inactive items text-secondary outline variant, nav labels in Pixelify Sans retro label style
- **Bottom sheet**: 20px top-corner radius, drag handle bar centered at top, backdrop scrim 60% opacity black regardless of theme
- **Chip/badge** (streak flame, PR rank): pill shape, icon (pixelarticons preferred) + Pixelify Sans label, accent-muted background with accent icon/text in default state, full accent background for emphasized state (e.g. new PR)
- **Input field**: 8px radius, surface-raised background, visible label above (Space Grotesk, not Pixelify — form labels need to stay easily scannable, not placeholder-only, per accessibility spec), accent-colored focus border, error state uses error token on border + helper text
- **Achievement/celebration moment** (new PR banner, streak milestone, completion-screen unlock): this is where the retro layer gets to be loudest — Pixelify Sans headline text ("NEW 5K PR"), pixel trophy/medal icon, optional subtle pixel-dither or scanline texture behind the banner (low opacity, doesn't obscure text, purely decorative flourish for this one moment type) — keep this treatment exclusive to genuine achievement moments so it retains impact, don't reuse the dither texture as generic decoration elsewhere

### Retro UI sounds (settings toggle)
Extends the pixel/retro layer into audio — 8-bit sound effects for key interactions, off by default.

**Toggle**: Settings screen, "UI Sounds" — off by default, user opts in. Persist via `shared_preferences` alongside theme/units preferences.

**Behavior**:
- Respects device silent/vibrate mode — check system audio state before playing (`AudioSession` / platform silent-mode check), stay silent if the device is silenced, don't force playback like a game would. This is a productivity/fitness app, not a game — the sound is a delight-flourish, not core functionality, so it defers to the phone's ambient state.
- Fully independent from voice coaching TTS (9.9) and split callouts — no ducking, no coordination logic, may overlap if both happen to fire close together. Keep the two systems decoupled rather than building cross-awareness between them.
- Only plays while toggle is on AND app is foregrounded — no sound events fire from background/locked-screen state (e.g. no sound if a PR were somehow detected while backgrounded; PR detection happens server-side on sync anyway, so this is naturally foreground-only in practice).

**Sound event map** — distinct short 8-bit clip per event type, each event category gets its own sound, not shared/generic:
- Navigation (tab switch, screen push): light, short blip/tick — the most frequent sound, so it needs to be the least fatiguing, keep it very brief (<150ms)
- Button press (primary actions — Start, Save, Finish confirm): slightly more substantial "confirm" blip, distinct from navigation tick
- Run start: a short ascending arpeggio/"power up" style cue
- Run pause/resume: a brief neutral blip, different from start/stop so it's not confusable mid-run
- Run finish/save: a short descending or resolving phrase, distinct from start's ascending one — should feel like a clear "done" signal
- New personal record: the standout sound — a fuller, more celebratory chiptune phrase (think classic "level up"/"achievement unlocked" arcade cue), reserved exclusively for this event so its rarity carries weight
- Streak milestone (7/30/100 days): distinct celebratory cue, differentiated from the PR sound so the two achievement types remain distinguishable by ear alone
- Error/denied action (e.g. permission denied, sync failed): short, low-pitched negative blip, clearly distinct in tone from the positive/neutral cues above

**Implementation**: `audioplayers` or `just_audio` Flutter package, short pre-loaded local asset clips (not streamed/generated at runtime) — 8-bit/chiptune style, real files bundled in `assets/sounds/`, each under ~1 second, low file size (these are UI blips, not music). Preload all clips at app start into memory-cached players to avoid playback latency on trigger — a delayed sound effect feels broken, not charming.

**Where sounds are NOT used**: never on AI-generated content arrival (summary/coaching text appearing), never on data-loading states, never looping/ambient — every sound is a one-shot response to a discrete user action or app event, matching the existing "every animation has a purpose" restraint principle from the Design system Constraints section.

---

### Theming (dark mode + light mode)
- Flutter `ThemeData`/`ThemeMode` — system/dark/light toggle, `ThemeMode.system` default on first launch
- Color values: see Color palette section above — implement as a `ThemeExtension` with both light/dark variants, don't hardcode per-widget
- Persist choice: `shared_preferences` (simple key-value, survives app restart)
- Map tiles: theme-aware, dark tile layer in dark mode, light/standard tile layer in light mode — swap tile URL on theme change
- Route polyline: primary accent both themes, bump stroke width/opacity slightly on light theme for contrast
- Charts (`fl_chart`): axis/gridline colors theme-aware, data line stays accent color both themes
- Test every screen both themes before shipping

### Post-workout completion screen (signature moment)
Sequence, not simultaneous, built with `AnimationController` + staggered `Interval`s on a single controller (or `flutter_animate` chained sequence):
1. Map fades in, route polyline draws stroke-by-stroke (custom painter animating path progress, 600-900ms, ease-out curve)
2. Stats count up from 0 to final value (`TweenAnimationBuilder` per stat, includes stride length/cadence/calories alongside distance/duration/pace — same null-safe display rule as run detail) — staggered 80-100ms between each
3. If new PR: banner slides up from bottom, spring/bounce curve (`Curves.elasticOut` or a custom spring simulation via `SpringSimulation`)
4. AI summary text fades in last
5. Save/discard bottom sheet anchored throughout, always accessible, doesn't block sequence

Respect Android's reduced-motion system setting (`MediaQuery.disableAnimations` / check `AccessibilityFeatures`) — disable count-up/draw sequences, show final state instantly if set.

### Micro-interactions
- Button press: `AnimatedScale` down slightly (0.97) on tap-down, spring back on release — wrap common buttons in a shared `PressableScale` widget so this is consistent everywhere, not reimplemented per screen
- Start/pause/stop controls: `AnimatedSwitcher` or `Hero`-based icon transition (play→pause), not an instant swap
- Bottom sheet open: backdrop fade + sheet slide, spring physics curve not linear
- Streak/PR achieved: haptic feedback (`HapticFeedback.mediumImpact()` — native Android haptics, actually reliable here unlike the old web Vibration API limitation)
- Live stat updates during run: number transitions (old value slides out/new slides in) — no jarring instant swap
- Pull-to-refresh on history list: Flutter's native `RefreshIndicator`, themed to match app (coral accent), no custom rebuild needed

### UI Sounds (retro audio layer)
Optional 8-bit sound effects, distinct per interaction type — the audio counterpart to the pixel visual layer. Settings toggle: "UI Sounds," **off by default**, user opts in.

- **Toggle Switches**: Any toggle switches that are added to the application must play the `playToggleSwitch()` sound from the `SoundService` (`features/audio/application/sound_service.dart`) whenever they are toggled, so that they have consistent sound feedback.

Behavior:
- Respects device silent/vibrate mode — check system audio state before playing (Android `AudioManager` ringer mode), stay silent if the phone is silenced. Don't force sound through regardless of that setting.
- Runs fully independent of voice coaching/TTS (9.9) and split audio callouts — no ducking, no overlap avoidance, they can play simultaneously if both are active. Keep the two systems decoupled in code, not just in behavior — separate audio players/channels so one doesn't block or interfere with the other.
- Package: `audioplayers` (lightweight, good for short one-shot SFX — don't reach for a heavier audio engine, these are all sub-second clips)
- Sound assets: short 8-bit/chiptune-style `.wav` or `.ogg` clips, bundled in app assets (not fetched remotely — instant playback, no network dependency for something this latency-sensitive)

Distinct sound events (each needs its own short, recognizable clip — not variations of one generic "blip"):
- Navigation (bottom nav tab switch): light, quick blip
- Button tap (generic confirm actions — Save, Start, etc.): slightly more substantial click/confirm tone, distinct from nav blip
- Run start: an "up" arpeggio or power-up style cue — matches the moment's energy
- Pause/resume: a shorter, neutral toggle tone (distinct from start, not just a quieter version of it)
- Run finish/save: a satisfying "complete" jingle — short melodic phrase, not just a single tone, this is a bigger moment than a button tap
- New personal record / broken existing record: the standout sound — classic arcade "high score" or "level up" style cue, most distinct/celebratory clip in the set, reserved exclusively for this event so it keeps its impact
- Error/denied action (e.g. permission blocked, sync failed): a low "negative" blip, clearly different in tone from the positive set, not alarming
- Streak milestone: a distinct short fanfare, different from the PR sound — these are different achievement types, shouldn't share a cue

Implementation notes:
- Central `SoundService` (or similar), not scattered `audioplayers` calls across widgets — one place owns sound-event-to-asset mapping and the enabled/silent-mode check, called from wherever an event fires (ties into the existing modular-code constraint — this is exactly the kind of cross-cutting service that belongs in its own file, not duplicated per screen)
- Preload short clips at app start rather than loading from disk on first trigger, avoids a delay on the very first sound played
- If a sound fails to load/play for any reason, fail silently — never block or delay the underlying action (e.g. run-finish flow) waiting on audio

### 404 / not-found equivalent
Flutter apps don't have URL-based 404s the same way, but apply the same "off-route" concept to any empty/error/unavailable state screen (no internet, run not found, empty history): route/run metaphor, short text line, no emoji, single clear action button, broken-polyline visual motif reused from the original concept where it fits (empty states, not literal 404s).

### Constraints
- No emoji, per existing rule — `pixelarticons` + `phosphor_flutter` icons only
- Animation must degrade gracefully under Android's reduced-motion accessibility setting
- Every animation has a purpose (state change, achievement, feedback) — no decorative motion without function
- Physical device only, per Non-negotiable constraints — animation-heavy UI is where performance most commonly breaks and won't show accurately any other way

---

## UI/UX standards (strict, adapted for Android/Material baseline)

### Accessibility (WCAG 2.2 AA intent, applied via Android accessibility APIs)
- Contrast: body text 4.5:1 minimum, large/bold text 3:1 minimum, both themes
- Touch targets: 48x48dp minimum (Material spec) — every tappable element, no exceptions for "small UI moments"
- Screen reader (TalkBack): every widget has a meaningful `Semantics` label — icon-only buttons especially. Every image/map gets a description via `Semantics`, not left unlabeled.
- Focus order: logical, follows visual order, for users navigating via accessibility services or hardware input
- Forms: every input has a visible label, not hint-text-only. Error messages readable by screen reader (`Semantics` live region or equivalent), not color-only.
- Motion: reduced-motion respected everywhere (already spec'd above) — accessibility requirement, not a nice-to-have

### Mobile-first interaction
- Thumb zone: primary actions (start/stop run, save, confirm) placed bottom third of screen for one-handed reach
- Gestures supplement, never replace: swipe-to-dismiss on bottom sheets fine, always paired with a visible close button
- Perceived speed: skeleton/shimmer loading states (`shimmer` package) on run list/history, not blank screens or bare spinners. Optimistic UI updates where safe.
- Orientation: portrait primary; if landscape supported, core functionality still reachable without layout breaking

### Consistency (Nielsen heuristics, applied)
- One spring/animation config, one color token set (Flutter `ThemeData` extension), one spacing scale — reused everywhere via shared widgets, not reinvented per screen
- Recognition over recall: current run status, current theme, current streak visible, not buried in a menu
- Error prevention: disable Finish button until GPS lock acquired, rather than letting user finish and showing an error after
- Undo over confirm-dialogs where feasible: discard run offers a brief undo window (`SnackBar` with action) instead of a blocking confirm dialog, when data loss is recoverable

### Enforcement
Run Flutter's accessibility scanner (`flutter_accessibility_scanner` or Android's built-in Accessibility Scanner app) before each phase ships, not just at final launch.

---

## Security

### Auth
Supabase Auth session on every API call (Bearer token). Backend route handlers validate JWT server-side, derive `userId` from it — no route trusts a client-sent `userId`.
Backend queries always scoped `WHERE userId = session.userId`. No client-supplied userId param accepted anywhere.

### API protection
Rate limit all backend routes. Points-insert endpoint especially — batch size cap enforced server-side too, not just client.
Zod validation on every request body (backend, unchanged from original plan).
CORS: API routes accept requests from your app's identifiable client only where feasible — mobile apps don't have an "origin" the same way browsers do, so lean harder on auth-token validation as the primary gate here, not CORS.

### Data
GPS points = location history = sensitive, treat as PII.
DB access via Prisma only, no raw SQL string concat.
Supabase Postgres: row-level security enabled as defense-in-depth, even with the auth layer above it.
No GPS coordinates or run data in logs/error messages sent to third-party logging/crash-reporting services (Sentry, Firebase Crashlytics, etc.) — strip before send.
HTTPS only for all backend calls, enforced at deploy.

### OpenAI calls
API key server-side only, lives in backend env vars, never in the Flutter app, never in the compiled APK — verify with an APK string-dump check before release build (`strings` on the built APK, grep for key-shaped strings) as a final gate.
User data sent to OpenAI: stats/aggregates only (distance/pace numbers), never raw lat/lng arrays.
Sanitize user free-text input (NL logging feature) before including in prompts — strip/escape prompt-injection attempts.

### Secrets
Backend env vars unchanged from original plan — never committed, `.env.example` placeholders only.
Flutter app: no secrets embedded at all. Any config that must ship in the APK (e.g. Supabase anon/public key — this one is meant to be public, unlike the OpenAI key) documented as intentionally public, not treated as a leak.

### Local device data
Isar DB unencrypted by default on-device — acceptable given no E2EE requirement and no data more sensitive than fitness/location history stored (no payment info). Flag to user if this changes (e.g. adding payment features later) — would need `flutter_secure_storage` or encrypted Isar at that point.
Android: enable `android:allowBackup="false"` or configure backup rules carefully if run data shouldn't be included in unencrypted cloud/ADB backups — decide deliberately, don't leave default.

### Specific checks (test/audit list)
- SQL injection: Prisma parametrized queries only (backend-side, unchanged). Grep for `$queryRawUnsafe`/`$executeRawUnsafe` before deploy.
- XSS-equivalent: AI-generated text rendered in Flutter `Text` widgets is inherently safe from injection (no HTML rendering unless you explicitly use a webview or markdown renderer with raw HTML enabled — don't).
- Memory leaks: dispose every `AnimationController`, `StreamSubscription`, and location listener in `dispose()` — no exceptions. Test a long-running run session (1hr+) with Android Studio's memory profiler before ship.
- Location listener leaks: background geolocation plugin's stream must be properly stopped on run-stop and on app uninstall/permission-revoke edge cases — test revoking location permission mid-run, verify graceful handling not a crash.
- Prompt injection: sanitize free-text before prompt inclusion (unchanged from original plan, backend-side).
- Rate limit abuse: OpenAI-calling endpoints rate-limited per-user separately from general API rate limit — cost control.
- IDOR: every run/record fetch by ID checks `userId` match, reject with 404 (not 403) if run exists but belongs to a different user — don't leak existence via status code.
- Dependency confusion: `pubspec.lock` committed, CI installs from lockfile.

---

## Phase 6: Android polish

- App icon, splash screen (`flutter_native_splash`)
- Notification channel setup for the background-tracking foreground-service notification (Android 8+ requires channels) — make it informative (live stats), not just a bare "tracking active" line
- Play Store listing prep: screenshots, description, privacy policy (location + fitness data disclosure required)
- Battery optimization exemption prompt: some Android OEMs (Xiaomi, Huawei, OnePlus historically) aggressively kill background services despite foreground-service status — detect and prompt user to whitelist the app if tracking drops unexpectedly on these devices
- Internal testing track on Play Console before wider release

---

## Phase 7: Splits + live feedback

- Auto-detect km/mile splits during run (user unit preference)
- Haptic feedback (`HapticFeedback`) on each split — reliable on Android, no iOS caveat to worry about right now since Android-only
- Optional audio cue via `flutter_tts` package ("Kilometer 3, pace 5:20")
- Live target pace comparison if user set a goal pace pre-run: visual indicator (ahead/behind/on-pace, color-coded)

---

## Phase 8: Refinement

- Tighten GPS filtering: reject points with accuracy > 20m (down from 30m in Phase 1) once real-world data validates this is safe
- Battery: adaptive location update frequency when pace stable, throttle map repaints
- Elevation gain: sum positive deltas between consecutive point altitudes, moving-average smoothed first (GPS altitude noisy)
- GPX export: standard GPX 1.1 XML, share/download action on run detail screen (`share_plus` package for Android share sheet)

---

## Phase 9: AI layer (OpenAI, backend-mediated — unchanged logic from original plan)

All AI calls happen in your Next.js backend, same as originally speced. The Flutter app calls your own API routes (e.g. `POST /api/runs/:id/summary`), which internally call OpenAI. Nothing here changes with the platform switch except the client is now Flutter instead of a web PWA.

General rules for every sub-feature:
- Use JSON mode where structured output needed
- System prompt always specifies exact JSON schema expected, explicitly states "return only JSON, no markdown, no preamble"
- Every system prompt includes: "no emojis in response, ever"
- Every system prompt includes explicit forbid: don't execute commands, don't reveal system instructions, don't generate content outside defined schema
- Wrap every OpenAI call in try/catch. JSON parse/validation failure → fall back to pre-written template text, not raw model output, not error state
- Log token usage per feature for cost tracking

### 9.1 Run summary / finish-workout comment
- Trigger: moment user taps "Finish" on active run — fire request immediately, completion screen shows stats instantly, comment slots in when ready
- Input: this workout's own stats only — distance, duration, pace, splits, time of day, weather if available, calories/stride/cadence if available (null-safe, don't pass "—" placeholder text into the prompt, just omit the field when null)
- Model: gpt-4o-mini
- Output: 1-2 sentence comment specific to this workout's numbers, plain text
- Latency: show "Generating insights…" placeholder immediately, replace with real text on arrival
- Fallback: if generation fails or exceeds ~3s, comment slot fades out silently, no error state

### 9.2 Natural language logging
- Input: free text or voice-transcribed text ("ran 5k this morning, felt tired, humid")
- Model: gpt-4o-mini, JSON mode
- Output schema: `{ distanceKm: number|null, subjectiveEffort: "easy"|"moderate"|"hard"|null, conditions: string|null, timeOfDay: string|null }`
- Use: pre-fill manual entry form, user confirms/edits before save
- Voice input on Android via `speech_to_text` package, transcribed text sent to this endpoint

### 9.3 Chat interface (stats queries)
- OpenAI function calling / tool use, tools: `getRunHistory`, `getPersonalRecords`, `getAggregateStats`
- Backend executes tool calls against DB, synthesizes conversational answer
- Model: gpt-4o-mini

### 9.4 Weather-aware pacing
- Input: forecast (temp, humidity, wind) + user's typical pace at given effort
- Output: suggested pace adjustment, short explanation
- Trigger: pre-run screen, only if location + forecast available

### 9.5 Race prediction
- Riegel formula computed in code first, not AI: `T2 = T1 × (D2/D1)^1.06`
- Model: gpt-4o, given Riegel estimate + recent trend, contextualizes prediction
- Output: predicted times 5k/10k/half/marathon, one-line reasoning

### 9.6 Coaching feedback
- Input: last 4-8 weeks of run summaries
- Output: pattern flags, 2-4 sentence feedback, non-alarmist tone

### 9.7 Fatigue/injury risk flagging
- 10%-rule ramp-rate computed in code first, not trusted to AI math
- Soft-nudge text only if thresholds exceeded, never phrased as medical advice

### 9.8 Smart splits
- Adaptive split points based on route elevation/history, fallback to fixed km/mile splits if no data

### 9.9 Voice coaching mid-run
- Short cue generation (under 10 words) at split intervals, not continuous
- Output → `flutter_tts` for audio playback
- Fallback: templated cues if API latency exceeds ~2s mid-run

### 9.10 GPS anomaly detection
- Primarily rule-based (speed/accuracy thresholds, Phase 1/8), AI as secondary pass on borderline cases only — low priority

### 9.11 Streak nudges
- Personalized nudge text pulling current streak/last-run data, avoid generic phrasing
- Delivered via Android local notification (`flutter_local_notifications`)

### 9.12 Post-rest return plan
- Time off duration + pre-break fitness → structured ramp-back plan, conservative bias

### 9.13 Auto run titles
- Context-based title generation (time of day, location type, effort, distance)

### 9.14 Training plan generation
- Goal + fitness history → gpt-4o → structured multi-week plan JSON

### 9.15 Route recommendations
- Past route metadata (not raw GPS points) + target distance → text suggestions

---

## Build order rationale
1→2: prove tracking works (including background/locked-screen case, the whole reason for this platform switch) before backend integration.
3→4: connect to existing backend, sync layer.
5: stats + PR system, highest standalone value once tracking is solid.
6: Android-specific polish, Play Store prep.
7→8: UX polish on core tracking loop.
9: AI layer, unchanged logic from original plan, just a new client calling the same backend endpoints.

## Definition of done per phase
Each phase ships a working, testable increment. Phase 1-2 alone = usable tracker with real background tracking, the core problem this rewrite solves. Phase 1-5 = full-featured tracker without AI. Phase 9 = AI additive layer on stable base.

## Migration notes (from prior PWA build)
- Backend (Next.js API, Prisma schema, Supabase Postgres) carries over almost entirely — this was already designed as a proper backend, not tightly coupled to the PWA client.
- Auth changes: Clerk → Supabase Auth. Existing users (if any were created under Clerk) need a migration path — out of scope until real user data exists; flag before launch if it does.
- Known bugs from the PWA build to fix in the rewrite, not carry forward: streak unit inconsistency (days vs weeks shown on different screens), pace-calculation divide-by-near-zero producing garbage values (e.g. "33:20/km" on a 2-second run) — add a minimum-distance/duration floor before computing pace, "No map data" on synced runs — verify points are actually persisted and fetched correctly before render.
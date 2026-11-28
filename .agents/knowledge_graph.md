# Trailhead Project Knowledge Graph

> Refreshed 2026-11-28 after migrating You, Stats, History, and Run Tracking.

## Project identity

- **Repository:** Trailhead
- **Application:** Flutter/Dart app in `mobile/` (`trailhead_mobile`)
- **Primary entry point:** `mobile/lib/main.dart`
- **Persistence:** Local Isar database, initialized in `main.dart`; preferences use `shared_preferences`.
- **Current state management** uses app-scoped Cubits and feature-scoped Blocs. GetIt registrations live in the DI modules.
- **Backend status:** No first-party backend/API server or Vercel deployment configuration was found in the repository. The root README and `agent_detail.md` contain stale Next.js/Vercel backend assumptions and must not be treated as current architecture.

## System graph

```mermaid
graph TD
  App[Flutter app: mobile/lib/main.dart] --> Nav[Navigation / main scaffold]
  Nav --> Home[Home]
  Nav --> Track[Run tracking]
  Nav --> History[History and activity sharing]
  Nav --> You[Profile / progress / records]
  Track --> Isar[(Local Isar database)]
  History --> Isar
  Stats[Stats / weekly reports / PRs] --> Isar
  Goals[Goals] --> Isar
  Shoes[Shoes] --> Isar
  Preferences[(SharedPreferences)] --> Theme[Theme and onboarding]
  Preferences --> AIConfig[AI provider/model/key]
  Home --> Weather[Weather feature]
  Track --> Weather
  AI[AI client] --> OpenAI[OpenAI API]
  AI --> Gemini[Google Gemini API]
  AI --> Anthropic[Anthropic API]
  Weather --> OpenMeteo[Open-Meteo API]
  Weather --> Geo[BigDataCloud reverse geocoding]
  Track --> OSM[OpenStreetMap tiles]
  History --> OSM
  History --> Esri[Esri imagery / terrain tiles]
```

## Feature map

Workout, report and dashboard cards use `AdaptiveColumns` where content needs to wrap. `InsetSheetBody` provides keyboard-aware scrolling, `ShoePhoto` handles local and remote gear photos, and `AppBarBackdrop` supplies the standard blur. The Home cards, Run Tracking controls and Onboarding previews live in their feature presentation widget folders.

| Feature | Main code | Responsibility / connections |
|---|---|---|
| AI | `mobile/lib/features/ai/` | Shared configuration Cubit, Settings panel and connection Bloc, and typed AI repository. A shared service handles OpenAI, Gemini, and Anthropic requests in native worker isolates. Chat and Predictions reuse it, and older AI callers use the compatibility client. |
| Audio and haptics | `features/audio/`, `features/haptics/` | Each has a global Cubit, a domain feedback use case, and a Flutter platform adapter. Audio groups cues into navigation, action, and alert channels. The navigation sound observer uses the same Audio Cubit as the screens. |
| Chat | `features/chat/` | The route owns a conversation Bloc. The domain builds context from recent activities and handles reply fallback. The repository reads Isar and delegates typed requests to the AI service, which streams replies from a worker isolate on native platforms. |
| Data management | `features/data_management/` | Settings hosts a local Bloc for JSON backup, restore, and bulk GPX export. A repository wraps Isar and file services. JSON encoding and decoding run in a native worker isolate. History and bulk GPX export share the Downloads directory resolver. |
| Goals | `features/goals/` | Goal targets use a shared Cubit. The editor and Home progress use feature Blocs, with Isar repositories for targets, completed runs and daily steps. |
| History | `features/history/` | Shared activity stream, scoped route and activity actions, manual entry, and flyover playback. GPX export uses a data service. |
| Home | `features/home/` | HomeBloc loads the weekly summary, coach card and cached trend. Weekly distance and streak rules live in the Home domain. Weather and Goals have their own dashboard Blocs. |
| Navigation | `features/navigation/`, `shared/navigation/app_navigator.dart` | Main app scaffold plus the shared route push, replacement, pop-until, and page-route builder used by feature screens. |
| Notifications | `features/notifications/` | App startup initializes a DI-managed local notification repository. Its platform service schedules streak nudges using a typed request. Scheduling is available through the repository and has no current caller. |
| Onboarding | `features/onboarding/` | Tour-scoped `OnboardingBloc` coordinates permission requests and finish actions. Shared `OnboardingCubit` persists completion through `OnboardingCompletionRepository`. |
| Predictions | `features/predictions/` | Race estimates and optional AI coach advice. The domain selects a valid baseline and calculates Riegel times. The data adapter reads Isar and uses the existing AI client in a native worker isolate. |
| Profile | `features/profile/` | Settings screen renders a feature-scoped ProfileBloc. The profile domain validates edits, and the preferences repository preserves the existing workout and profile keys. |
| Run tracking | `features/run_tracking/` | GPS/background tracking, steps, route, run calculations, Isar models, map widgets, post-run UI. Central cross-feature data source. |
| Shoes | `features/shoes/` | A shared ShoesCubit watches Isar inventory for gear management, Run Tracking and History. Local Blocs handle gear edits, photos and activity summaries. |
| Stats | `features/stats/` | ISO-week aggregation and a weekly reports Bloc. Personal records use an Isar repository and a shared records Cubit. |
| Weather | `features/weather/` | Home-scoped `WeatherBloc` loads a typed forecast for the badge, details sheet and pacing card. Domain `WeatherPacing` calculates the recommendation. Run tracking uses the same repository contract. |
| You | `features/you/` | Local selection and bulk delete, live period-specific activity and step data, progress calendar, and benchmark editor. |
| Shared | `shared/` | Theme, reusable widgets, global Cubits under `shared/state_management/global/`, and generic local state helpers under `shared/state_management/local/`. |

## External APIs and services

These integrations are called by the Flutter client; no Vercel proxy/API layer is present in the inspected source.

| Service | Endpoint / resource | Caller | Notes |
|---|---|---|---|
| OpenAI | `https://api.openai.com/v1/chat/completions` | `features/ai/application/ai_client.dart` | Chat and streaming requests; bearer key comes from local AI configuration. |
| Google Gemini | `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent` and `:streamGenerateContent` | `features/ai/application/ai_client.dart` | API key is passed as query parameter. |
| Anthropic | `https://api.anthropic.com/v1/messages` | `features/ai/application/ai_client.dart` | Chat and streaming requests. |
| Open-Meteo | `https://api.open-meteo.com/v1/forecast` | `features/weather/data/weather_service_current_conditions.dart` | Current weather fetched using device coordinates. |
| BigDataCloud | `https://api.bigdatacloud.net/data/reverse-geocode-client` | `features/weather/data/weather_service_current_conditions.dart` | Best-effort city/locality lookup; weather response remains usable if this lookup fails. |
| OpenStreetMap | `https://tile.openstreetmap.org/{z}/{x}/{y}.png` | Run tracking and history map widgets | Map tile resource, not a first-party backend API. |
| Esri | ArcGIS World Imagery and World Topo Map tile URLs | `features/history/presentation/widgets/flyover_3d_map_view.dart` | Satellite and terrain imagery options. |

Image fields also accept HTTP(S) URLs in screens, but the repository does not establish a first-party image-hosting service. No first-party auth, account API, cloud database, or run-sync endpoint was found in the app source scan.

## Local data and state relationships

- `main.dart` opens Isar schemas for runs, run points, shoes, daily steps, personal records, weekly reports, and goals.
- Run tracking writes/reads run data through Isar-backed models; history and stats consume these records.
- Weather is requested from Home and when tracking starts and can be stored on run records.
- AI credentials/provider/model are read and written through the global `AiConfigCubit` and persisted in `SharedPreferences`.
- Theme, onboarding, navigation, distance unit, and AI configuration have global Cubits under `shared/state_management/global/`.
- `RunTrackerCubit` manages live tracking and is registered in the feature DI module. Goals state uses `GoalsCubit`.
- `AsyncResourceBloc<T>` provides a generic Future/Stream loading pattern for feature-local state, but current feature screens have not yet adopted it broadly.
- Feature-local state management belongs in each feature's `state_management/` directory. Keep dependency lookup in `core/di/` and business workflows in domain use cases; UI screens should only dispatch actions and render state.
- App bootstrap provides the shared Cubits and typed Bloc factories. Riverpod has been removed from source and dependencies.
- Dependency registration is split into `core/di/core_module.dart`, `shared_module.dart`, and `feature_module.dart`, orchestrated by `dependency_injection.dart`.

### State-management migration status

| Scope | Current implementation | Notes |
|---|---|---|
| Global theme | `shared/state_management/global/theme_mode_cubit.dart` | Registered from `SharedModule`; initialized from saved preferences. |
| Global onboarding | `shared/state_management/global/onboarding_cubit.dart` | Registered from `SharedModule`; completion persists to preferences. |
| Global navigation | `shared/state_management/global/navigation_cubit_main_tab.dart` | Holds the selected `MainTab`. The scaffold listens for tab changes, preserves the tab stack, and delegates the double-back exit rule to its domain policy. |
| Global distance unit | `shared/state_management/global/distance_unit_cubit.dart` | Registered as a shared Cubit. |
| Global haptics | `shared/state_management/global/haptics_cubit_feedback.dart` | One persisted setting controls UI feedback and run split feedback. |
| Global UI sounds | `shared/state_management/global/audio_cubit_ui_sounds.dart` | One persisted setting controls UI cues, including navigation. The setting is refreshed after a backup restore. |
| Global AI config | `shared/state_management/global/ai_config_cubit.dart` | Used by settings and AI services; persists provider/model/key. |
| Run tracking | `shared/state_management/global/run_tracking_cubit_live_session.dart` | RunTrackerCubit orchestrates device services. LiveSessionRepository owns transactional writes, and domain use cases calculate live session metrics. |
| Profile settings | `features/profile/state_management/profile_bloc_settings.dart` | Settings-scoped Bloc dispatches validated profile and workout edits. |
| Home dashboard | `features/home/state_management/home_bloc_dashboard.dart` | Loads the live weekly summary and independently loads coach and trend data. |
| Shoes inventory | `shared/state_management/global/shoes_cubit_inventory.dart` | Isar changes update gear, run selection and history. Gear edits and activity are feature-scoped. |
| Goals | `shared/state_management/global/goals_cubit_targets.dart` | Shared targets reload after backup restore. Home progress watches completed runs and step changes using `GoalProgressBloc`. |
| Feature-local async state | `shared/state_management/local/async_resource_bloc.dart` | Generic Future/Stream BLoC is used by the home coach/trend cards and the post-run summary. |
| Race predictions | `features/predictions/state_management/predictions_bloc_race_predictions.dart` | The route owns its Bloc. Feature DI registers the repository implementation, coach advice service, use case, and Bloc factory. The coach service uses separate request and response models. The screen renders typed results and navigates through AppNavigator. |
| History manual entry | `features/history/state_management/manual_entry_bloc.dart` | Coordinates parsing and saving. `ParseManualRunLog` and `SaveManualRun` use cases own the workflows; domain repository contracts live in `features/history/domain/`, with the Isar adapter registered centrally in `core/di/feature_module.dart`. |

Run Tracking uses a shared route-map Cubit and scoped workout actions, permissions, and post-run summary Blocs. History detail and flyover each own their Bloc lifecycle. You reads the shared run and record snapshots and owns its local selection.

### Latest migration error cleanup (2026-11-24)

- `RunTrackerCubit.fetchInitialLocation` now checks `isClosed` before emitting after asynchronous location requests; Cubits do not expose a widget `mounted` property.
- Run tracking presentation types now refer to `RunTrackerCubit`, matching the app-wide registration and provider.
- History manual entry is route-scoped. DI wires its parser and save use cases.
- Generic `AsyncResourceBloc<T>` creates its loading state without `const`, because a const construction cannot use `T` as a type argument.
- VS Code Dart diagnostics refreshed to **0 errors**, 79 warnings, and 112 informational notices after these fixes. This is IDE analyzer status; a full CLI `flutter analyze` did not complete during this session.

## Rules for future Flutter work (user-provided)

1. Every new feature uses Clean Architecture and BLoC state management.
2. Keep business logic in the domain layer. Presentation contains state management and clean UI only.
3. Break code into small methods with simple, understandable names.
4. Name feature files using `feature_name_{layer_role}_{use_case_name}`. Each feature API uses a domain repository contract and separate data files for the implementation, service, request model, and response model.
5. Use global/shared state when multiple features need the same common object.
6. Put reusable components in new files. Generic components may be grouped together in a shared generic file.
7. Preserve local conventions and use the feature DI module to register new dependencies.

## Architecture notes and migration caveats

- Run tracking device integrations still use Flutter platform services for foreground execution, GPS, speech, and step counting.
- The manifest uses flutter_bloc for state management and GetIt for DI. The app provides shared Cubits and typed factories at startup.
- Vercel removal means there is no currently discovered server-side secret boundary. AI provider keys are stored in `SharedPreferences` and requests are sent directly from the app. Confirm this is an intentional product/security decision before changing AI integration architecture; this graph records behavior, not an endorsement.
- Existing `agent_detail.md` describes planned Next.js routes, Prisma/Supabase, custom auth, Vercel deployment, and requirements that do not match current source. Prefer this file and verified source for current project facts; retain `agent_detail.md` only as historical/planning material until it is reconciled.

## Useful entry points

- Startup and Isar registration: `mobile/lib/main.dart`
- Dependencies/platform stack: `mobile/pubspec.yaml`
- AI endpoints and request formats: `mobile/lib/features/ai/application/ai_client.dart`
- AI settings persistence: `mobile/lib/features/ai/data/ai_repository_implementation_configuration.dart`
- Weather and geocoding endpoints: `mobile/lib/features/weather/data/weather_service_current_conditions.dart`
- Run tracking controller: `mobile/lib/features/run_tracking/application/run_tracker_controller.dart`
- Existing repository-specific agent guidance: `.agents/AGENTS.md` (includes the sound-on-toggle UI rule)

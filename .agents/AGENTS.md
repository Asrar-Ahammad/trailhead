# Trailhead Agent Instructions

Use `.agents/knowledge_graph.md` as the current codebase map. Verify code before relying on this map, because implementation can change.

## Flutter feature rules

- Build every new feature with Clean Architecture and BLoC state management.
- Use Cubit for state shared across features and keep global Cubits under `mobile/lib/shared/state_management/global/`.
- Use feature-scoped Bloc for local event-driven state.
- Create a `state_management/` directory inside each feature for that feature's Cubit/Bloc and state classes; do not put feature-local state in the shared global directory.
- Register shared and feature dependencies through the modular `mobile/lib/core/di/` modules.
- Put business logic in the domain layer. Keep presentation focused on state management and clean UI.
- Screens and widgets must not resolve dependencies with GetIt or implement business workflows. Resolve dependencies in DI modules, pass use cases into feature state management, and let presentation dispatch actions and render state.
- Break code into small methods with simple, understandable names.
- Name feature files in snake case using `feature_name_{layer_role}_{use_case_name}`. For example, `predictions_service_coach_advice.dart`.
- For every feature API, define a repository contract in domain and a separate repository implementation, service, request model, and response model in data. Keep transport models out of domain and UI.
- Use shared/global state when multiple features need the same common object.
- Put reusable components in separate files. Generic components may share a generic file.
- Use feature-scoped Bloc providers and shared Cubits for their respective lifecycles.

## UI/UX rules

- Any toggle switch added to the application must play `AudioCubit.playToggleSwitch()` when toggled.

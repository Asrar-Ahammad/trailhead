# Trailhead Agent Instructions

Use `.agents/knowledge_graph.md` as the current codebase map. Verify code before relying on this map, because implementation can change.

## Flutter feature rules

- Build every new feature with Clean Architecture and BLoC state management.
- Put business logic in the domain layer. Keep presentation focused on state management and clean UI.
- Break code into small methods with simple, understandable names.
- Name new files using `feature_name_{directory_to_which_it_belongs}`.
- Use shared/global state when multiple features need the same common object.
- Put reusable components in separate files. Generic components may share a generic file.
- Existing features use Riverpod. Treat that as existing-code context; do not copy it into new feature architecture when it conflicts with the BLoC rule.

## UI/UX rules

- Any toggle switch added to the application must play `playToggleSwitch()` from `mobile/lib/features/audio/application/sound_service.dart` when toggled.

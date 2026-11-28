import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/profile_repository_settings.dart';
import '../domain/profile_use_case_update_settings.dart';

typedef CreateProfileBloc = ProfileBloc Function();
typedef ProfileState = ({
  ProfileSettings settings,
  ProfileSetting? updated,
  String? message,
});

sealed class ProfileEvent {
  const ProfileEvent();
}

class ReloadProfile extends ProfileEvent {
  const ReloadProfile();
}

class EditProfileSetting extends ProfileEvent {
  const EditProfileSetting(this.setting, this.value);
  final ProfileSetting setting;
  final Object? value;
}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(
    ProfileSettingsRepository repository,
    UpdateProfileSettings update,
  ) : super((settings: repository.read(), updated: null, message: null)) {
    on<ProfileEvent>((event, emit) async {
      ProfileSetting? updated;
      String? message;
      if (event is EditProfileSetting) {
        try {
          await update(event.setting, event.value);
          updated = event.setting;
        } on FormatException catch (error) {
          message = error.message;
        } catch (_) {
          message = 'Could not save profile settings.';
        }
      }
      // Clear the previous action so repeated errors and cues still reach the UI.
      emit((settings: repository.read(), updated: null, message: null));
      if (updated != null || message != null) {
        emit((settings: state.settings, updated: updated, message: message));
      }
    }, transformer: (events, mapper) => events.asyncExpand(mapper));
  }
}

enum ChatRole { system, user, assistant }

typedef ChatMessage = ({ChatRole role, String text});

typedef ChatActivity = ({
  String type,
  DateTime? startTime,
  double distanceMeters,
  int durationSeconds,
});

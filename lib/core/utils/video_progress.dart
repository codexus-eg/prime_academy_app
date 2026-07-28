abstract final class VideoProgress {
  static int resumePositionSeconds(int? lastPosition) {
    if (lastPosition == null || lastPosition <= 5) return 0;
    return lastPosition;
  }

  static int clampResumePosition(int positionSeconds, int durationSeconds) {
    if (durationSeconds <= 0) return positionSeconds;
    if (positionSeconds >= durationSeconds - 5) {
      return (durationSeconds - 5).clamp(0, durationSeconds);
    }
    return positionSeconds;
  }
}

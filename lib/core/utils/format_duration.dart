String formatDuration(int milliseconds) {
  final duration = Duration(milliseconds: milliseconds);

  String twoDigits(int n) => n.toString().padLeft(2, '0');

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    // h:mm:ss
    return "$hours:${twoDigits(minutes)}:${twoDigits(seconds)}";
  } else {
    // mm:ss
    return "${twoDigits(minutes)}:${twoDigits(seconds)}";
  }
}

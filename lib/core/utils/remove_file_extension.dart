String removeFileExtension(String fileName) {
  const validExtensions = ['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'];
  final dotIndex = fileName.lastIndexOf('.');
  if (dotIndex != -1) {
    final ext = fileName.substring(dotIndex + 1).toLowerCase();
    if (validExtensions.contains(ext)) {
      return fileName.substring(0, dotIndex);
    }
  }
  return fileName;
}

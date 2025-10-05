import 'package:path/path.dart' as p;

/// Converts an absolute path to a path relative to the given base path.
String getRelativePath(String absolutePath, String basePath) {
  if (p.isAbsolute(absolutePath)) {
    return p.relative(absolutePath, from: basePath);
  }
  return absolutePath;
}

/// Converts a relative path to an absolute path based on the given base path.
String getAbsolutePath(String relativePath, String basePath) {
  // Find the 'media' directory, which is the root for all app media
  final mediaIndex = relativePath.lastIndexOf('media');

  if (mediaIndex != -1) {
    // The relative path starts from the 'media' directory
    final correctRelativePath =
        relativePath.substring(mediaIndex);
    return p.join(basePath, correctRelativePath);
  } else {
    // Fallback for older versions or if 'media' is not in the path
    if (p.isRelative(relativePath)) {
      return p.join(basePath, relativePath);
    }
    return relativePath;
  }
}

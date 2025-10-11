import 'package:path/path.dart' as p;

/// Converts an absolute path to a path relative to the given base path.
String getRelativePath(String absolutePath, String basePath) {
  if (p.isAbsolute(absolutePath)) {
    return p.relative(absolutePath, from: basePath);
  }
  return absolutePath;
}

/// Converts a relative path to an absolute path based on the given base path.
String getAbsolutePath(String path, String basePath) {
  if (p.isAbsolute(path)) {
    return path;
  }
  return p.join(basePath, path);
}

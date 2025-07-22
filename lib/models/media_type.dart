/// Defines the types of media that can be associated with a music piece.
///
/// This enum helps categorize and handle different media formats,
/// such as documents, images, audio, and external links.
enum MediaType {
  /// Represents markdown formatted text.
  markdown,
  /// Represents a PDF document.
  pdf,
  /// Represents an image file.
  image,
  /// Represents an audio file.
  audio,
  /// Represents an external link (e.g., YouTube video, external audio stream, website).
  mediaLink,
  /// Represents a thumbnail image (for hierarchical storage of thumbnails)
  thumbnails,
  // Add other types as needed, e.g., 'text' for plain text notes
}

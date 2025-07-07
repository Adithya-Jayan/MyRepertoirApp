# Repertoire: Music Practice & Sheet Music Organizer

Repertoire is a cross-platform application designed for musicians to manage their musical pieces, track practice sessions, and organize all related media in one place. Built with Flutter, it offers a seamless experience on mobile, web, and desktop platforms.

The app helps you keep your sheet music, notes, audio recordings, and practice logs neatly organized for every piece in your collection. With optional Google Drive integration, you can back up your data and access it from anywhere.

## Screenshots

<p align="center">
  <img src="https://github.com/Adithya-Jayan/MyRepertoirApp/blob/screenshots/assets/images/6294161292981814199.jpg?raw=true" width="200"/>
  <img src="https://github.com/Adithya-Jayan/MyRepertoirApp/blob/screenshots/assets/images/6294161292981814200.jpg?raw=true" width="200"/>
  <img src="https://github.com/Adithya-Jayan/MyRepertoirApp/blob/screenshots/assets/images/6294161292981814201.jpg?raw=true" width="200"/>
  <img src="https://github.com/Adithya-Jayan/MyRepertoirApp/blob/screenshots/assets/images/6294161292981814202.jpg?raw=true" width="200"/>
  <img src="https://github.com/Adithya-Jayan/MyRepertoirApp/blob/screenshots/assets/images/6294161292981814203.jpg?raw=true" width="200"/>
  <img src="https://github.com/Adithya-Jayan/MyRepertoirApp/blob/screenshots/assets/images/6294161292981814205.jpg?raw=true" width="200"/>
  <img src="https://github.com/Adithya-Jayan/MyRepertoirApp/blob/screenshots/assets/images/6294161292981814206.jpg?raw=true" width="200"/>
</p>

## Features

- **Repertoire Library**: View your entire collection of music pieces in a clean, organized list or grid format.
- **Detailed Piece View**: Each piece has a dedicated page showing:
    - Title, composer, genre, and instrumentation.
    - User-assigned tags for easy filtering.
- **Flexible Media Attachments**: Add multiple media types to each piece:
    - **PDFs**: For sheet music (viewable directly in the app).
    - **Markdown Notes**: For text-based annotations, lyrics, or practice notes.
    - **Images**: For reference photos or alternative scores.
    - **Audio Files**: For backing tracks or recordings.
    - **Video Links**: To link to YouTube or other external video resources.
- **Practice Tracking**:
    - Log practice sessions for each piece.
    - Track the date of your last practice and the total number of sessions.
    - Toggle practice tracking on or off for individual pieces.
- **Powerful Search & Filtering**:
    - Full-text search through titles, composers, and tags.
    - Filter your repertoire by genre, instrumentation, difficulty, and custom tags.
    - Filter by practice history (e.g., "practiced in the last week" or "never practiced").
- **Data Persistence**:
    - All data is stored locally in a robust SQLite database.
    - **Manual Backup & Restore**: Manually export your entire library to a single JSON file for backup. You can specify the backup location and restore from a previously saved file.
- **Material You Design**: A modern, adaptive UI that uses Material 3 design principles.

## Technologies & Key Packages

This project is built with Flutter and leverages a number of high-quality packages from the ecosystem:

- **State Management**: `provider`
- **Database**: `sqflite` for local persistence.
- **File & Path**: `file_picker` and `path_provider` for local file handling.
- **Media Viewers**:
    - `syncfusion_flutter_pdfviewer` for in-app PDF viewing.
    - `flutter_markdown` for rendering notes.
    - `photo_view` for zoomable images.
- **Media Playback**:
    - `just_audio` for background audio playback.
    - `video_player` for local video files.
- **Networking**: `http` for network requests and `url_launcher` to open external links.
- **UI**: `flutter_speed_dial` for enhanced floating action buttons and `intl` for date/time formatting.

## Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

Ensure you have the Flutter SDK installed on your machine. For more information, see the [official Flutter installation guide](https://flutter.dev/docs/get-started/install).

### Installation

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/your_username/repertoire.git
    ```
2.  **Navigate to the project directory:**
    ```sh
    cd repertoire
    ```
3.  **Install dependencies:**
    ```sh
    flutter pub get
    ```
4.  **Run the app:**
    ```sh
    flutter run
    ```

## Project Structure

The project's source code is organized within the `lib` directory, following a feature-first approach:

```
lib/
├── database/     # Database helper and schema
├── models/       # Core data models (MusicPiece, MediaItem, etc.)
├── screens/      # UI for each screen of the app
├── services/     # Business logic for services (e.g., Google Drive sync)
├── utils/        # Utility functions and constants
├── widgets/      # Reusable custom widgets
└── main.dart     # App entry point
```

## Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

1.  **Fork the Project**
2.  **Create your Feature Branch** (`git checkout -b feature/AmazingFeature`)
3.  **Commit your Changes** (`git commit -m 'Add some AmazingFeature'`)
4.  **Push to the Branch** (`git push origin feature/AmazingFeature`)
5.  **Open a Pull Request**

## License

Distributed under the MIT License. See `LICENSE` for more information.
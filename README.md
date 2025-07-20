<div align="center">
  
<a href="https://github.com/Adithya-Jayan/MyRepertoirApp">
  <img src="./web/icons/Icon.png" alt="Repertoir logo" title="Repertoir logo" width="80"/>
</a>

# Repertoire: Music Practice & Sheet Music Organizer

Repertoire is a cross-platform application designed for musicians, dancers, Magicians or performers to help manage their repertoir (Musical pieces/dance routines or even Magic tricks), track practice sessions, and organize all related media in one place. Built with Flutter, it offers a seamless experience on mobile, web, and desktop platforms.

The app helps you keep your sheet music, notes, audio recordings, videos, links and practice logs neatly organized for every piece in your collection.

**[Download Latest Release](https://github.com/Adithya-Jayan/MyRepertoirApp/releases/latest)**
</div>

## Screenshots 
(Slightly outdated)

<p align="center">
  <img src="https://github.com/Adithya-Jayan/MyRepertoirApp/blob/screenshots/assets/images/6294161292981814205.jpg?raw=true" width="110"/>
  <img src="https://github.com/Adithya-Jayan/MyRepertoirApp/blob/screenshots/assets/images/6294161292981814206.jpg?raw=true" width="110"/>
  <img src="https://github.com/Adithya-Jayan/MyRepertoirApp/blob/screenshots/assets/images/6294161292981814201.jpg?raw=true" width="110"/>
  <img src="https://github.com/Adithya-Jayan/MyRepertoirApp/blob/screenshots/assets/images/6294161292981814202.jpg?raw=true" width="110"/>
  <img src="https://github.com/Adithya-Jayan/MyRepertoirApp/blob/screenshots/assets/images/6294161292981814203.jpg?raw=true" width="110"/>
  <img src="https://github.com/Adithya-Jayan/MyRepertoirApp/blob/screenshots/assets/images/6294161292981814199.jpg?raw=true" width="110"/>
  <img src="https://github.com/Adithya-Jayan/MyRepertoirApp/blob/screenshots/assets/images/6294161292981814200.jpg?raw=true" width="110"/>
</p>

## Features

- **Repertoire Library**: View your entire collection of music pieces in a clean, organized list or grid format.
- **Detailed Piece View**: Each piece has a dedicated page showing:
    - Title and Artist/composer
    - User-assigned tags for easy filtering.
- **Flexible Media Attachments**: Add multiple media types to each piece:
    - **PDFs**: For sheet music (viewable directly in the app).
    - **Markdown Notes**: For text-based annotations, lyrics, or practice notes.
    - **Images**: For reference photos or alternative scores.
    - **Audio Files**: For backing tracks or recordings, with built-in support for speed control and pitch shifting.
    - **Video Links**: To link to YouTube or other external video resources.
- **Practice Tracking**:
    - Log practice sessions for each piece.
    - Track the date of your last practice and the total number of sessions.
    - Toggle practice tracking on or off for individual pieces.
- **Powerful Search & Filtering**:
    - Full-text search through titles, composers, and tags.
    - Filter your repertoire by genre, instrumentation, difficulty, and custom tags.
    - Filter by practice history (e.g., "practiced in the last week" or "never practiced").
- **Manual Backup & Restore**: Manually export your entire library to a single JSON file for backup. You can specify the backup location and restore from a previously saved file. The app also support automatic periodic backups.

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



## Credits
Thank you to all the people who have contributed!

<div align="center">
<a href="https://github.com/Adithya-Jayan/">
    <img src="https://contrib.rocks/image?repo=Adithya-Jayan/MyRepertoirApp" alt="MyRepertoir app contributors" title="MyRepertoir app contributors" width="100"/>
</a>
</div>


## License

Distributed under the Apache 2.0 licence. See [`NOTICE`](Notice) and [`LICENSE`](LICENSE) for more information.



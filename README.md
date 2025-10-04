<div align="center">
  
[//]: # (Badges go here)

<!-- Build Status Badge -->
[![Build Status](https://github.com/Adithya-Jayan/MyRepertoirApp/actions/workflows/release.yml/badge.svg)](https://github.com/Adithya-Jayan/MyRepertoirApp/actions/workflows/release.yml)
[![Nightly Status](https://github.com/Adithya-Jayan/MyRepertoirApp/actions/workflows/nightly.yml/badge.svg)](https://github.com/Adithya-Jayan/MyRepertoirApp/actions/workflows/nightly.yml)

<!-- License Badge -->
[![License](https://img.shields.io/github/license/Adithya-Jayan/MyRepertoirApp?style=flat-square)](./LICENSE)

<a href="https://github.com/Adithya-Jayan/MyRepertoirApp">
  <img src="./web/icons/Icon.png" alt="Repertoir logo" title="Repertoir logo" width="80"/>
</a>

# Repertoire: Music Practice & Sheet Music Organizer

Repertoire is a cross-platform application designed for musicians, dancers, magicians, or performers to help manage their repertoire (musical pieces, dance routines, or even magic tricks), track practice sessions, and organize all related media in one place. Built with Flutter, it offers a seamless experience on mobile, web, and desktop platforms.

The app helps you keep your sheet music, notes, audio recordings, videos, links, and practice logs neatly organized for every piece in your collection.

**[Download Latest Release](https://github.com/Adithya-Jayan/MyRepertoirApp/releases/latest)**

**[Download Nightly Build](https://github.com/Adithya-Jayan/MyRepertoirApp/releases/tag/nightly)**

</div>

## Quick Start

- **Just want to use the app on Android?** Follow our **[Step-by-Step Installation Guide](INSTALL.md)**.
- **Want to contribute or build from source?** See the [Contributing](#contributing) section below.

## Screenshots 

> **Note**: Screenshots are slightly outdated — *new screenshots are welcome as contributions!*

### Light and Dark Modes
<p align="center">
  TODO: Update image here.
</p>

### Gallery View
*Create a gallery of all your pieces*

<p align="center">
  <img src="https://github.com/user-attachments/assets/c66daedf-76cc-4c41-afc5-4f608674dd7a" width="300" alt="Piece gallery view"/>
  <img src="https://github.com/user-attachments/assets/d77d40c9-c185-474d-8ddd-de517cbfa72c" width="300" alt="Grid layout view"/>
</p>

### Media Attachments & Practice Tracking
*Attach all relevant media (links, audio recordings, notes), track practice sessions and tag them for searchability*

<p align="center">
  <img src="https://github.com/user-attachments/assets/59918de7-5e0c-40d9-a4db-73d10bfe440e" width="300" alt="Media attachments interface"/>
  <img src="https://github.com/user-attachments/assets/3b6eb20d-e677-416d-9fcb-111f14a0ed1b" width="300" alt="Practice tracking interface"/>
</p>

### Organization & Sorting
*Group your pieces and tag them as you wish! Sort your items by name or in order of longest since practice*

<p align="center">
  <img src="https://github.com/user-attachments/assets/ceb12e0f-9ce5-4197-82e9-db8563faa386" width="300" alt="Piece organization"/>
  <img src="https://github.com/user-attachments/assets/4aa90d2e-184e-4213-9ca8-d9018d3bedf7" width="300" alt="Sorting options"/>
  <img src="https://github.com/Adithya-Jayan/MyRepertoirApp/blob/screenshots/assets/images/6294161292981814203.jpg?raw=true" width="300" alt="Sorting"/>

</p>

### Customization & Backup
*Customizations for personalization and backup & restore files for safety. Backups are zip files. Choose to backup periodically or manually*

<p align="center">
  <img src="https://github.com/user-attachments/assets/e56f076a-71f0-4e17-9464-d5f899d1a055" width="300" alt="Customization settings"/>
  <img src="https://github.com/user-attachments/assets/e3aede9a-62e1-4e4f-bd33-4fca6dc623e9" width="300" alt="Backup and restore"/>
</p>

## Features

- **Repertoire Library**: View your entire collection of music pieces in a clean, organized list or grid format.
- **Detailed Piece View**: Each piece has a dedicated page showing:
    - Title and Artist/composer
    - User-assigned tags for easy filtering.
- **Flexible Media Attachments**: Add multiple media types to each piece:
    - **📄 PDFs**: For sheet music (viewable directly in the app).
    - **📝 Markdown Notes**: For text-based annotations, lyrics, or practice notes.
    - **🖼️ Images**: For reference photos or alternative scores.
    - **🎧 Audio Files**: For backing tracks or recordings, with built-in support for speed control and pitch shifting.
    - **🎬 Video Links**: To link to YouTube or other external video resources.
- **Practice Tracking**:
    - Log practice sessions for each piece.
    - Track the date of your last practice and the total number of sessions.
    - Toggle practice tracking on or off for individual pieces.
- **Powerful Search & Filtering**:
    - Full-text search through titles, composers, and tags.
    - Filter your repertoire by genre, instrumentation, difficulty, and custom tags.
    - Filter by practice history (e.g., "practiced in the last week" or "never practiced").
- **Manual Backup & Restore**: Manually export your entire library to a single JSON file for backup. You can specify the backup location and restore from a previously saved file. The app also supports automatic periodic backups.

## Project Structure

The project's source code is organized within the `lib` directory, following a feature-first approach:

```
lib/
├── database/     # Database helper and schema
├── models/       # Core data models (MusicPiece, MediaItem, etc.)
├── screens/      # UI for each screen of the app
├── services/     # Business logic for services
├── utils/        # Utility functions and constants
├── widgets/      # Reusable custom widgets
└── main.dart     # App entry point
```

## Tech Stack

- **Flutter** (Dart)
- **SQLite** (local storage)
- **just_audio**, **video_player** (media playback)
- **Provider** (state management)
- **Other major libraries**: `file_picker`, `share_plus`, `url_launcher`, etc.

## Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

1.  **Fork the Project**
2.  **Create your Feature Branch** (`git checkout -b feature/AmazingFeature`)
3.  **Commit your Changes** (`git commit -m 'Add some AmazingFeature'`)
4.  **Push to the Branch** (`git push origin feature/AmazingFeature`)
5.  **Open a Pull Request**

### Getting Started

To get a local copy up and running, follow these simple steps.

#### Prerequisites

Ensure you have the Flutter SDK installed on your machine. For more information, see the [official Flutter installation guide](https://flutter.dev/docs/get-started/install).

#### Installation

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

## FAQ

**Where is my data stored?**
- All your data is stored locally on your device in a private app directory. You can export backups at any time.

**How do I backup or restore my data?**
- Go to Settings > Backup & Restore. You can create manual backups or restore from a previous backup file. Automatic periodic backups are also supported.

**Is there a mobile app?**
- Yes! Repertoire runs on Android, iOS, web, Windows, macOS, and Linux (where supported by Flutter).

## Credits
Thank you to all the people who have contributed! (Please contribute to help improve the app 🥺)

<div align="center">
<a href="https://github.com/Adithya-Jayan/">
    <img src="https://contrib.rocks/image?repo=Adithya-Jayan/MyRepertoirApp" alt="MyRepertoir app contributors" title="MyRepertoir app contributors" width="100"/>
</a>
</div>

## License

Distributed under the Apache 2.0 licence. See [`NOTICE`](Notice) and [`LICENSE`](LICENSE) for more information.

## Support

- For help, bug reports, or feature requests, open an [issue](https://github.com/Adithya-Jayan/MyRepertoirApp/issues).



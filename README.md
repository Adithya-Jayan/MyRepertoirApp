<div align="center">

<a href="https://hacktoberfest.digitalocean.com/"><img src="https://img.shields.io/badge/Hacktoberfest-2025-2ea44f?style=flat-square" alt="Hacktoberfest 2025"/></a>

[![Build Status](https://github.com/Adithya-Jayan/MyRepertoirApp/actions/workflows/release.yml/badge.svg)](https://github.com/Adithya-Jayan/MyRepertoirApp/actions/workflows/release.yml)
[![Nightly Status](https://github.com/Adithya-Jayan/MyRepertoirApp/actions/workflows/nightly.yml/badge.svg)](https://github.com/Adithya-Jayan/MyRepertoirApp/actions/workflows/nightly.yml)

[![Github All Releases](https://img.shields.io/github/downloads/Adithya-Jayan/MyRepertoirApp/total.svg)]()
[![Github Lastest Releases](https://img.shields.io/github/downloads/Adithya-Jayan/MyRepertoirApp/latest/total.svg)]()


[![License](https://img.shields.io/github/license/Adithya-Jayan/MyRepertoirApp?style=flat-square)](./LICENSE)

<a href="https://github.com/Adithya-Jayan/MyRepertoirApp">
  <img src="./web/icons/Icon.png" alt="Repertoir logo" title="Repertoir logo" width="80"/>
</a>

# Repertoire: Music Practice & Sheet Music Organizer

**[Download Latest Release](https://github.com/Adithya-Jayan/MyRepertoirApp/releases/latest)** | **[Download Nightly Build](https://github.com/Adithya-Jayan/MyRepertoirApp/releases/tag/nightly)** | **[Download from F-Droid](https://f-droid.org/en/packages/io.github.adithya_jayan.myrepertoirapp.fdroid/)** | **[View the Webpage](https://adithyajayan.in/MyRepertoirApp/)**

Repertoire is an app designed for musicians, dancers, magicians, or performers to help manage their repertoire, track practice sessions, and organize all related media in one place.

Keep your sheet music, notes, audio recordings, videos, links, and practice logs neatly organized for every piece in your collection.

</div>

## Getting Started

### Installation

**Just want to use the app on Android?** Follow our **[Step-by-Step Installation Guide](INSTALL.md)**.

Currently available for Android. Support for other platforms is planned for the future.

### Quick Overview

Once installed, you can:
1. Add your music pieces, dance routines, or other performance pieces
2. Attach sheet music (PDFs), notes, audio files, videos, and images
3. Track your practice sessions
4. Search and filter your collection by tags, genre, or practice history
5. Backup your entire library

## Key Features

**Repertoire Library**
- View your collection in list or grid format
- Each piece shows title, artist/composer, and custom tags

**Media Attachments**
- PDFs for sheet music (viewable in-app)
- Markdown notes for annotations and lyrics
- Images for reference photos
- Audio files with speed control and pitch shifting
- Video links to YouTube or other resources

**Practice Tracking**
- Log practice sessions for each piece
- See when you last practiced
- Track total practice sessions
- Filter pieces by practice history

**Organization**
- Search through titles, composers, and tags
- Filter by genre, difficulty, and custom tags
- Sort by name or longest since practice
- Group and categorize your pieces

**Backup & Restore**
- Manual backup to a single file
- Automatic periodic backups
- Choose your backup location
- Restore from previous backups

## Screenshots

> Note: Screenshots are slightly outdated — new screenshots are welcome as contributions!

### Gallery View
Create a gallery of all your pieces

<p align="center">
  <img src="https://github.com/user-attachments/assets/c66daedf-76cc-4c41-afc5-4f608674dd7a" width="300" alt="Piece gallery view"/>
  <img src="https://github.com/user-attachments/assets/d77d40c9-c185-474d-8ddd-de517cbfa72c" width="300" alt="Grid layout view"/>
</p>

### Media & Practice
Attach all relevant media and track practice sessions

<p align="center">
  <img src="https://github.com/user-attachments/assets/59918de7-5e0c-40d9-a4db-73d10bfe440e" width="300" alt="Media attachments interface"/>
  <img src="https://github.com/user-attachments/assets/3b6eb20d-e677-416d-9fcb-111f14a0ed1b" width="300" alt="Practice tracking interface"/>
</p>

### Organization & Sorting
Group your pieces and tag them as you wish

<p align="center">
  <img src="https://github.com/user-attachments/assets/ceb12e0f-9ce5-4197-82e9-db8563faa386" width="300" alt="Piece organization"/>
  <img src="https://github.com/user-attachments/assets/4aa90d2e-184e-4213-9ca8-d9018d3bedf7" width="300" alt="Sorting options"/>
</p>

### Customization & Backup
Personalize your experience and keep your data safe

<p align="center">
  <img src="https://github.com/user-attachments/assets/e56f076a-71f0-4e17-9464-d5f899d1a055" width="300" alt="Customization settings"/>
  <img src="https://github.com/user-attachments/assets/e3aede9a-62e1-4e4f-bd33-4fca6dc623e9" width="300" alt="Backup and restore"/>
</p>

### Light and Dark Modes
<p align="center">
  TODO: Update image here.
</p>

## Frequently Asked Questions

**Where is my data stored?**
- All your data is stored locally on your device in a private app directory. You can export backups at any time.

**How do I backup or restore my data?**
- Go to Settings > Backup & Restore. You can create manual backups or restore from a previous backup file. Automatic periodic backups are also supported.

**What platforms does the app support?**
- Currently available for Android. Support for web, Windows, macOS, and Linux is planned for the future.

## Contributing

We welcome contributions from everyone! Whether you're fixing bugs, adding features, or improving documentation, your help is appreciated.

### Hacktoberfest 2025

<a href="https://hacktoberfest.digitalocean.com/"><img src="https://img.shields.io/badge/Hacktoberfest-2025-2ea44f?style=flat-square" alt="Hacktoberfest 2025"/></a>

We are participating in Hacktoberfest! Look for the `hacktoberfest` and `good first issue` labels in our [issues tab](https://github.com/Adithya-Jayan/MyRepertoirApp/issues).

### How to Contribute

Please read our [Contributing Guidelines](CONTRIBUTING.md) before getting started.

**For Developers:**

1. Clone the repository:
   ```sh
   git clone https://github.com/your_username/repertoire.git
   ```

2. Navigate to the project directory:
   ```sh
   cd repertoire
   ```

3. Install dependencies:
   ```sh
   flutter pub get
   ```

4. Run the app:
   ```sh
   flutter run
   ```

**Prerequisites:** Ensure you have the Flutter SDK installed. See the [official Flutter installation guide](https://flutter.dev/docs/get-started/install).

### Project Structure

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

### Tech Stack

- Flutter (Dart)
- SQLite (local storage)
- just_audio, video_player (media playback)
- Provider (state management)
- Other libraries: file_picker, share_plus, url_launcher, etc.

## Credits

Thank you to all the people who have contributed! (Please contribute to help improve the app 🥺)

<a href="https://github.com/Adithya-Jayan/MyRepertoirApp/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Adithya-Jayan/MyRepertoirApp"  alt="MyRepertoir app contributors" title="MyRepertoir app contributors" width="100" anon=1/>
</a>

Made with [contrib.rocks](https://contrib.rocks).

## Support & License

For help, bug reports, or feature requests, open an [issue](https://github.com/Adithya-Jayan/MyRepertoirApp/issues).

Distributed under the Apache 2.0 licence. See [NOTICE](Notice) and [LICENSE](LICENSE) for more information.

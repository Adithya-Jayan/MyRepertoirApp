# Contributing to Repertoire

First off, thank you for considering contributing to Repertoire! It's people like you that make the open-source community such a great place. Any contributions you make are **greatly appreciated**.

This document provides guidelines for contributing to the project. Please read it carefully to ensure a smooth and effective contribution process.

## How Can I Contribute?

There are many ways to contribute to Repertoire, from writing code to improving documentation. Here are a few ideas:

- **Reporting Bugs**: If you find a bug, please open an issue and provide detailed steps to reproduce it.
- **Suggesting Enhancements**: If you have an idea for a new feature or an improvement to an existing one, open an issue to discuss it.
- **Writing Code**: Help fix bugs or implement new features.
- **Improving Documentation**: Enhance the README, add tutorials, or improve the in-code documentation.
- **Updating Screenshots**: The UI has changed, and we need new screenshots for the README and website.

## Getting Started

1.  **Fork the repository** on GitHub.
2.  **Clone your fork** to your local machine:
    ```sh
    git clone https://github.com/your_username/MyRepertoirApp.git
    ```
3.  **Navigate to the project directory:**
    ```sh
    cd MyRepertoirApp
    ```
4.  **Choose the project variant to run and install dependencies:**
    Because of our flavor setup, dependencies must be fetched in both the root directory and the specific variant directory.

    * **F-Droid Build (FOSS)**:
      ```sh
      flutter pub get
      cd app_fdroid
      flutter pub get
      flutter run
      ```
    * **Play Store Build (Google Play)**:
      ```sh
      flutter pub get
      cd app_playstore
      flutter pub get
      flutter run
      ```
5.  **Create a new branch** for your feature or bug fix:
    ```sh
    git checkout -b feature/YourAmazingFeature
    ```
6.  **Make your changes**.
7.  **Run the app** to test your changes.

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

- **Flutter (Dart)**
- **SQLite** (`sqflite` / `sqflite_common_ffi`) for local storage
- **pdfrx** for F-Droid compatible PDF rendering
- **just_audio** & **media_kit** for rich media playback
- **Provider** for state management
- Other libraries: `file_picker`, `archive`, `dart_midi_pro`, `share_plus`, etc.
8.  **Commit your changes** with a clear and descriptive commit message:
    ```sh
    git commit -m 'Add some AmazingFeature'
    ```
9.  **Push your changes** to your fork:
    ```sh
    git push origin feature/YourAmazingFeature
    ```
10. **Open a Pull Request** from your fork to the `main` branch of the original repository.

## Code Style

Please follow the existing code style in the project. We use the standard Dart and Flutter formatting guidelines. You can format your code using:

```sh
dart format .
```

## Adding or Updating Translations

Repertoire uses Flutter's ARB-based localization support. See the dedicated
[translation guide](docs/TRANSLATIONS.md) for locale naming, native language
names, placeholders, generated files, validation, and the pull request
checklist.

To contribute a language:

1. Copy `lib/l10n/app_en.arb` to `lib/l10n/app_<locale>.arb` and update
   `@@locale`.
2. Translate `languageName` into the language itself, then translate the other
   message values while preserving keys, ICU syntax, and placeholders.
3. Run `flutter gen-l10n`; the generated locale will automatically appear in
   the in-app language selector.
4. Run `flutter analyze` and `flutter test` before opening your pull request.

When adding a new user-facing string, add it to `app_en.arb` and access it with
`context.l10n.<messageName>` instead of embedding the text directly in a widget.

## Pull Request Guidelines

- Ensure your PR is based on the `main` branch.
- Provide a clear and descriptive title for your PR.
- In the PR description, explain the purpose of your changes and reference any related issues.
- Make sure your code is well-documented, especially for new features or complex logic.
- Ensure that your changes do not introduce any new warnings or errors.

Thank you for your contribution!

# How to Install Repertoire

Repertoire is a cross-platform application available for Android, with experimental desktop and web builds. Choose your platform below for installation instructions.

---

## Android

Repertoire comes in two flavors for Android:
* **F-Droid Variant (Recommended):** Fully open-source, no proprietary code.
* **Play Store Variant:** Might include proprietary Google services in the future (like Google Drive sync and analytics).

### Option 1: Install from F-Droid (Recommended)

F-Droid is a trusted, community-maintained software repository for Android. Installing from F-Droid is the easiest way to get the app and keep it updated automatically.

1.  **Get the F-Droid Client:** Install the F-Droid client from the [official F-Droid website](https://f-droid.org/).
2.  **Open the App Page:** Click the logo below or search for "Repertoire" in the F-Droid app.

    <a href="https://f-droid.org/en/packages/io.github.adithya_jayan.myrepertoirapp.fdroid/">
      <img src="https://gitlab.com/fdroid/fdroidclient/-/raw/master/logo-icon.svg" alt="Get it on F-Droid" height="80">
    </a>

3.  **Install:** Tap "Install" to download and automatically update the app in the future.

### Option 2: Manual Installation (APK)

If you prefer to install manually without an app store:

1.  **[Click here to go to the latest release page.](https://github.com/Adithya-Jayan/MyRepertoirApp/releases/latest)**
2.  Scroll down to the **Assets** section.
3.  Download the universal APK for your preferred variant:
    * `app-universal-fdroid-release.apk` (For the fully open-source version)
    * `app-universal-playstore-release.apk` (For the Play Store variant)
4.  Once downloaded, tap the notification to open the `.apk` file. 
    *Note: Your phone may show a security pop-up. Tap **"Settings"** and enable **"Allow from this source"**, then go back and tap **"Install"**.*

---

## Web Server Hosting

You can host Repertoire yourself on any static web server (like GitHub Pages, Vercel, or Nginx).

1.  **[Click here to go to the latest release page.](https://github.com/Adithya-Jayan/MyRepertoirApp/releases/latest)**
2.  Scroll down to the **Assets** section and download `web_build.zip`.
3.  Extract the `.zip` file.
4.  Upload the extracted contents to your static web hosting provider.

---

## Desktop

We also provide desktop builds for Windows and Linux. Please note that these builds are provided as-is and may not be actively tested prior to every release.

### Windows

1.  **[Click here to go to the latest release page.](https://github.com/Adithya-Jayan/MyRepertoirApp/releases/latest)**
2.  Scroll down to the **Assets** section and download the Windows release zip file (e.g., `repertoire-windows-v1.0.0.zip`).
3.  Extract the `.zip` file to a folder on your computer.
4.  Open the folder and double-click `repertoire.exe` to run the app.
    *Note: Windows SmartScreen may show a "Windows protected your PC" warning. Click **"More info"** and then **"Run anyway"**.*

### Linux

1.  **[Click here to go to the latest release page.](https://github.com/Adithya-Jayan/MyRepertoirApp/releases/latest)**
2.  Scroll down to the **Assets** section and download the Linux release zip file (e.g., `repertoire-linux-v1.0.0.zip`).
3.  Extract the `.zip` file.
4.  Open your terminal, navigate to the extracted folder, and execute the app by running `./repertoire`.

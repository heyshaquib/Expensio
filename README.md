<h2 align="center"><b>Expensio 💸</b></h2>
<h4 align="center">A privacy-first, fully offline Android expense tracker featuring Material You Monet dynamic theming, comprehensive visualization, and manual transaction management to give users complete control over their budgets.</h4>

<hr>
<p align="center"><a href="#description">Description</a> &bull; <a href="#features">Features</a> &bull; <a href="#getting-started">Getting Started</a> &bull; <a href="#contributing">Contributing</a> &bull; <a href="#privacy-policy">Privacy Policy</a> &bull; <a href="#license">License</a></p>
<hr>

<p align="center">
  <img src="https://img.shields.io/badge/license-GPLv3-blue" alt="License">
  <img src="https://img.shields.io/badge/Flutter-3.7+-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.7+-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/platform-Android-3DDC84?logo=android" alt="Android">
</p>

## Description

Expensio is a modern, Material Design 3 expense tracking application. Built with Flutter, it offers a fresh, beautiful, and native-feeling Android experience while maintaining a core philosophy: providing a private, secure, and completely offline environment for managing your personal finances.

Since it is free and open-source software, Expensio does not use any cloud servers, proprietary tracking libraries, or data collection frameworks. This means your financial data never leaves your device and you retain 100% ownership of your information.

### Features

* **🔒 100% Offline & Private:** No cloud dependency, servers, or trackers. All financial data stays on your device in a local SQLite database.
* **✏️ Manual Transaction Entry:** Add income and expenses manually with categories, and dates. Chips sort dynamically based on your usage frequency.
* **🏷️ Custom Categories Management:** Create, enable/disable, and delete custom tags with segmented Expense/Income toggles, curated emojis, or native system keyboard custom emoji input.
* **🎨 Dynamic Monet Theming:** Material 3 UI with `dynamic_color` support. Adapts to your wallpaper colors with full Light/Dark mode support and custom deterministic chart colors.
* **📊 Interactive Analytics:** Spending trends, category breakdowns, and budget tracking via `fl_chart` interactive charts.
* **💰 Budget Management:** Set monthly budgets per category with real-time tracking, automatically cleaned up on custom tag deletion.
* **💾 Backup & Restore:** Complete settings, transaction records, and custom categories portability via robust JSON exports and restores using `file_picker`.

## Getting Started

> [!IMPORTANT]
> This is the SHA-256 fingerprint of Expensio's signing key to verify downloaded APKs which are signed by us:
> `E2:EE:E6:AD:2D:1F:CB:F9:B9:34:E1:9D:7C:AF:4A:5D:4B:81:59:1A:6B:65:52:81:CC:F4:01:C1:45:81:64:13`

### Prerequisites

- Flutter SDK `^3.7.0`
- Android SDK with Build Tools (min SDK 26, target SDK 35)
- Java 17 (for Gradle / Kotlin DSL builds)

### Installation / Build from source

To build a debug APK yourself:

1. Clone the repository:
   ```bash
   git clone https://github.com/heyshaquib/Expensio.git
   cd Expensio
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run Drift code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Contributing

Whether you have ideas, translations, design changes, code cleaning, or even major code changes, help is always welcome. The app gets better and better with each contribution, no matter how big or small!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Privacy Policy

Expensio aims to provide a completely private and secure experience for managing your finances. Therefore, the app does not collect, transmit, or store any data on external servers. All your financial data, settings, and transaction history remain strictly on your local device within an offline SQLite database.

## License

[![GNU GPLv3 Image](https://www.gnu.org/graphics/gplv3-127x51.png)](https://www.gnu.org/licenses/gpl-3.0.en.html)

Expensio is Free Software: You can use, study, share, and improve it at will. Specifically, you can redistribute and/or modify it under the terms of the [GNU General Public License](https://www.gnu.org/licenses/gpl.html) as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

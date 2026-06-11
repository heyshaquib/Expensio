# Expensio 💸

> A privacy-first, fully offline Android expense tracker featuring Material You Monet dynamic theming, comprehensive visualization, and manual transaction management to give users complete control over their budgets.

![License](https://img.shields.io/badge/license-MIT-blue) ![Flutter](https://img.shields.io/badge/Flutter-3.7+-02569B?logo=flutter) ![Dart](https://img.shields.io/badge/Dart-3.7+-0175C2?logo=dart) ![Android](https://img.shields.io/badge/platform-Android-3DDC84?logo=android)
---

## ✨ Key Features

- **🔒 100% Offline & Private** - No cloud dependency, servers, or trackers. All financial data stays on your device in a local SQLite database.
- **✏️ Manual Transaction Entry** - Add income and expenses manually with categories, and dates. Chips sort dynamically based on your usage frequency.
- **🏷️ Custom Categories Management** - Create, enable/disable, and delete custom tags with segmented Expense/Income toggles, curated emojis, or native system keyboard custom emoji input. 
- **🎨 Dynamic Monet Theming** - Material 3 UI with `dynamic_color` support. Adapts to your wallpaper colors with full Light/Dark mode support and custom deterministic chart colors.
- **📊 Interactive Analytics** - Spending trends, category breakdowns, and budget tracking via `fl_chart` interactive charts.
- **💰 Budget Management** - Set monthly budgets per category with real-time tracking, automatically cleaned up on custom tag deletion.
- **💾 Backup & Restore** - Complete settings, transaction records, and custom categories portability via robust JSON exports and restores using `file_picker`.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.7.0`
- Android SDK with Build Tools (min SDK 26, target SDK 35)
- Java 17 (for Gradle / Kotlin DSL builds)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/expensio.git
   cd expensio
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run Drift code generation:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to open a Pull Request or create an Issue.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License

Distributed under the MIT License. See `LICENSE` for more information.

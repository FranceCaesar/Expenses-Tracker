# 🏦 ExpenseVault - Expense Tracker App

A modern, feature-rich Flutter mobile application for tracking daily expenses with budget management, REST API integration for real-time currency exchange rates, and Firebase authentication.

---

## 🚀 Quick Start

### 1. Prerequisites
- Flutter SDK v3.11.1 or higher
- Dart SDK
- Android Studio or Xcode (for mobile development)
- Firebase project setup (see `FIREBASE_SETUP.md`)

### 2. Installation

```bash
# Clone/navigate to the project directory
cd app_expenses_tracker_

# Install dependencies
flutter pub get

# Run the app
flutter run
````

### 3\. Firebase Setup

Follow the instructions in [FIREBASE\_SETUP.md](https://www.google.com/search?q=FIREBASE_SETUP.md) to:

  - Create a Firebase project
  - Enable Authentication and Firestore
  - Configure Android/iOS credentials

### 4\. First Run

1.  Create an account with your email and password
2.  Create your first budget (weekly or monthly)
3.  Start adding expenses
4.  View your budget summary and exchange rates

-----

## ✨ Key Features

### 📊 Budget Management

  - Create weekly or monthly budgets
  - Set spending limits
  - Track budget history
  - View budget progress in real-time

### 💰 Expense Tracking

  - Add, edit, and delete expenses
  - Categorize expenses (Food, Transport, Entertainment, etc.)
  - Group expenses by category
  - Track spending patterns

### 💱 Currency Exchange

  - View real-time exchange rates
  - Select your preferred currency
  - Automatic currency conversion
  - Support for 180+ currencies

### 🔐 Authentication

  - Secure user registration and login
  - Firebase Authentication
  - Password-protected accounts
  - Session management

### 📱 Modern UI

  - Clean, intuitive interface
  - Responsive design
  - Visual spending progress indicators
  - Error handling and user feedback

-----

## 📂 Project Structure

```text
lib/
├── main.dart                    # App entry point & routing
├── models/                      # Data models
│   ├── budget_model.dart
│   └── expense_model.dart
├── services/                    # Business logic
│   ├── firebase_service.dart
│   ├── api_service.dart
│   └── currency_service.dart
└── screens/                     # UI screens
    ├── auth/
    ├── home/
    ├── budget/
    └── expense/
```

-----

## 🛠 Available Scripts

```bash
# Run the app in debug mode
flutter run

# Build release APK (Android)
flutter build apk --release

# Build release IPA (iOS)
flutter build ipa --release

# Run tests
flutter test

# Clean build artifacts
flutter clean

# Get dependencies
flutter pub get

# Format code
dart format lib/

# Analyze code for issues
flutter analyze
```

-----

## 📦 Dependencies

  - **firebase\_core**: ^2.10.0
  - **firebase\_auth**: ^4.6.0
  - **cloud\_firestore**: ^4.8.0
  - **http**: ^1.1.0 (API calls)
  - **shared\_preferences**: ^2.2.0 (Local storage)
  - **intl**: ^0.19.0 (Date formatting)

*See `pubspec.yaml` for the complete list.*

-----

## 📚 Documentation

  - [SETUP\_GUIDE.md](https://www.google.com/search?q=SETUP_GUIDE.md) - Detailed setup and feature guide
  - [FIREBASE\_SETUP.md](https://www.google.com/search?q=FIREBASE_SETUP.md) - Firebase configuration guide

-----

## 🏗 Architecture

The app follows a clean architecture pattern:

  - **Models**: Data representation and serialization
  - **Services**: Business logic and API integration
  - **Screens**: UI and state management
  - **Main**: App initialization and routing

**Data flow:**

```text
UI (Screens) → Services → Firebase/API → Models → UI
```

-----

## 🧪 Testing

To test the app:

1.  **Create Account**

    ```text
    Email: test@example.com
    Password: test123456
    ```

2.  **Create Budget**

      - Add budget name and amount
      - Choose weekly or monthly
      - Confirm dates

3.  **Add Expenses**

      - Add various expenses in different categories
      - Edit and delete to test CRUD operations

4.  **Test Features**

      - Change currency and verify updates
      - Check exchange rates load
      - Test logout and login

-----

## 📄 File Structure Overview

### Key Files

| File | Purpose |
|------|---------|
| `main.dart` | App entry point, navigation setup |
| `firebase_options.dart` | Firebase configuration |
| `services/firebase_service.dart` | Firestore CRUD operations |
| `services/api_service.dart` | REST API integration |
| `screens/home/home_screen.dart` | Main dashboard |
| `models/budget_model.dart` | Budget data model |
| `models/expense_model.dart` | Expense data model |

-----

## 🗄 Database Collections

### `budgets`

```json
{
  "userId": "string",
  "name": "string",
  "amount": "double",
  "period": "weekly|monthly",
  "startDate": "timestamp",
  "endDate": "timestamp",
  "isActive": "boolean",
  "createdAt": "timestamp"
}
```

### `expenses`

```json
{
  "userId": "string",
  "budgetId": "string",
  "name": "string",
  "amount": "double",
  "category": "string",
  "date": "timestamp",
  "description": "string"
}
```

-----

## 🔒 Security

  - All user data encrypted in transit (HTTPS)
  - Firebase security rules restrict unauthorized access
  - Password hashing by Firebase Authentication
  - User data isolated by UID

-----

## ⚡ Performance

  - Efficient Firestore queries
  - Stream-based real-time updates
  - Lazy loading where applicable
  - Optimized widget rendering

-----

## 🐛 Troubleshooting

### Common Issues

**Issue**: "google-services.json not found"

  - **Solution**: Place file in `android/app/` directory

**Issue**: "Firebase initialization error"

  - **Solution**: Check Firebase project setup, verify credentials

**Issue**: "iOS build fails"

  - **Solution**: Run `cd ios && pod install && cd ..`

**Issue**: "Exchange rates not loading"

  - **Solution**: Check internet connection, verify API endpoint

See [FIREBASE\_SETUP.md](https://www.google.com/search?q=FIREBASE_SETUP.md) for detailed troubleshooting.

-----

## 🗺 Future Roadmap

  - [ ] Budget analytics and charts
  - [ ] Expense notifications
  - [ ] Receipt image capture
  - [ ] Budget sharing
  - [ ] Export reports (PDF, CSV)
  - [ ] Dark mode
  - [ ] Multi-language support
  - [ ] Recurring expenses
  - [ ] Data backup/restore

-----

## 🤝 Contributing

1.  Fork the repository
2.  Create a feature branch
3.  Make your changes
4.  Submit a pull request

-----

## 📝 License

This project is open-source and available under the [MIT License](https://www.google.com/search?q=LICENSE).

-----

## 💬 Support

For issues or questions:

1.  Check the documentation files
2.  Review [Flutter documentation](https://flutter.dev)
3.  Check [Firebase documentation](https://firebase.google.com/docs)

-----

## 👥 Authors

  - France Jefferson Sulibio

## 🎉 Acknowledgments

  - Flutter team for the amazing framework
  - Firebase for the backend services
  - ExchangeRate-API for exchange rate data

-----

**Current Version**: 1.0.0  
**Last Updated**: April 2026  
**Flutter SDK**: ^3.11.1

```
```

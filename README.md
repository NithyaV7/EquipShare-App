# EquipShare App

## About the Project

**EquipShare** is a Flutter-based application designed to support resource sharing by connecting donors and recipients through a simple and accessible digital platform.

The application aims to make sharing resources easier, encourage collaboration, and provide a convenient user experience.

## Key Features

- User authentication
- Donor interface
- Recipient interface
- User profile management
- QR code or barcode scanning
- Location-based functionality
- Scan result management

## Technologies Used

| Technology | Purpose |
|---|---|
| Flutter | Mobile application development |
| Dart | Programming language |
| Firebase / Backend | To be specified |
| Google ML Kit | Scanning functionality |
| Git & GitHub | Version control and collaboration |

## Project Structure

```text
EquipShare-App/
├── lib/
│   ├── models.dart
│   ├── scan/
│   │   ├── scan_result.dart
│   │   ├── scanner_mlkit.dart
│   │   └── scanner_stub.dart
│   └── ui/
│       ├── auth.dart
│       ├── donor.dart
│       ├── profile.dart
│       ├── recipient.dart
│       └── widgets.dart
├── test/
│   ├── domain_test.dart
│   └── geo_test.dart
├── pubspec.yaml
└── README.md
```

## Installation and Setup

1. Clone the repository:

```bash
git clone https://github.com/NithyaV7/EquipShare-App.git
```

2. Navigate to the project directory:

```bash
cd EquipShare-App
```

3. Install dependencies:

```bash
flutter pub get
```

4. Run the application:

```bash
flutter run
```

## Running Tests

Execute the following command to run the project tests:

```bash
flutter test
```


## Repository

GitHub: https://github.com/NithyaV7/EquipShare-App

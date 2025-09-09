
# QuickJob (quickjob_mobileapp)

Mobile app (Flutter) for a simple job/worker marketplace — employee-facing dashboard, quick-find listings, apply/hire flows and user settings wired to Firebase.

This repository contains the Flutter client used to browse job posts, manage a service provider profile, and handle apply/hire flows. It uses Firebase for authentication and Cloud Firestore for all backend data.

## Key features

- Employee-facing dashboard with search, filters and job cards
- Quick Find listing for service providers with district/city filters
- Google Sign-In authentication
- Employee Settings screen (editable first/last name, contact, district→city, dynamic skills list, geolocation capture)
- Apply flow saves applicant records to Firestore `applicant` collection
- Hire flow prompts a 5-star rating and updates provider `userlog.rating` and `userlog.ratedCount`

## Tech stack

- Flutter (Dart)
- Firebase Auth (Google Sign-In)
- Cloud Firestore
- geolocator (for device GPS)

## Repository structure (important files)

- `lib/` — main Flutter source
	- `main.dart` — app entrypoint and splash screen
	- `landing_page.dart`, `sign_in.dart`, `welcome.dart` — auth / landing flow
	- `employee.dart` — employee dashboard UI
	- `employee_settings.dart` — settings form and Firestore sync logic
	- `quick_find_page.dart` — Quick Find listing and Hire/rating dialog
- `android/` and `ios/` — native configs and platform manifests
- `pubspec.yaml` — Flutter dependencies

## Firebase setup (required)

This app expects a Firebase project with the following collections and documents:

- `userlog` — user profile documents keyed by Firebase UID
- `map` — documents containing `districtName` (or `name`) and `cities` array used for district→city dropdowns
- `jobposts`, `jobcategory` — job data
- `applicant` — saved application records when a user applies

Steps:

1. Create a Firebase project in the Firebase Console.
2. Enable Authentication → Sign-in method → Google.
3. Add an Android app in Firebase and download the `google-services.json` file. Place that file at `android/app/google-services.json`.
4. (If you target iOS) Add an iOS app, download the `GoogleService-Info.plist`, and add it to `ios/Runner`.
5. Create the Firestore collections above or ensure your backend rules allow the client to read/write the documents used by the app during development.

## Android / iOS permissions

- Android: `android/app/src/main/AndroidManifest.xml` already includes location permissions. When testing on Android, the app must be restarted after adding/removing native permissions or adding native plugins.
- iOS: If you plan to run on iOS, add the following keys to `ios/Runner/Info.plist` with human-friendly descriptions:

	- `NSLocationWhenInUseUsageDescription` — e.g. "QuickJob needs your location to save service location for customers."
	- `NSLocationAlwaysAndWhenInUseUsageDescription` (if you need background location)

## Local development — quick start (Windows / PowerShell)

1. Install Flutter SDK (https://docs.flutter.dev/get-started/install).
2. Open a PowerShell terminal and clone the repo:

```powershell
git clone <your-repo-url> quickjob_mobileapp
cd "D:\HD mobile\quickjob_mobileapp"
```

3. Install dependencies and prepare the app:

```powershell
flutter pub get
flutter clean ; flutter pub get
```

4. Run the app on a connected device/emulator (use a full restart when native plugin changes were made):

```powershell
flutter run
```

5. Build a release APK (Android):

```powershell
flutter build apk --release
```

## Important runtime notes

- Native plugin changes (for example, adding `geolocator`) require a full app restart and a clean build (`flutter clean`) — hot reload is not sufficient.
- The `employee_settings.dart` uses the geolocator plugin to save `userlog.serviceLocation` as a `lat,lng` string. Confirm location permissions when running on a device.
- Firestore document structure is assumed to follow the app's conventions (for example `userlog/<uid>`). If your Firestore schema differs, update the code in `lib/` accordingly.

## Tests & checks

Run static analysis and tests before pushing:

```powershell
flutter analyze
flutter test
```

## Troubleshooting

- If you see a MissingPluginException after adding a plugin, run `flutter clean` and restart the app on the device/emulator.
- If Firestore reads fail, verify Firebase project configuration and that `google-services.json` / `GoogleService-Info.plist` are present and correct.

## Contributing

Contributions are welcome. Open an issue or a pull request and follow these steps:

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/my-change`
3. Make changes and add tests where applicable
4. Run `flutter analyze` and `flutter test`
5. Create a pull request describing your changes

## License

This project currently does not include a license file. Add `LICENSE` to the repository if you want to choose a license (MIT/Apache-2.0/etc.).

## Author / Contact

Project created in a collaborative session. For questions about setup or existing features, inspect the key files under `lib/` (especially `employee_settings.dart` and `quick_find_page.dart`) or open an issue in this repository.

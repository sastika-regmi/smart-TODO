# Smart ToDo

A responsive, cloud-backed task manager built with **Flutter** and **Firebase** for **Android** and **Web** from one codebase.

![Flutter](https://img.shields.io/badge/Flutter-3.44.9-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.12.2-0175C2?logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?logo=firebase)
![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20Web-success)
![License](https://img.shields.io/badge/license-MIT-blue)

## Features

- **Auth** — email/password sign up, sign in, sign out, password reset. Session survives restarts.
- **Tasks** — create, edit, complete/reopen, delete. Optional description, priority and due date. A due date can be removed, not just set.
- **Find** — debounced search over title and description, status and priority filters, four sort fields in either direction.
- **Live** — Firestore listeners keep the list current; statistics (total / pending / completed / overdue) update with it.
- **Themes** — light, dark or system, remembered between launches.
- **Responsive** — Material 3 window size classes; nav rail on desktop, swipe-to-delete on phones.
- **Accessible** — semantic labels, 48 px targets, live-region error banners, and colour is never the only signal.

## Tech Stack

| Concern | Choice |
| --- | --- |
| Framework | Flutter 3.44.9, Material 3 |
| Language | Dart 3.12.2, `strict-casts` / `strict-inference` / `strict-raw-types` |
| Auth | `firebase_auth` |
| Database | `cloud_firestore` (real-time listeners) |
| State | `provider` (`ChangeNotifier`) |
| Local storage | `shared_preferences` (theme only) |
| Tests | `flutter_test` + `mocktail` |

## Architecture

Layered, one direction of dependency:

```
presentation  →  domain  ←  data
     │              ▲          │
     └── core ──────┴──────────┘
```

- `domain` — entities, repository interface, use cases, `Result<T>`. Pure Dart, no Flutter, no Firestore.
- `data` — models, remote data source, repository implementation. The only layer that knows Firestore exists.
- `presentation` — screens, widgets, providers. Never builds a Firestore query.
- `core` — theme, constants, errors, utilities, dependency injection.

Two rules keep it honest: **widgets never build Firestore queries**, and **services never touch `BuildContext`**.

```
lib/
├── main.dart
├── core/           # theme, constants, di, errors, utils
├── data/           # datasources, models, repositories
├── domain/         # entities, repositories, usecases
└── presentation/   # providers, screens, widgets
```

## Getting Started

**Prerequisites:** Flutter 3.44.9 (Dart 3.12.2), Android SDK or Chrome, a Firebase project, and the Firebase CLI for deploying rules.

This repository does **not** contain `lib/firebase_options.dart`, `android/app/google-services.json` or `android/local.properties` — they are environment-specific and git-ignored. Configure your own:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project-id>
```

Then in the [Firebase console](https://console.firebase.google.com/):

1. **Authentication → Sign-in method** — enable **Email/Password**.
2. **Firestore Database** — create the database.
3. Deploy the rules: `firebase deploy --only firestore:rules`

Run and build:

```bash
flutter pub get
flutter run                  # attached device or emulator
flutter run -d chrome        # web

flutter build apk --release
flutter build web --release
```

> `applicationId` is `com.example.flutter_application_1` and must stay in step with `google-services.json` — Firebase resolves the Android app by package name.

## Security

Rules live in [`firestore.rules`](firestore.rules). Tasks are stored at `users/{uid}/tasks/{taskId}`, so access is granted by **path**, and every write is additionally checked so `userId == request.auth.uid`.

- Every rule requires `request.auth != null`.
- A user can only read or write under their own uid.
- Updates may not change `userId` or `createdAt`.
- Field types, lengths and the priority enum are validated on every write.
- A catch-all `match /{document=**} { allow read, write: if false }` denies everything else.

There is no `allow read, write: if true` anywhere. Ownership is derived from the signed-in session on the client too — `TaskRemoteDataSourceImpl` reads `FirebaseAuth.currentUser.uid` and refuses operations targeting another user.

## Testing

```bash
flutter test
```

92 test cases across 8 suites covering the domain, data, validation, query, provider and UI layers. Firebase is faked at the repository boundary, so no test touches the network. Filtering and sorting are tested exhaustively (21 cases), including no-due-date ordering in both directions.

```bash
dart format .
flutter analyze
```

`analysis_options.yaml` enables `flutter_lints` plus 72 additional rules.

## Screenshots

> Placeholders — no images are committed. Generate them from a real device or browser; do not ship fabricated ones.

| Screen | Path |
| --- | --- |
| Splash | `docs/screenshots/01-splash.png` |
| Sign in | `docs/screenshots/02-sign-in.png` |
| Sign up | `docs/screenshots/03-sign-up.png` |
| Home — compact | `docs/screenshots/04-home-compact.png` |
| Home — expanded | `docs/screenshots/05-home-expanded.png` |
| Task form | `docs/screenshots/06-task-form.png` |
| Task detail | `docs/screenshots/07-task-detail.png` |
| Settings (dark) | `docs/screenshots/08-settings-dark.png` |

## Status and Limitations

`flutter pub get` resolves and `flutter build apk --debug` completed successfully (88.7 MB APK, built after the last source edit), so the Dart sources compile and the Android Gradle configuration is sound.

Not yet verified in this environment:

- `flutter analyze` and `flutter test` have not been run here. Neither leaves an artifact — run both before submitting.
- `flutter build web` has not been run.
- The Firebase-backed paths have not been exercised against a live project; they are covered by tests with mocked boundaries, which is not the same thing.

Also known:

- Task timestamps are client-generated — type-validated by the rules but not pinned to `request.time`.
- No pagination; the full collection is loaded and filtered client-side. Fine for personal task volumes.
- Android and Web only; other platforms fail with a clear `UnsupportedError`.
- Email verification is not enforced.

## Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| `permission-denied` on every read | Rules not deployed | `firebase deploy --only firestore:rules` |
| `configuration-not-found` on sign-up | Email/Password provider disabled | Enable it in the console |
| "Firebase could not start" screen | `firebase_options.dart` missing or mismatched | `flutterfire configure` |
| Release APK has no network | `INTERNET` permission missing | Already declared in the main manifest — verify your local copy |
| *"The build file has been changed and may need reload"* on `android/app/build.gradle.kts` | The VS Code **Java** extension imported `android/` and its cached Gradle model went stale. A bookkeeping notice, not a build error | Ignore it, or stop it recurring via `"java.import.exclusions": ["**/android/**", "**/build/**"]` in `.vscode/settings.json` |

## License

MIT — see [`LICENSE`](LICENSE).

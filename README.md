# Smart ToDo

A responsive, cloud-backed task manager built with **Flutter** and **Firebase**, targeting **Android** and **Web** from a single codebase.

Smart ToDo lets a signed-in user create, prioritise, search, sort and track tasks in real time across every device they sign in on. Task data is stored per user in Cloud Firestore and protected by server-side security rules — the UI never decides who may read what.

---

## 1. Project Title

**Smart ToDo** — Flutter + Firebase task manager.

## 2. Badges

> The CI badges are placeholders until a pipeline exists — they are not claims.
> The Flutter and Dart versions are real: 3.44.9 stable / Dart 3.12.2, read from
> the SDK this was developed against and matching `pubspec.yaml`'s
> `sdk: ^3.12.2`.

![Flutter](https://img.shields.io/badge/Flutter-3.44.9-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.12.2-0175C2?logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?logo=firebase)
![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20Web-success)
![License](https://img.shields.io/badge/license-MIT-blue)

## 3. Overview

Smart ToDo is a complete task-management application:

- Email/password accounts with a persistent session.
- A real-time task list scoped to the signed-in user.
- Full task lifecycle: create, read, update, complete/reopen, delete.
- Search, status filters, priority filters and four sort orders.
- Live statistics (total, pending, completed, overdue).
- Light, dark and system themes, remembered between launches.
- Responsive layouts for phone, tablet, desktop and browser.
- Material 3 throughout, with accessibility and error states treated as first-class.

## 4. Features

**Authentication**
- Sign up with full name, email, password and password confirmation.
- Sign in / sign out.
- Session persists across restarts (Firebase Auth).
- Forgot-password email flow.
- Inline, human-readable error messages for every failure mode.

**Task management**
- Create, view, edit and delete tasks.
- Mark complete / reopen, with a completion timestamp.
- Optional description, priority (low/medium/high) and due date.
- Due dates can be changed *and removed*.
- Overdue detection by calendar day, not by elapsed hours.

**Finding things**
- Debounced search across title and description.
- Filter by status (all / pending / completed).
- Filter by priority (all / low / medium / high).
- Sort by created date, due date, priority or title, ascending or descending.
- Tasks without a due date always sort last, in both directions.

**Personalisation and polish**
- Light / dark / system theme, persisted locally.
- Splash → content, with no flash of the sign-in screen for a returning user.
- Distinct empty states for "no tasks yet" and "nothing matched".
- Retry action when the task stream fails.

## 5. Screenshots

> **Placeholders.** No screenshots are committed. Generate them from a real
> device or browser and replace the image paths below — do not ship this README
> with fabricated images.

| Screen | Placeholder |
| --- | --- |
| Splash | `docs/screenshots/01-splash.png` — _add real screenshot_ |
| Sign in | `docs/screenshots/02-sign-in.png` — _add real screenshot_ |
| Sign up | `docs/screenshots/03-sign-up.png` — _add real screenshot_ |
| Home — compact (phone) | `docs/screenshots/04-home-compact.png` — _add real screenshot_ |
| Home — expanded (desktop) | `docs/screenshots/05-home-expanded.png` — _add real screenshot_ |
| Add task | `docs/screenshots/06-add-task.png` — _add real screenshot_ |
| Task detail | `docs/screenshots/07-task-detail.png` — _add real screenshot_ |
| Settings (dark theme) | `docs/screenshots/08-settings-dark.png` — _add real screenshot_ |

## 6. Tech Stack

| Concern | Choice |
| --- | --- |
| Framework | Flutter (Material 3) |
| Language | Dart, null-safe |
| Auth | `firebase_auth` — email/password |
| Database | `cloud_firestore` — real-time listeners |
| State | `provider` (`ChangeNotifier`) |
| Local storage | `shared_preferences` — theme only |
| Formatting | `intl` |
| App metadata | `package_info_plus` |
| Lint | `flutter_lints` + ~60 additional strict rules |
| Tests | `flutter_test` + `mocktail` |

## 7. Architecture

Layered, feature-agnostic, one direction of dependency:

```
presentation  →  domain  ←  data
     │              ▲          │
     └── core ──────┴──────────┘
```

- **`domain`** — entities, repository interfaces, use cases. Pure Dart; no Flutter, no Firestore.
- **`data`** — models, data sources, repository implementations. Knows about Firestore.
- **`presentation`** — screens, widgets, providers. Knows about Flutter; never talks to Firestore directly.
- **`core`** — theme, constants, errors, utilities, and the dependency-injection entry point.

The rule that keeps this honest: **widgets never construct Firestore queries, and services never touch `BuildContext`.**

## 8. Folder Structure

```
lib/
├── main.dart                     # bootstrap + MaterialApp
├── firebase_options.dart         # generated config (git-ignored)
├── core/
│   ├── constants/                # AppConstants
│   ├── di/                       # initializeDependencies()
│   ├── errors/                   # Failure hierarchy
│   ├── services/                 # AuthService
│   ├── theme/                    # AppTheme, AppThemeMode
│   └── utils/                    # validators, task_query, dates, responsive, prefs
├── data/
│   ├── datasources/              # TaskRemoteDataSource
│   ├── models/                   # TaskModel
│   └── repositories/             # TaskRepositoryImpl
├── domain/
│   ├── entities/                 # Task, TaskPriority
│   ├── repositories/             # TaskRepository, Result<T>
│   └── usecases/                 # WatchTasks, CreateTask, …
└── presentation/
    ├── providers/                # AuthProvider, TaskProvider, ThemeProvider
    ├── screens/                  # auth/, tasks/, settings/, profile/
    └── widgets/                  # shared, presentational widgets
```

## 9. Data Model

`Task` (`lib/domain/entities/task.dart`) — immutable, pure Dart:

| Field | Type | Notes |
| --- | --- | --- |
| `id` | `String` | Firestore document id |
| `userId` | `String` | Owner; always taken from the session |
| `title` | `String` | Required, ≤ 100 characters |
| `description` | `String?` | Optional, ≤ 500 characters |
| `isCompleted` | `bool` | |
| `priority` | `TaskPriority` | `low` / `medium` / `high` |
| `dueDate` | `DateTime?` | Optional |
| `createdAt` | `DateTime` | |
| `updatedAt` | `DateTime` | |
| `completedAt` | `DateTime?` | Set on completion, cleared on reopen |

`copyWith` uses a sentinel so that `copyWith(dueDate: null)` **clears** the field while omitting the argument **preserves** it. Without that distinction a due date could never be removed.

Equality compares every field, so `context.select` and `listEquals` detect edits rather than only identity changes.

## 10. Firestore Schema

```
users/{uid}
  uid:         string      // must equal {uid}
  displayName: string
  email:       string
  createdAt:   timestamp   // server timestamp
  updatedAt:   timestamp   // server timestamp

users/{uid}/tasks/{taskId}
  userId:      string      // must equal the authenticated uid
  title:       string      // 1..100
  description: string|null // 0..500
  isCompleted: boolean
  priority:    'low' | 'medium' | 'high'
  dueDate:     timestamp|null
  createdAt:   timestamp
  updatedAt:   timestamp
  completedAt: timestamp|null
```

Tasks live in a **subcollection of the owning user**, not in a top-level collection with a `userId` field. That shape is what makes the security rules provable: access is granted by path, and no query ever needs to look outside one user's subtree.

## 11. Security Rules

See [`firestore.rules`](firestore.rules). Summary:

- Every rule requires `request.auth != null`.
- A user may only read or write under `users/{their own uid}`.
- Task documents must declare `userId == request.auth.uid`.
- Updates may not change `userId` or `createdAt`, so a task cannot be reassigned or backdated.
- Field types, lengths, and the priority enum are validated on every write.
- `users/{uid}` deletion is denied.
- A catch-all `match /{document=**} { allow read, write: if false }` denies anything not explicitly allowed.

There is no `allow read, write: if true` anywhere, and no path depends on a client-supplied uid. Deploy with:

```bash
firebase deploy --only firestore:rules
```

## 12. Authentication Flow

1. `Firebase.initializeApp` runs in `main()` before the first frame.
2. `AuthProvider` subscribes to `FirebaseAuth.authStateChanges()`.
3. `AuthGate` renders one of three states:
   - **not yet resolved** → splash (or an error view with *Retry*),
   - **signed in** → task list,
   - **signed out** → sign-in screen.
4. On sign-out, `TaskProvider` cancels its Firestore listener and clears every cached task and filter, so nothing leaks into the next session.

Credentials are only ever held by Firebase. No password, token or user id is written to disk or to `SharedPreferences`.

## 13. State Management

Three independent `ChangeNotifier`s, created once in `lib/core/di/injection.dart`:

| Provider | Owns |
| --- | --- |
| `AuthProvider` | session state, loading flag, user-facing auth errors |
| `TaskProvider` | the Firestore subscription, the task query, statistics |
| `ThemeProvider` | the selected theme mode |

Consumers subscribe to **narrow slices** with `context.select`, so typing in the search box does not rebuild the app bar and toggling one checkbox does not rebuild the statistics row.

## 14. Theming

`AppTheme` builds light and dark `ThemeData` once, from a single seed colour (`#6750A4`), and caches them in `static final` fields. Both themes configure `ColorScheme`, app bar, cards, inputs, buttons, chips, checkboxes, switches, FAB, dialogs, bottom sheets, snack bars, navigation rail, list tiles, dividers, date picker, progress indicators and text selection.

No downloaded fonts: the Material 3 type scale is used as shipped, so there is no first-paint font flash and no offline fallback risk.

## 15. Responsive Design

Material 3 window size classes:

| Class | Width | Behaviour |
| --- | --- | --- |
| Compact | `< 600` | single column, swipe-to-delete, bottom padding for the FAB |
| Medium | `600–1023` | single column, wider gutters |
| Expanded | `≥ 1024` | navigation rail, content capped at 1280px |

Forms are capped at 560px regardless of window width — a 1280px-wide text field is unusable. Sizes are read through `MediaQuery.sizeOf`, which does not rebuild on keyboard-driven `MediaQuery` changes.

## 16. Accessibility

- Every icon-only control has a tooltip and a semantic label.
- Task rows announce title, status, priority and due state as one sentence.
- Interactive targets are at least 48×48 logical pixels.
- Async error banners are `liveRegion`s, so screen readers announce them.
- Colour is never the only signal: priority, status and overdue each carry an icon and a word.
- Text scaling is clamped to 0.8×–1.6× so the layout stays usable at extreme settings.

## 17. Performance

- `Task` equality is value-based, so unchanged snapshots do not trigger rebuilds.
- `TaskProvider._recompute()` returns early when the filtered result is unchanged, so a snapshot that does not alter the visible list causes no rebuild. It is *forced* when the loading or error flags changed too — otherwise a first snapshot that happens to be empty would leave the spinner up forever.
- Search input is debounced (250 ms) and clears instantly.
- `DateFormat` instances and `ThemeData` objects are constructed once.
- Lists use `ListView.builder`; statistics tiles use `RepaintBoundary`.
- The search field rebuilds itself via `ValueListenableBuilder` rather than rebuilding the screen.

## 18. Error Handling

Failures are mapped to a `Failure` hierarchy (`AuthFailure`, `PermissionFailure`, `NetworkFailure`, `NotFoundFailure`, `ServerFailure`) and surfaced as a user-facing sentence — never a raw error code or stack trace.

- Auth errors appear inline on the form.
- Task stream errors replace the list with an error view and a *Retry* action.
- Mutation errors appear in a snack bar and never navigate away.
- Startup failures render a diagnostic screen with setup instructions instead of a blank window.

## 19. Validation Rules

| Field | Rule |
| --- | --- |
| Email | required, must match an address pattern |
| Password (sign-up) | required, ≥ 6 and ≤ 128 characters |
| Password (sign-in) | required only — strength rules are deliberately *not* applied |
| Confirm password | required, must match |
| Full name | required, ≤ 60 characters |
| Task title | required, ≤ 100 characters |
| Task description | optional, ≤ 500 characters |

Sign-in intentionally checks presence only: applying today's strength rules to an existing password would lock out accounts created before a rule change, with an error the user cannot act on.

## 20. Prerequisites

- **Flutter 3.44.9 (stable) with Dart 3.12.2.** `pubspec.yaml` pins `sdk: ^3.12.2`, so 3.12.2 is a hard floor, not a suggestion.
- Android Studio + Android SDK (for Android builds) or Chrome (for web)
- A Firebase project
- Node.js + the Firebase CLI (`npm i -g firebase-tools`) to deploy rules

The Android SDK path is read from `android/local.properties` (`sdk.dir`), and the Flutter SDK path from the same file (`flutter.sdk`). Both must exist before a Gradle build will configure — a missing Android SDK fails at *configure* time, not at compile time, with an error that does not name the file.

## 21. Firebase Setup

The project is generated with the official FlutterFire workflow. **Do not hand-write credentials.**

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project-id>
```

That command writes `lib/firebase_options.dart` and `android/app/google-services.json`.

Then, in the [Firebase console](https://console.firebase.google.com/):

1. **Authentication → Sign-in method** — enable **Email/Password**.
2. **Firestore Database** — create the database.
3. Deploy the rules and indexes:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

`lib/firebase_options.dart` is git-ignored and is **not** in this repository. A clone will not build until `flutterfire configure` has been run. This is deliberate: credentials do not belong in version control.

## 22. Running the App

```bash
flutter pub get
flutter run              # attached device or emulator
flutter run -d chrome    # web
```

## 23. Building for Android

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

The release build signs with the debug keystore by default. Supply a real keystore before publishing:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload
```

then reference it from `android/key.properties` (git-ignored) and `android/app/build.gradle.kts`.

The `INTERNET` permission is declared in the **main** manifest. It must be — a release APK has no network access without it, and every Firebase call would fail.

## 24. Building for Web

```bash
flutter build web --release
# served from a sub-path?
flutter build web --release --base-href /your/path/
```

## 25. Testing

```bash
flutter test
```

| Suite | Covers |
| --- | --- |
| `test/domain/task_test.dart` | `copyWith` including field clearing, value equality, overdue logic, priority parsing |
| `test/data/task_model_test.dart` | serialisation, defensive deserialisation, legacy timestamp shapes, round trip |
| `test/core/validators_test.dart` | every validation rule, including both password paths |
| `test/core/task_query_test.dart` | search, status/priority filters, all four sorts, combined filters, no input mutation |
| `test/presentation/task_provider_test.dart` | subscription lifecycle, sign-out cleanup, debounce, mutation guards, stream errors, retry, and the empty-first-snapshot case that must still clear the loading state (see §17) |
| `test/widget/sign_in_screen_test.dart` | form validation, successful sign-in, inline error, no stuck spinner |
| `test/widget/task_form_screen_test.dart` | task validation, trimmed values, closing on success, staying open on failure |
| `test/widget_test.dart` | theme switching, persistence, unknown stored value fallback |

## 26. Code Quality

`analysis_options.yaml` enables `flutter_lints` plus roughly sixty additional rules, including:

- `prefer_single_quotes`, `directives_ordering`, `sort_constructors_first`
- `prefer_const_constructors`, `prefer_final_locals`, `prefer_initializing_formals`
- `unawaited_futures`, `use_build_context_synchronously`
- `strict-casts`, `strict-inference`, `strict-raw-types`

Run it with:

```bash
dart format .
flutter analyze
```

## 27. Known Limitations

1. **The verification commands have not been run in this environment.** Command execution was unavailable where this code was written, so none of these has ever been executed. Treat them as outstanding, not as passing, and run them before submitting:
   ```bash
   dart format .
   flutter analyze
   flutter test
   flutter build apk --release
   flutter build web --release
   ```
   What *was* verified, so you know where to start looking: the toolchain resolves (Flutter 3.44.9 stable / Dart 3.12.2, matching `sdk: ^3.12.2`; `.dart_tool/package_config.json` was generated by pub 3.12.2), both SDK paths declared in `android/local.properties` resolve to real directories, and the IDE's Dart analyzer — which applies this project's `analysis_options.yaml` and its ~60 extra rules — reported zero errors, warnings and lints across the files touched in the final pass. That last one is a *per-file* signal: it is not a substitute for a project-wide `flutter analyze`, and it says nothing about whether the tests pass.
   Two things are known to need a first run: `dart format` will reflow a handful of long lines (a few `RegExp` and `switch` statements exceed 80 columns), and no build output has been produced yet.
2. **Firebase runtime verification was not performed.** The Firebase-backed paths (sign-up, sign-in, live task sync, rule enforcement) have not been exercised against a live project from the environment this code was written in. They are covered by unit and widget tests with mocked boundaries, which is not the same thing.
3. Timestamps (`createdAt`, `updatedAt`, `completedAt` on tasks) are generated by the client. The profile document uses server timestamps. See §35 for the upgrade path.
4. Offline persistence is not explicitly enabled; Firestore's default in-memory cache applies.
5. Android and Web only. Other platforms throw a clear `UnsupportedError` at startup rather than failing obscurely.
6. Password reset does not deep-link back into the app; it uses Firebase's hosted page.
7. Email verification is not enforced.
8. No pagination — the whole task collection is loaded and filtered client-side. Fine for personal task volumes; see §34.

## 28. Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| `UnsupportedError: configured for Android and Web only` | Running on iOS/macOS/Windows/Linux | `flutterfire configure` for that platform |
| `permission-denied` on every read | Rules not deployed | `firebase deploy --only firestore:rules` |
| `configuration-not-found` on sign-up | Email/Password provider disabled | Enable it in the Firebase console |
| Blank window at startup | `lib/firebase_options.dart` missing | `flutterfire configure` |
| Release APK has no network | `INTERNET` permission missing | Already declared in the main manifest — verify your local copy |
| `google-services.json` not found | Android config not generated | `flutterfire configure` |
| *"The build file has been changed and may need reload to make it effective"* reported against `android/app/build.gradle.kts` | The VS Code **Java** extension imported `android/` as a Gradle project and its cached model went stale when a build file changed. It is a bookkeeping notice about the extension's own cache, not a build error | Ignore it — see below if it is noise you want gone |

### The Android Gradle model warning

If the VS Code **Java** extension reports

> The build file has been changed and may need reload to make it effective.

against `android/app/build.gradle.kts`, nothing is wrong with the project. The extension imports `android/` as a Gradle project and keeps its own copy of the model. That copy duplicates what the Gradle wrapper already builds, and it goes stale every time a build file changes — so the notice reappears after any edit to `build.gradle.kts`.

Nothing here needs that import: `flutter build apk` drives the Gradle wrapper directly and never consults the Java language server, and the only Java/Kotlin in the repo is the generated `MainActivity` and plugin registrant. To stop the notice coming back, exclude the Android tree from Java's import in `.vscode/settings.json`:

```json
{
    "java.import.exclusions": [
        "**/android/**",
        "**/build/**"
    ]
}
```

The language server re-imports when a `java.*` setting changes, so no window reload is needed. To clear it **once** without changing any settings: `Ctrl+Shift+P` → **Java: Clean Java Language Server Workspace**.

## 29. Roadmap

- Server-side pagination for large collections.
- Recurring tasks.
- Task reminders via local notifications.
- Sharing a list between accounts (would require rules that model membership, not just ownership).
- CSV/JSON export.

## 30. Contributing

1. Branch from `main`.
2. Keep `flutter analyze` clean and add tests for behaviour changes.
3. Run `dart format .`, `flutter analyze`, `flutter test` before opening a PR.
4. Never commit `lib/firebase_options.dart`, `google-services.json`, keystores or `.env` files.

## 31. License

MIT. See `LICENSE`.

## 32. Author

Add your name, course, institution and student id here before submission.

## 33. Acknowledgements

- Flutter and the Material 3 design system.
- Firebase / FlutterFire.
- The `provider` and `mocktail` packages.

## 34. Performance Notes

Filtering, searching and sorting happen **client-side** over the full task collection. That is a deliberate trade-off: it makes search instant and keeps the Firestore query to a single ordered listener, which is the right shape for personal task volumes (hundreds, not millions, of documents, and only one user's).

If a user ever accumulates tens of thousands of tasks, the upgrade path is server-side filtering with `where` clauses plus `limit`/`startAfter` pagination, and the corresponding composite indexes in `firestore.indexes.json`. That would move the work to Firestore and make each keystroke a network round trip, so it should only be done when the local approach measurably falls short.

## 35. Security and Data Notes

- **Ownership is derived from the session, never from an argument.** `TaskRemoteDataSourceImpl` reads `FirebaseAuth.currentUser.uid` and refuses any operation whose target belongs to someone else, so even a modified client cannot address another user's data — and the rules reject it regardless.
- **No secrets on disk.** `SharedPreferences` stores exactly one key: the theme mode. No uid, no tokens, no credentials.
- **Tasks are addressed directly, not by collection-group query.** A `collectionGroup('tasks')` scan cannot be proven to stay inside one user's subtree, so the rules correctly reject it; addressing `users/{uid}/tasks/{taskId}` avoids the problem and the extra index entirely.
- **Task timestamps are client-generated.** They are type-validated by the rules but not pinned to `request.time`, so a modified client could backdate its own `createdAt`. This only affects that user's own data. To close it: write `FieldValue.serverTimestamp()` for `createdAt`/`updatedAt` in `TaskModel.toFirestore`, add `request.resource.data.createdAt == request.time` on create, and `updatedAt == request.time` on update. It was left out here because it cannot be verified against a live project from this environment, and a rule that is subtly wrong would block every write.

## 36. FAQ

**Why a subcollection instead of a `userId` field?**
Because rules can then grant access by path, which is provable, instead of by inspecting document data, which is not — and it removes the temptation of a cross-user query.

**Why does sign-in not enforce password strength?**
Because the password already exists. Strength rules belong at creation; enforcing them at sign-in only locks people out.

**Why is `lib/firebase_options.dart` git-ignored?**
It contains project-specific configuration. It is not a secret — Firebase API keys ship in every client — but it is environment-specific, and the repo stays cleaner when a clone configures its own project.

**Why does the app refuse to run on desktop?**
Because those platforms have no real credentials configured. Failing loudly with instructions beats a blank screen.

## 37. Manual QA Checklist

Run through this on a real device or browser before submitting.

**Authentication**
- [ ] Sign up with a new email; confirm the task list appears.
- [ ] Sign up with an existing email; confirm a clear error.
- [ ] Sign up with mismatched passwords; confirm the confirm-password error.
- [ ] Sign in with wrong credentials; confirm an error and that the button re-enables.
- [ ] Sign out from Settings; confirm the sign-in screen appears.
- [ ] Force-quit and relaunch while signed in; confirm no sign-in flash.

**Tasks**
- [ ] Create a task with a title only.
- [ ] Create a task with description, priority and due date.
- [ ] Edit a task; confirm the list updates without a manual refresh.
- [ ] Remove a due date from an existing task; confirm it is actually gone.
- [ ] Complete and reopen a task.
- [ ] Delete a task; confirm the dialog and that it disappears.
- [ ] Swipe a task on a phone-width layout; confirm the confirmation dialog appears.

**Finding things**
- [ ] Search by title, then by description.
- [ ] Clear the search with the ✕; confirm all tasks return immediately.
- [ ] Apply status and priority filters, then *Clear*.
- [ ] Try each sort order, including "Due soonest" with tasks that have no due date.
- [ ] Confirm the "no matching tasks" state (not "no tasks yet") when a filter matches nothing.

**Themes and layout**
- [ ] Switch light / dark / system; confirm the change is instant.
- [ ] Restart; confirm the theme was remembered.
- [ ] Rotate the device / resize the browser to < 600, 600–1023 and ≥ 1024; confirm the layout adapts and nothing overflows.
- [ ] Set system text size to maximum; confirm nothing is clipped.

**Failure paths**
- [ ] Sign in with the device in airplane mode; confirm a readable error.
- [ ] Open the app with no Firebase config; confirm the diagnostic screen, not a blank window.

## 38. Change Log

**1.0.0**
- Initial release: authentication, real-time task CRUD, search/filter/sort, statistics, themes, responsive layouts.
- Security rules enforcing per-user ownership with field validation.
- Unit and widget test suite covering the domain, data, validation, query, provider and UI layers.

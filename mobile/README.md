# Ticketly mobile

Flutter app for the Ticketly platform: voice-first search for train, bus,
launch and flight tickets in Bangladesh, with MFS/card checkout, bookings and
notifications.

## Run it

```bash
flutter pub get
flutter run                                # device/emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080   # Android emulator
```

The gateway has to be reachable first — `make up` (or `make dev`) from the
repository root starts it.

## Screens

| Screen | File | What it does |
|---|---|---|
| Splash | `lib/screens/splash_screen.dart` | Restores the stored session, then routes to login or home |
| Login / Register | `login_screen.dart`, `register_screen.dart` | Phone (or e-mail) + password against `POST /api/v1/auth/*` |
| Home shell | `home_screen.dart` | Tabs (search / bookings / profile) plus the notification bell |
| Search | inside `home_screen.dart` | Hold-to-talk voice query or the manual form, offers strip |
| Results | `results_screen.dart` | `POST /api/v1/search`, sorting, price breakdown sheet |
| Checkout | `booking_checkout_screen.dart` | Passenger, quantity, MFS/card, promo → `POST /api/v1/bookings` |
| My bookings | `my_bookings_screen.dart` | List, detail sheet, cancellation |
| Notifications | `notifications_screen.dart` | `GET /api/v1/notifications`, marks them read |
| Profile | `profile_screen.dart` | Account details and logout |

## Layout

```
lib/
├── config/      # base URL, theme, city list
├── models/      # JSON models for every backend payload
├── screens/     # one file per screen
├── services/    # ApiClient + one thin client per backend area
├── state/       # AppState (session, offers, notifications)
├── utils/       # tolerant JSON readers, Bengali formatting, helpers
└── widgets/     # reusable cards, chips, empty/error/loading views
```

## Checks

```bash
flutter analyze     # must report no issues (this is what CI runs)
flutter test        # model, pricing and formatting tests
```

Voice capture needs the microphone permission, declared in
`android/app/src/main/AndroidManifest.xml` (RECORD_AUDIO) and
`ios/Runner/Info.plist` (NSMicrophoneUsageDescription).

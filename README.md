# WildTrack AR — Flutter App
### Genting Nature Adventures

A fully native Android AR wildlife tracking game. Point your camera around,
discover Genting's 6 endangered species using your phone's gyroscope, capture
them in the viewfinder, and learn about conservation.

---

## How the AR works (the key mechanic you asked for)

When wildlife spawns, it is placed at a **random angular offset** from where
your camera is currently pointing — like it's hiding just off the edge of your
screen in the real world.

As you **physically pan/tilt your phone**, the gyroscope tracks your camera
direction and the animal moves on screen accordingly:
- Pan **right** → animal moves **left** (camera is looking away from it)
- Pan **left** → animal moves **right** (getting closer to it)
- Tilt **up/down** → animal moves vertically

When the animal's emoji enters the **green viewfinder box** in the centre of
the screen, the viewfinder turns **amber** and the SCAN button pulses.
Tap SCAN to capture it!

---

## Setup — Step by step

### Step 1 — Install Flutter

1. Go to **flutter.dev/docs/get-started/install/windows** (or macOS/Linux)
2. Download Flutter SDK, unzip it somewhere like `C:\flutter`
3. Add `C:\flutter\bin` to your system PATH
4. Open a terminal and run:
   ```
   flutter doctor
   ```
5. Fix any issues it shows (usually just Android SDK path)

### Step 2 — Install Android Studio

1. Download from **developer.android.com/studio**
2. During setup, install the Android SDK (API 33 or higher)
3. In Android Studio → SDK Manager → install "Android SDK Build-Tools"
4. Accept all licenses:
   ```
   flutter doctor --android-licenses
   ```

### Step 3 — Enable USB debugging on your Android phone

1. Go to **Settings → About Phone**
2. Tap **Build Number** 7 times to unlock Developer Options
3. Go to **Settings → Developer Options**
4. Enable **USB Debugging**
5. Plug your phone into your computer with a USB cable
6. Accept the "Allow USB Debugging" popup on your phone

### Step 4 — Run the app

Open a terminal in the `wildtrack_ar` folder and run:

```bash
# Get all dependencies
flutter pub get

# Check your phone is detected
flutter devices

# Run on your phone (it will install and launch automatically)
flutter run
```

The first run takes 2–3 minutes to compile. After that it's instant with
hot-reload (`r` key in terminal to reload, `R` to full restart).

### Step 5 — Build a release APK (to share with others)

```bash
flutter build apk --release
```

The APK will be at:
`build/app/outputs/flutter-apk/app-release.apk`

Send this file to anyone — they can install it directly on Android
(they need "Install from unknown sources" enabled in settings).

---

## Project structure

```
wildtrack_ar/
├── lib/
│   ├── main.dart                    ← App entry, routing
│   ├── game/
│   │   └── game_controller.dart     ← Gyro tracking, motion detection,
│   │                                   wildlife spawn, targeting logic
│   ├── models/
│   │   └── species.dart             ← All 6 Genting species data
│   ├── screens/
│   │   ├── splash_screen.dart       ← Loading screen
│   │   ├── permission_screen.dart   ← Camera permission + tutorial
│   │   └── ar_game_screen.dart      ← Main AR view (camera + HUD + sprites)
│   └── widgets/
│       ├── ar_viewfinder.dart       ← Green/amber viewfinder box
│       ├── wildlife_sprite.dart     ← Floating emoji + label
│       └── species_modal.dart       ← Discovery popup with facts
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml      ← Camera + vibration permissions
└── pubspec.yaml                     ← Dependencies
```

---

## Dependencies used

| Package | Purpose |
|---|---|
| `camera` | Live camera feed |
| `sensors_plus` | Gyroscope for AR tracking |
| `flutter_animate` | Smooth pop-in / float animations |
| `share_plus` | Native Android share sheet |
| `vibration` | Haptic feedback on scan |
| `shared_preferences` | Save discovered species & points |
| `provider` | State management |

---

## Troubleshooting

**`flutter doctor` shows Android SDK not found**
→ Open Android Studio → SDK Manager → copy the SDK path → run:
`flutter config --android-sdk "C:\path\to\sdk"`

**Phone not detected**
→ Try a different USB cable (some cables are charge-only)
→ Check Device Manager on Windows for driver issues

**Camera shows black screen**
→ Make sure you tapped "Allow" when the camera permission popup appeared
→ Force-stop the app, open Android Settings → Apps → WildTrack AR → Permissions → Allow Camera

**`sensors_plus` not detecting motion**
→ Some emulators don't have gyroscopes — always test on a real Android phone

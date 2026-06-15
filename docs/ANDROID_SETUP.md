# Android Studio Setup (Windows)

Your machine has Flutter installed at `C:\flutter` but **no Android SDK yet**. Follow these steps to build and run the Khade app on a phone or emulator.

## 1. Install Android Studio

1. Download from [developer.android.com/studio](https://developer.android.com/studio)
2. Run the installer — keep defaults checked:
   - Android SDK
   - Android SDK Platform
   - Android Virtual Device (AVD)
3. Launch Android Studio → **More Actions → SDK Manager**
4. Under **SDK Platforms**, install **Android 14 (API 34)** or latest stable
5. Under **SDK Tools**, ensure these are checked:
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android Emulator
   - Android SDK Platform-Tools

Default SDK location: `%LOCALAPPDATA%\Android\Sdk`

## 2. Configure environment variables

After SDK install, run this in PowerShell **as your user** (from the project root):

```powershell
.\scripts\setup-android-env.ps1
```

Or set manually:

| Variable | Value |
|----------|-------|
| `ANDROID_HOME` | `C:\Users\<you>\AppData\Local\Android\Sdk` |
| Path (append) | `%ANDROID_HOME%\platform-tools` |
| Path (append) | `%ANDROID_HOME%\cmdline-tools\latest\bin` |

Restart your terminal after setting variables.

## 3. Point Flutter at the SDK

```powershell
flutter config --android-sdk "$env:LOCALAPPDATA\Android\Sdk"
flutter doctor --android-licenses   # type 'y' to accept all
flutter doctor
```

You want `[√] Android toolchain` with no errors.

## 4. Add Flutter to PATH (recommended)

Append `C:\flutter\bin` to your user **Path** so you can run `flutter` from any terminal.

## 5. Create an emulator (optional)

Android Studio → **Device Manager → Create Device** → pick Pixel 7 → API 34 image → Finish.

## 6. Run Khade on device

```powershell
cd khade_app
flutter pub get
flutter devices          # list phone/emulator
flutter run              # pick Android device
```

**Physical phone:** Enable **Developer options → USB debugging**, connect via USB, accept the trust prompt.

## 7. Build release APK

```powershell
cd khade_app
flutter build apk --release
```

Output: `khade_app\build\app\outputs\flutter-apk\app-release.apk`

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `No Android SDK found` | Run `setup-android-env.ps1`, restart terminal |
| `cmdline-tools not found` | SDK Manager → SDK Tools → Android SDK Command-line Tools |
| `Gradle build failed` | Open `khade_app/android` in Android Studio once to sync Gradle |
| Phone not listed | Install OEM USB driver; try `adb devices` |
| Slow emulator | Use a physical device or enable hardware acceleration in BIOS |

## Quick verify checklist

```powershell
flutter doctor -v
adb devices
cd khade_app && flutter run -d chrome   # works now without Android SDK
cd khade_app && flutter run             # works after SDK setup
```

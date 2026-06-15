# Configures ANDROID_HOME and PATH for Flutter Android builds on Windows.
# Run after installing Android Studio + SDK.
# Usage:  .\scripts\setup-android-env.ps1

$SdkPath = Join-Path $env:LOCALAPPDATA "Android\Sdk"

if (-not (Test-Path $SdkPath)) {
    Write-Host "Android SDK not found at: $SdkPath" -ForegroundColor Red
    Write-Host "Install Android Studio first: https://developer.android.com/studio"
    Write-Host "Then open SDK Manager and install Android SDK Platform + Platform-Tools."
    exit 1
}

Write-Host "Found Android SDK at: $SdkPath" -ForegroundColor Green

# Set user-level environment variables (persists across sessions)
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $SdkPath, "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $SdkPath, "User")

$pathsToAdd = @(
    "$SdkPath\platform-tools",
    "$SdkPath\emulator",
    "$SdkPath\cmdline-tools\latest\bin"
)

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
foreach ($p in $pathsToAdd) {
    if ((Test-Path $p) -and ($userPath -notlike "*$p*")) {
        $userPath = "$userPath;$p"
        Write-Host "Added to PATH: $p"
    } elseif (-not (Test-Path $p)) {
        Write-Host "Skipped (not installed yet): $p" -ForegroundColor Yellow
    }
}
[Environment]::SetEnvironmentVariable("Path", $userPath, "User")

# Add Flutter to PATH if missing
$flutterBin = "C:\flutter\bin"
if ((Test-Path $flutterBin) -and ($userPath -notlike "*$flutterBin*")) {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$flutterBin", "User")
    Write-Host "Added Flutter to PATH: $flutterBin"
}

# Apply to current session
$env:ANDROID_HOME = $SdkPath
$env:ANDROID_SDK_ROOT = $SdkPath
$env:Path = "$env:Path;$SdkPath\platform-tools;C:\flutter\bin"

Write-Host ""
Write-Host "Done. Restart your terminal, then run:" -ForegroundColor Cyan
Write-Host "  flutter config --android-sdk `"$SdkPath`""
Write-Host "  flutter doctor --android-licenses"
Write-Host "  flutter doctor"
Write-Host "  cd khade_app && flutter run"

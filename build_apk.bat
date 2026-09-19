@echo off
setlocal
echo === Akilog: preparando projeto Flutter ===
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter nao foi encontrado no PATH.
  echo Instale o Flutter SDK e o Android Studio primeiro.
  pause
  exit /b 1
)
flutter create .
if errorlevel 1 exit /b 1
flutter pub get
if errorlevel 1 exit /b 1
flutter build apk --release
if errorlevel 1 exit /b 1
echo.
echo APK gerado em:
echo build\app\outputs\flutter-apk\app-release.apk
pause

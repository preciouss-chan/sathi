@echo off
echo ============================================
echo Installing ffmpeg using winget...
echo ============================================
echo.

winget install ffmpeg

if %errorlevel% equ 0 (
    echo.
    echo ============================================
    echo ffmpeg installed successfully!
    echo ============================================
    echo.
    echo IMPORTANT: Close and reopen your terminal for the changes to take effect.
    echo Then run 'setup.bat' again to verify installation.
) else (
    echo.
    echo ============================================
    echo Failed to install ffmpeg with winget.
    echo ============================================
    echo.
    echo Please install manually:
    echo 1. Download from: https://www.gyan.dev/ffmpeg/builds/
    echo 2. Extract the zip file
    echo 3. Add the 'bin' folder to your Windows PATH
    echo 4. Restart your terminal
)
echo.
pause

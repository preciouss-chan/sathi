@echo off
echo ============================================
echo Mental Health Voice Analysis - Setup
echo ============================================
echo.

echo Step 1: Installing Python dependencies...
C:\Users\aarjan\AppData\Local\Programs\Python\Python313\python.exe -m pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo ERROR: Failed to install Python dependencies
    pause
    exit /b 1
)
echo.

echo Step 2: Checking for ffmpeg...
ffmpeg -version >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNING: ffmpeg is not installed!
    echo.
    echo Please install ffmpeg using ONE of these methods:
    echo.
    echo Option 1 - Using winget (recommended):
    echo    winget install ffmpeg
    echo.
    echo Option 2 - Manual download:
    echo    1. Download from: https://www.gyan.dev/ffmpeg/builds/
    echo    2. Extract the zip file
    echo    3. Add the 'bin' folder to your PATH
    echo.
    echo After installing ffmpeg, run this setup again.
    pause
    exit /b 1
) else (
    echo ffmpeg is installed! ✓
)
echo.

echo Step 3: Creating .env file...
if not exist .env (
    copy .env.example .env
    echo .env file created! Please edit it and add your OpenAI API key.
) else (
    echo .env file already exists.
)
echo.

echo ============================================
echo Setup Complete!
echo ============================================
echo.
echo Next steps:
echo 1. Edit .env and add your OpenAI API key
echo 2. Run: python main.py
echo 3. Open: http://localhost:8000/docs
echo.
pause

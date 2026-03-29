# COMPLETE SETUP GUIDE - Mental Health Voice Analysis API

## Step 1: Install Google Gemini Package

Run this command:
```
C:\Users\aarjan\AppData\Local\Programs\Python\Python313\python.exe -m pip install google-generativeai
```

## Step 2: Get Your FREE Google Gemini API Key

1. Go to: https://aistudio.google.com/apikey
2. Sign in with your Google account
3. Click "Create API key"
4. Copy the API key (starts with "AIza...")

## Step 3: Add API Key to .env File

Open the `.env` file in the transcribe folder with Notepad.

Replace this line:
```
GOOGLE_API_KEY=your_google_gemini_api_key_here
```

With your actual key:
```
GOOGLE_API_KEY=AIzaSyAbc123YourActualKeyHere...
```

Save and close the file.

## Step 4: Run the Server

Run this command:
```
C:\Users\aarjan\AppData\Local\Programs\Python\Python313\python.exe main.py
```

You should see:
```
INFO:__main__:ffmpeg is available
INFO:__main__:Loading Whisper model...
INFO:__main__:Whisper model loaded successfully
INFO:     Uvicorn running on http://0.0.0.0:8000
```

## Step 5: Test It

1. Open your browser
2. Go to: http://localhost:8000/docs
3. Click on "POST /analyze-voice"
4. Click "Try it out"
5. Upload your M4A audio file
6. Click "Execute"

You should get a response like:
```json
{
  "transcription": "I am feeling anxious...",
  "emotion": "anxious",
  "mental_health_score": 4,
  "detected_language": "en",
  "mood": "Anxious but aware",
  "energy": "Heavy",
  "summary": "Your reflection suggests noticeable anxiety and some emotional strain right now.",
  "suggestion": "Take one small grounding step today: water, rest, a short walk, or a message to someone safe.",
  "safety": "gentle-check-in",
  "share_title": "A friendly update",
  "share_body": "Today's reflection carries anxiety and some strain, but there are still signs of resilience.",
  "share_footer": "Only share this if it feels right for you."
}
```

## Troubleshooting

**Problem:** "ModuleNotFoundError: No module named 'google'"
**Solution:** Run step 1 again to install google-generativeai

**Problem:** "Error analyzing with Gemini: 401"
**Solution:** Your API key is wrong. Check step 2 and 3 again.

**Problem:** "ffmpeg not found"
**Solution:** Close PowerShell completely, open a new one, then try again.

## THAT'S IT!

Your mental health voice analysis API is ready to use with your Flutter app!

The endpoint is: POST http://localhost:8000/analyze-voice

It accepts audio files and returns:
- transcription (what was said)
- emotion (single word)
- mental_health_score (1-10)
- mood, energy, summary, suggestion, safety, and share-card text for the Flutter app

## Cost: 100% FREE! 
Gemini has a generous free tier - 60 requests per minute!

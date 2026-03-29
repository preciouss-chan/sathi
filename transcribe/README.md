# Mental Health Voice Analysis API

A FastAPI-based backend that transcribes voice input in real-time and analyzes mental health status using OpenAI Whisper and **Google Gemini** (FREE!).

## Features

- **Voice Transcription**: Uses OpenAI Whisper for accurate speech-to-text conversion
- **Emotion Detection**: Identifies user's current emotional state with a single word
- **Mental Health Scoring**: Provides a 1-10 score indicating mental health status
- **FREE AI Analysis**: Uses Google Gemini API (free tier available!)
- **REST API**: Easy integration with Flutter or any HTTP client

## Quick Setup (Automated)

### Run the setup script:

```bash
.\setup.bat
```

This will:
1. Install all Python dependencies
2. Check if ffmpeg is installed
3. Create your .env file

### If ffmpeg is missing:

```bash
.\install_ffmpeg.bat
```

Then **close and reopen your terminal** and run `.\setup.bat` again.

## Manual Setup

### 1. Install ffmpeg (REQUIRED)

**Option A - Using winget (easiest):**
```bash
winget install ffmpeg
```

**Option B - Manual download:**
1. Download from: https://www.gyan.dev/ffmpeg/builds/
2. Extract the zip file
3. Add the `bin` folder to your Windows PATH
4. Restart your terminal

### 2. Install Python Dependencies

```bash
C:\Users\aarjan\AppData\Local\Programs\Python\Python313\python.exe -m pip install -r requirements.txt
```

### 3. Configure Google Gemini API Key (FREE!)

**Get your FREE API key:**
1. Go to: https://aistudio.google.com/apikey
2. Click "Create API key"
3. Copy the key

**Add to .env file:**
Create a `.env` file:
```bash
copy .env.example .env
```

Edit `.env` and add your Google API key:
```
GOOGLE_API_KEY=your-actual-gemini-api-key-here
```

### 4. Run the Server

```bash
python main.py
```

The API will be available at `http://localhost:8000`

## Testing the API

### Option 1: Interactive Swagger Docs (Easiest)

1. Go to: **http://localhost:8000/docs**
2. Click on **POST /analyze-voice**
3. Click **"Try it out"**
4. Click **"Choose File"** and upload an audio file (M4A, MP3, WAV, etc.)
5. Click **"Execute"**
6. See the transcription, emotion, and mental health score!

### Option 2: Using curl

```bash
curl -X POST "http://localhost:8000/analyze-voice" -F "audio=@your_audio.m4a"
```

## API Documentation

### POST /analyze-voice

Analyzes voice input and returns transcription, emotion, and mental health score.

**Request:**
- Method: `POST`
- Content-Type: `multipart/form-data`
- Body: Audio file (supported: WAV, MP3, M4A, FLAC, OGG, etc.)

**Response:**
```json
{
  "transcription": "I've been feeling really stressed lately with work...",
  "emotion": "anxious",
  "mental_health_score": 5
}
```

**Mental Health Score Guide:**
- **1-3**: User needs mental help ASAP (severe distress, crisis situation)
- **4-5**: Significant mental health concerns (moderate depression, high stress)
- **6-7**: Some challenges but managing (occasional stress, minor worries)
- **8-10**: Doing well mentally (positive, balanced, healthy mindset)

## Flutter Integration Example

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

Future<Map<String, dynamic>> analyzeVoice(File audioFile) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://localhost:8000/analyze-voice'),
  );
  
  request.files.add(
    await http.MultipartFile.fromPath('audio', audioFile.path),
  );
  
  var response = await request.send();
  var responseData = await response.stream.bytesToString();
  
  return json.decode(responseData);
}

// Usage
void main() async {
  File audioFile = File('path/to/recording.m4a');
  var result = await analyzeVoice(audioFile);
  
  print('Transcription: ${result['transcription']}');
  print('Emotion: ${result['emotion']}');
  print('Mental Health Score: ${result['mental_health_score']}/10');
}
```

## Troubleshooting

### Error: "ffmpeg is not installed"

**Solution:** Install ffmpeg using one of the methods above, then restart your terminal.

### Error: "ModuleNotFoundError"

**Solution:** Make sure you're using the correct Python:
```bash
C:\Users\aarjan\AppData\Local\Programs\Python\Python313\python.exe -m pip install -r requirements.txt
```

### Error: "No module named 'fastapi'"

**Solution:** The dependencies aren't installed for the Python you're using. Run the setup script or install manually.

### Server runs but transcription fails

**Solution:** This usually means ffmpeg isn't in your PATH. Install it and restart your terminal.

## Requirements

- **Python 3.8+**
- **ffmpeg** (for audio processing)
- **OpenAI API key**
- At least 2GB RAM (for Whisper model)

## Notes

- First run will download the Whisper model (~140MB for base model)
- For better accuracy, edit `main.py` and change `whisper.load_model("base")` to `"medium"` or `"large"`
- For production, restrict CORS origins to your Flutter app's domain
- Consider rate limiting for production deployments
- The API processes one request at a time for optimal performance

## Project Structure

```
transcribe/
├── main.py              # Main API server
├── requirements.txt     # Python dependencies
├── .env.example        # Environment variables template
├── .env                # Your API keys (create this)
├── setup.bat           # Automated setup script
├── install_ffmpeg.bat  # ffmpeg installer
├── temp_audio/         # Temporary audio storage (auto-created)
└── README.md           # This file
```

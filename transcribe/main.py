from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import whisper
import google.generativeai as genai
import os
from dotenv import load_dotenv
import tempfile
import logging
import subprocess
import sys
from pathlib import Path

# Fix PATH for ffmpeg on Windows
if sys.platform == 'win32':
    import winreg
    try:
        # Get system PATH
        with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r'SYSTEM\CurrentControlSet\Control\Session Manager\Environment') as key:
            system_path = winreg.QueryValueEx(key, 'Path')[0]
        # Get user PATH
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, r'Environment') as key:
            user_path = winreg.QueryValueEx(key, 'Path')[0]
        # Update current process PATH
        os.environ['PATH'] = system_path + ';' + user_path + ';' + os.environ.get('PATH', '')
    except Exception as e:
        logging.warning(f"Could not update PATH from registry: {e}")

# Load environment variables
load_dotenv()
google_api_key = os.getenv("GOOGLE_API_KEY")
if google_api_key:
    genai.configure(api_key=google_api_key)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def check_ffmpeg():
    """Check if ffmpeg is available"""
    try:
        subprocess.run(['ffmpeg', '-version'], 
                      stdout=subprocess.PIPE, 
                      stderr=subprocess.PIPE, 
                      check=True)
        logger.info("ffmpeg is available")
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        logger.warning("ffmpeg not found in PATH")
        return False


# Check ffmpeg on startup
if not check_ffmpeg():
    logger.warning("=" * 60)
    logger.warning("WARNING: ffmpeg not found!")
    logger.warning("Installing ffmpeg-python package...")
    logger.warning("If issues persist, install ffmpeg manually:")
    logger.warning("Download from: https://www.gyan.dev/ffmpeg/builds/")
    logger.warning("Or run: winget install ffmpeg")
    logger.warning("=" * 60)

app = FastAPI(title="Mental Health Voice Analysis API")

# CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load Whisper model (using base model for balance of speed and accuracy)
logger.info("Loading Whisper model...")
whisper_model = whisper.load_model("base")
logger.info("Whisper model loaded successfully")


class AnalysisResponse(BaseModel):
    transcription: str
    emotion: str
    mental_health_score: int
    detected_language: str  # New field to show what language was detected


@app.get("/")
async def root():
    return {"message": "Mental Health Voice Analysis API is running"}


@app.post("/analyze-voice", response_model=AnalysisResponse)
async def analyze_voice(audio: UploadFile = File(...)):
    """
    Accepts an audio file, transcribes it using Whisper,
    and analyzes it using FREE Gemini for emotion and mental health score.
    """
    temp_audio_path = None
    try:
        # Get file extension from uploaded file
        file_extension = os.path.splitext(audio.filename)[1] or ".wav"
        
        # Read audio content
        content = await audio.read()
        
        # Create a proper temp directory if it doesn't exist
        temp_dir = os.path.join(os.getcwd(), "temp_audio")
        os.makedirs(temp_dir, exist_ok=True)
        
        # Save with a simple filename
        import time
        temp_audio_path = os.path.join(temp_dir, f"audio_{int(time.time())}{file_extension}")
        
        with open(temp_audio_path, 'wb') as f:
            f.write(content)
        
        logger.info(f"Processing audio file: {audio.filename}")
        logger.info(f"Temp file path: {temp_audio_path}")
        logger.info(f"File exists: {os.path.exists(temp_audio_path)}")
        logger.info(f"File size: {os.path.getsize(temp_audio_path)} bytes")
        
        # Transcribe audio using Whisper with AUTO language detection
        logger.info("Transcribing audio with auto language detection...")
        try:
            result = whisper_model.transcribe(
                temp_audio_path, 
                fp16=False,
                verbose=True
                # No language parameter = auto-detect!
            )
            transcription = result["text"]
            detected_language = result.get("language", "unknown")
            logger.info(f"Detected language: {detected_language}")
            logger.info(f"Transcription: {transcription}")
        except Exception as whisper_error:
            logger.error(f"Whisper transcription error: {str(whisper_error)}")
            logger.error(f"Error type: {type(whisper_error).__name__}")
            
            # Check if it's an ffmpeg issue
            if "ffmpeg" in str(whisper_error).lower() or isinstance(whisper_error, FileNotFoundError):
                raise HTTPException(
                    status_code=500, 
                    detail="ffmpeg is not installed or not in PATH. Please install ffmpeg: https://www.gyan.dev/ffmpeg/builds/ or run 'winget install ffmpeg'"
                )
            raise
        
        # Clean up temp file
        if temp_audio_path and os.path.exists(temp_audio_path):
            os.unlink(temp_audio_path)
        
        if not transcription.strip():
            raise HTTPException(status_code=400, detail="No speech detected in audio")
        
        # Analyze with FREE Gemini (supports multiple languages including Nepali!)
        logger.info(f"Analyzing with Gemini (FREE tier) - Language: {detected_language}...")
        analysis = await analyze_with_gemini(transcription, detected_language)
        
        return AnalysisResponse(
            transcription=transcription,
            emotion=analysis["emotion"],
            mental_health_score=analysis["score"],
            detected_language=detected_language
        )
    
    except Exception as e:
        logger.error(f"Error processing audio: {str(e)}")
        # Clean up temp file on error
        if temp_audio_path and os.path.exists(temp_audio_path):
            try:
                os.unlink(temp_audio_path)
            except:
                pass
        raise HTTPException(status_code=500, detail=str(e))


async def analyze_with_gemini(text: str, language: str = "en") -> dict:
    """
    Analyzes transcribed text using FREE Gemini API.
    Supports multiple languages including English and Nepali.
    """
    try:
        # List available models and use the first one
        logger.info("Checking available Gemini models...")
        available_models = []
        try:
            for m in genai.list_models():
                if 'generateContent' in m.supported_generation_methods:
                    available_models.append(m.name)
                    logger.info(f"Available model: {m.name}")
        except Exception as list_error:
            logger.error(f"Could not list models: {list_error}")
        
        # Try different model names in order of preference
        model_names = [
            'models/gemini-1.5-flash',
            'models/gemini-1.5-pro', 
            'models/gemini-pro',
            'gemini-1.5-flash',
            'gemini-1.5-pro',
            'gemini-pro'
        ]
        
        # Add any available models we found
        model_names.extend(available_models)
        
        # Adjust prompt based on language
        if language == "ne":  # Nepali
            prompt = f"""यो मानसिक स्वास्थ्य पाठको विश्लेषण गर्नुहोस् र केवल JSON वस्तु फिर्ता गर्नुहोस्:
{{"emotion": "शब्द", "score": संख्या}}

जहाँ emotion एउटा शब्द हो (खुशी/दुःखी/चिन्तित/निराश/तनाव/शान्त/रिसाएको/आशावादी) र score 1-10 हो:
- 1-3: तुरुन्त मद्दत चाहिन्छ
- 4-5: महत्वपूर्ण समस्याहरू
- 6-7: चुनौतीहरू तर व्यवस्थापन गर्दै
- 8-10: राम्रो छ

पाठ: {text}"""
        else:  # English and other languages
            prompt = f"""Analyze this mental health text and respond with ONLY a JSON object:
{{"emotion": "word", "score": number}}

Where emotion is ONE word (happy/sad/anxious/depressed/stressed/calm/angry/hopeful) and score is 1-10:
- 1-3: Needs urgent help
- 4-5: Struggling significantly  
- 6-7: Managing with challenges
- 8-10: Doing well

Text: {text}
Language detected: {language}"""
        
        model = None
        last_error = None
        
        for model_name in model_names:
            try:
                logger.info(f"Trying model: {model_name}")
                model = genai.GenerativeModel(model_name)
                
                response = model.generate_content(prompt)
                content = response.text.strip()
                logger.info(f"SUCCESS with {model_name}! Response: {content}")
                
                # Parse JSON response
                import json
                # Clean up response
                if '```' in content:
                    parts = content.split('```')
                    for part in parts:
                        part = part.strip()
                        if part.startswith('json'):
                            part = part[4:].strip()
                        if '{' in part and '}' in part:
                            content = part[part.index('{'):part.rindex('}')+1]
                            break
                
                content = content.strip()
                result = json.loads(content)
                
                # Validate
                if "emotion" not in result or "score" not in result:
                    raise ValueError("Invalid response format")
                
                score = int(result["score"])
                if score < 1 or score > 10:
                    score = 5  # Default to neutral
                
                return {
                    "emotion": result["emotion"].lower(),
                    "score": score
                }
                
            except Exception as e:
                last_error = str(e)
                logger.warning(f"Model {model_name} failed: {e}")
                continue
        
        # If we get here, all models failed
        raise Exception(f"No working Gemini models found. Last error: {last_error}. Your API key might not be activated for Gemini API. Please visit https://aistudio.google.com/app/apikey to check your API key status.")
    
    except Exception as e:
        logger.error(f"Gemini error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"AI analysis failed: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

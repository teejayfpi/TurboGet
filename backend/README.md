# TurboGet Backend Server

A comprehensive backend server for TurboGet app that supports:
- YouTube video downloads
- General file downloads from any URL
- File type detection
- Multiple quality options for video downloads

## Features

### Supported Platforms
- YouTube (youtube.com, youtu.be)
- Vimeo
- Dailymotion
- Twitter/X
- Instagram
- Facebook
- TikTok
- SoundCloud
- And 50+ other platforms via yt-dlp

### Supported File Types
- **Video**: mp4, mkv, avi, mov, wmv, flv, webm, m4v, 3gp
- **Audio**: mp3, wav, flac, aac, ogg, m4a, wma, opus
- **Images**: jpg, png, gif, bmp, webp, svg
- **Documents**: pdf, doc, docx, xls, xlsx, ppt, pptx, txt, rtf
- **Archives**: zip, rar, 7z, tar, gz, bz2
- **Software**: exe, msi, dmg, apk, deb, rpm
- **Code**: py, js, java, cpp, c, h, php, rb, go, rs

## Quick Start

### Option 1: Docker (Recommended)

```bash
cd backend
docker-compose up -d
```

### Option 2: Python Virtual Environment

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

### Option 3: Direct Python

```bash
cd backend
pip install -r requirements.txt
python main.py
```

The server will start at `http://localhost:8000`

## API Endpoints

### Health Check
```
GET /health
```

### Detect File Type
```bash
POST /api/detect?url=https://example.com/file.pdf
```

### Download General File
```bash
POST /api/download?url=https://example.com/file.pdf
```

### Get Video Information
```bash
POST /api/video/info?url=https://youtube.com/watch?v=xxx
```

### Download YouTube Video
```bash
POST /api/video/download?url=https://youtube.com/watch?v=xxx&quality=720p
```

Quality options: `best`, `1080p`, `720p`, `480p`, `audio`

### Check Download Progress
```bash
GET /api/progress/{download_id}
```

### List Downloads
```bash
GET /api/downloads
```

### Get Supported Platforms
```bash
GET /api/supported-platforms
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| PORT | 8000 | Server port |
| DOWNLOAD_DIR | ./downloads | Download storage directory |
| TEMP_DIR | ./temp | Temporary file storage |

## Using with Flutter App

Update your Flutter app's settings to point to your backend URL:

1. Open the app
2. Go to Settings
3. Find "Server URL" or "Backend URL"
4. Enter your server address (e.g., `http://your-server-ip:8000`)

## Deployment

### Deploy to Railway
1. Connect your GitHub repo
2. Railway will auto-detect Docker
3. Set environment variables if needed
4. Deploy!

### Deploy to Render
1. Create Web Service
2. Connect GitHub repo
3. Set build command: `pip install -r requirements.txt`
4. Set start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`

### Deploy to VPS
```bash
# SSH into your VPS
git clone <your-repo>
cd TurboGet/backend
docker-compose up -d
```

## API Documentation

Interactive API docs available at:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## License

MIT License

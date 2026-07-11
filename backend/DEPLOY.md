# 🚀 TurboGet Backend Deployment Guide

## Built & Designed by Olatunji Ayobami Ayanlowo
### Contact: +2347038193753

This guide will help you deploy the TurboGet backend server to Render.

---

## ⚠️ IMPORTANT: Render Free Tier Limitation

Render requires payment information to create new services. If you haven't added a card:
1. Go to https://dashboard.render.com/billing
2. Add your payment method
3. Then follow the deployment steps below

---

## 📋 Prerequisites

- GitHub account connected to Render
- Render account (free tier works)
- Payment method added to Render (required for new services)

---

## 🎯 Deployment Steps (Option 1: Manual)

### Step 1: Connect GitHub to Render
1. Go to https://dashboard.render.com
2. Click "New +" → "Blueprint"
3. Connect your GitHub account if not already connected
4. Select the `teejayfpi/TurboGet` repository
5. Set the root directory to `backend`

### Step 2: Configure the Service
1. **Name**: `turboget-server`
2. **Environment**: Python
3. **Region**: Oregon (or closest to you)
4. **Branch**: `main`
5. **Root Directory**: `backend`

### Step 3: Set Build Command
```
pip install -r requirements.txt
```

### Step 4: Set Start Command
```
uvicorn main:app --host 0.0.0.0 --port $PORT
```

### Step 5: Add Environment Variables (Optional)
- `PYTHON_VERSION`: `3.11`

### Step 6: Create Service
Click "Create Blueprint" to deploy.

---

## 🎯 Deployment Steps (Option 2: Direct Create)

### Step 1: Create New Web Service
1. Go to https://dashboard.render.com
2. Click "New +" → "Web Service"
3. Connect GitHub repo: `teejayfpi/TurboGet`
4. Configure:
   - **Name**: `turboget-server`
   - **Region**: Oregon
   - **Branch**: `main`
   - **Root Directory**: `backend`
   - **Environment**: Python 3.11
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`

### Step 2: Deploy
Click "Create Web Service" and wait for deployment.

---

## 🎯 Deployment Steps (Option 3: One-Click Deploy)

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

1. Click the button above
2. Connect your GitHub repo
3. Set root directory to `backend`
4. Click "Deploy"

---

## 🐳 Alternative: Docker Deployment

If you prefer Docker, use the included Dockerfile:

### Build Docker Image
```bash
docker build -t turboget-server ./backend
```

### Run Container
```bash
docker run -p 8000:8000 turboget-server
```

### Docker Compose
```bash
cd backend
docker-compose up -d
```

---

## 📱 Configure Flutter App

Once your server is deployed, update the app settings:

1. Open TurboGet app
2. Go to Settings
3. Find "Server URL"
4. Enter your Render server URL (e.g., `https://turboget-server.onrender.com`)
5. Save

---

## ✅ Verify Deployment

Test your server:
```bash
curl https://YOUR-SERVER-URL.onrender.com/health
```

Should return:
```json
{"status": "healthy"}
```

---

## 🔧 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| POST | `/api/detect` | Detect file type from URL |
| POST | `/api/download` | Download any file |
| POST | `/api/video/info` | Get video info (YouTube, etc.) |
| POST | `/api/video/download` | Download video |
| GET | `/api/progress/{id}` | Get download progress |
| GET | `/api/downloads` | List downloads |
| GET | `/api/supported-platforms` | List supported platforms |

---

## 🌐 Supported Streaming Platforms (100+)

### Major Platforms
- YouTube, YouTube Shorts
- Facebook, Instagram
- Twitter/X, TikTok
- Vimeo, Dailymotion

### Music/Audio
- SoundCloud, Bandcamp
- Spotify, Deezer
- Apple Music

### Video Platforms
- Twitch, Reddit
- VK, OK.ru
- Bilibili

### More...
- And 80+ other platforms via yt-dlp!

---

## ⚡ Speed Optimization

The backend is configured for maximum speed:
- Multi-threaded downloads
- Connection pooling
- Async I/O
- Progress tracking

For even faster speeds on Render:
1. Upgrade to Render Starter or Pro plan
2. Enable auto-scaling
3. Use multiple instances

---

## 📞 Support

For questions or issues:
- **Developer**: Olatunji Ayobami Ayanlowo
- **Phone**: +2347038193753
- **WhatsApp**: https://wa.me/2347038193753
- **Email**: ayanlowo89@gmail.com

---

## 📄 License

MIT License - Built with ❤️ by Olatunji Ayobami Ayanlowo

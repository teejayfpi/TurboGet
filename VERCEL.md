# 🚀 TurboGet Backend - Vercel Deployment

## ⚠️ Important: Vercel Limitations for Video Downloads

Vercel is **not ideal** for video/file downloading because:

1. **10MB Response Limit** - Vercel serverless functions have a 10MB response limit
2. **No Background Processing** - Downloads require long-running processes
3. **No Persistent Storage** - Downloads need storage for large files
4. **yt-dlp Not Supported** - Complex Python dependencies may fail

---

## ✅ Better Alternatives for Video Downloads

### Option 1: Railway (Recommended for Video)
- **Pros**: No response limit, persistent storage, easy Python deployment
- **Free Tier**: 512MB RAM, 10GB disk
- **Website**: https://railway.app

### Option 2: Render (Already Set Up)
- **Pros**: Already configured with `render.yaml`
- **Note**: Requires payment info for new services

### Option 3: DigitalOcean App Platform
- **Pros**: $5/month starter, no response limits
- **Website**: https://digitalocean.com

### Option 4: VPS (DigitalOcean, Linode, Vultr)
- **Pros**: Full control, unlimited downloads
- **Cost**: $4-6/month

---

## 🔧 If You Still Want Vercel

### What's Working on Vercel:
The API endpoints for **detection** and **metadata** work great:

| Endpoint | Method | Works on Vercel |
|----------|--------|-----------------|
| `/api/health` | GET | ✅ Yes |
| `/api/detect` | POST | ✅ Yes |
| `/api/platforms` | GET | ✅ Yes |
| `/api/download` | POST | ⚠️ Limited* |

*Limited: Only returns metadata, not actual files

### Deploy to Vercel:

```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy
cd TurboGet
vercel

# Follow prompts:
# - Set up and deploy? Yes
# - Which scope? Select your account
# - Link to existing project? No
# - Project name? turboget
# - Directory? ./
# - Override settings? No
```

---

## 📱 For TurboGet App to Work

The app needs a **backend server** that can:
1. Download large files
2. Process YouTube/Facebook videos with yt-dlp
3. Store files temporarily
4. Stream files to the app

**Vercel cannot do this.** Use Railway or Render instead.

---

## 🎯 Recommended Setup

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────┐
│   Flutter   │────▶│  Vercel API     │────▶│  Railway    │
│     App     │     │  (Detection)     │     │  (Download) │
└─────────────┘     └──────────────────┘     └─────────────┘
```

**Recommended:**
1. Deploy **Vercel API** for detection (this)
2. Deploy **Railway/Backend** for actual downloads (from `backend/` folder)

---

## 📞 Support

**Developer**: Olatunji Ayobami Ayanlowo
**Phone**: +2347038193753
**WhatsApp**: https://wa.me/2347038193753

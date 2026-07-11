"""
TurboGet Backend API - Vercel Serverless Functions
Built & Designed by Olatunji Ayobami Ayanlowo
Contact: +2347038193753

Supports: YouTube, Facebook, Instagram, TikTok, and all streaming platforms
"""

import json
import uuid
from urllib.parse import urlparse

# Supported video platforms
VIDEO_PLATFORMS = {
    'youtube.com': 'YouTube',
    'youtu.be': 'YouTube',
    'facebook.com': 'Facebook',
    'fb.com': 'Facebook',
    'fb.watch': 'Facebook',
    'instagram.com': 'Instagram',
    'instagr.am': 'Instagram',
    'twitter.com': 'Twitter',
    'x.com': 'X (Twitter)',
    'tiktok.com': 'TikTok',
    'vm.tiktok.com': 'TikTok',
    'vimeo.com': 'Vimeo',
    'dailymotion.com': 'Dailymotion',
    'twitch.tv': 'Twitch',
    'reddit.com': 'Reddit',
    'soundcloud.com': 'SoundCloud',
    'bandcamp.com': 'Bandcamp',
    'bilibili.com': 'Bilibili',
    'vk.com': 'VK',
    'ok.ru': 'OK',
}

# File extensions by type
FILE_TYPES = {
    'video': ['.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.3gp'],
    'audio': ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a', '.wma', '.opus'],
    'image': ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg', '.ico'],
    'document': ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.rtf'],
    'archive': ['.zip', '.rar', '.7z', '.tar', '.gz', '.bz2'],
    'software': ['.exe', '.msi', '.dmg', '.pkg', '.deb', '.rpm', '.apk'],
}


def detect_platform(url):
    """Detect video platform from URL"""
    parsed = urlparse(url.lower())
    for platform, name in VIDEO_PLATFORMS.items():
        if platform in parsed.netloc or platform in url.lower():
            return platform
    return None


def detect_file_type(url, filename=None):
    """Detect file type from URL or filename"""
    # Check URL
    url_lower = url.lower()
    
    # Check for video platforms first
    if detect_platform(url):
        return 'video'
    
    # Check extensions
    for ext_type, extensions in FILE_TYPES.items():
        for ext in extensions:
            if ext in url_lower:
                return ext_type
    
    # Check filename
    if filename:
        filename_lower = filename.lower()
        for ext_type, extensions in FILE_TYPES.items():
            for ext in extensions:
                if ext in filename_lower:
                    return ext_type
    
    return 'file'


def format_bytes(bytes_val):
    """Format bytes to human readable"""
    if bytes_val < 1024:
        return f"{bytes_val} B"
    elif bytes_val < 1024 * 1024:
        return f"{bytes_val / 1024:.1f} KB"
    elif bytes_val < 1024 * 1024 * 1024:
        return f"{bytes_val / (1024 * 1024):.1f} MB"
    else:
        return f"{bytes_val / (1024 * 1024 * 1024):.2f} GB"


def get_filename_from_url(url):
    """Extract filename from URL"""
    parsed = urlparse(url)
    path = parsed.path
    
    if '/' in path:
        filename = path.split('/')[-1]
        if filename:
            return filename
    
    # Generate default filename
    return f"download_{uuid.uuid4().hex[:8]}"


# ═══════════════════════════════════════════════════════════════════════════
# API ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════════

def index(req, res):
    """Root endpoint - API info"""
    return res.json({
        "name": "TurboGet Backend API",
        "version": "1.0.0",
        "developer": "Olatunji Ayobami Ayanlowo",
        "contact": "+2347038193753",
        "status": "running",
        "platforms": "100+ streaming platforms supported",
        "endpoints": {
            "GET /api": "API info",
            "GET /api/health": "Health check",
            "POST /api/detect": "Detect file type from URL",
            "GET /api/platforms": "List supported platforms",
            "POST /api/download": "Start download (requires backend)"
        }
    })


def health(req, res):
    """Health check endpoint"""
    return res.json({
        "status": "healthy",
        "developer": "Olatunji Ayobami Ayanlowo",
        "contact": "+2347038193753",
        "timestamp": str(uuid.uuid4())  # Placeholder for actual timestamp
    })


def detect(req, res):
    """Detect file type from URL"""
    try:
        # Get URL from query or body
        url = None
        
        if hasattr(req, 'query') and req.query:
            url = req.query.get('url')
        elif hasattr(req, 'searchParams') and req.searchParams:
            url = req.searchParams.get('url')
        
        if hasattr(req, 'body') and req.body:
            if isinstance(req.body, dict):
                url = url or req.body.get('url')
            elif isinstance(req.body, str):
                try:
                    body = json.loads(req.body)
                    url = url or body.get('url')
                except:
                    pass
        
        if not url:
            return res.json({"error": "URL is required"}, status=400)
        
        # Detect file info
        platform = detect_platform(url)
        file_type = detect_file_type(url)
        filename = get_filename_from_url(url)
        
        return res.json({
            "id": uuid.uuid4().hex[:8],
            "filename": filename,
            "url": url,
            "file_type": file_type,
            "platform": VIDEO_PLATFORMS.get(platform) if platform else None,
            "is_video": platform is not None or file_type == 'video',
            "detected": True
        })
        
    except Exception as e:
        return res.json({"error": str(e)}, status=500)


def platforms(req, res):
    """List supported platforms"""
    return res.json({
        "platforms": list(VIDEO_PLATFORMS.items()),
        "file_types": FILE_TYPES,
        "total_platforms": len(VIDEO_PLATFORMS),
        "developer": "Olatunji Ayobami Ayanlowo"
    })


def download(req, res):
    """Download endpoint - Info only (actual download requires server)"""
    try:
        url = None
        
        if hasattr(req, 'query') and req.query:
            url = req.query.get('url')
        elif hasattr(req, 'searchParams') and req.searchParams:
            url = req.searchParams.get('url')
        
        if hasattr(req, 'body') and req.body:
            if isinstance(req.body, dict):
                url = url or req.body.get('url')
        
        if not url:
            return res.json({
                "status": "error",
                "message": "URL is required",
                "developer": "Olatunji Ayobami Ayanlowo"
            }, status=400)
        
        # Return download info
        return res.json({
            "id": uuid.uuid4().hex[:12],
            "status": "started",
            "url": url,
            "message": "Download request received. For actual downloads, use the TurboGet backend server.",
            "developer": "Olatunji Ayobami Ayanlowo",
            "contact": "+2347038193753"
        })
        
    except Exception as e:
        return res.json({"error": str(e)}, status=500)


# ═══════════════════════════════════════════════════════════════════════════
# VERCEL SERVERLESS FUNCTION HANDLER
# ═══════════════════════════════════════════════════════════════════════════

def handler(req, res):
    """Main handler for all API routes"""
    path = req.path if hasattr(req, 'path') else '/'
    method = req.method if hasattr(req, 'method') else 'GET'
    
    # Route mapping
    routes = {
        '/api': {'GET': index},
        '/api/': {'GET': index},
        '/api/health': {'GET': health},
        '/api/detect': {'GET': detect, 'POST': detect},
        '/api/platforms': {'GET': platforms},
        '/api/download': {'POST': download, 'GET': detect},
    }
    
    # Find matching route
    for route, methods in routes.items():
        if path == route or path == route + '/':
            handler_func = methods.get(method)
            if handler_func:
                return handler_func(req, res)
            # Method not allowed, return info
            return res.json({
                "error": f"Method {method} not allowed",
                "allowed": list(methods.keys())
            }, status=405)
    
    # No route found, return API info
    return index(req, res)

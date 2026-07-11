"""
TurboGet Backend Server
A comprehensive file download server with YouTube support and general file downloads.
"""

import os
import asyncio
import uuid
import mimetypes
from pathlib import Path
from typing import Optional, List, Dict, Any
from datetime import datetime

from fastapi import FastAPI, HTTPException, BackgroundTasks, Query, UploadFile, File
from fastapi.responses import FileResponse, JSONResponse, StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, HttpUrl
import yt_dlp
import httpx
import aiohttp

# Configuration
DOWNLOAD_DIR = Path("./downloads")
DOWNLOAD_DIR.mkdir(exist_ok=True)

TEMP_DIR = Path("./temp")
TEMP_DIR.mkdir(exist_ok=True)

# Supported platforms for video extraction
VIDEO_PLATFORMS = [
    'youtube.com',
    'youtu.be',
    'vimeo.com',
    'dailymotion.com',
    'twitter.com',
    'x.com',
    'instagram.com',
    'facebook.com',
    'tiktok.com',
    'soundcloud.com',
]

# File type mappings
FILE_TYPES = {
    'video': ['.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.3gp'],
    'audio': ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a', '.wma', '.opus'],
    'image': ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg', '.ico'],
    'document': ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.rtf', '.odt'],
    'archive': ['.zip', '.rar', '.7z', '.tar', '.gz', '.bz2', '.xz'],
    'software': ['.exe', '.msi', '.dmg', '.pkg', '.deb', '.rpm', '.apk', '.app'],
    'code': ['.py', '.js', '.java', '.cpp', '.c', '.h', '.php', '.rb', '.go', '.rs'],
}

# MIME types mapping
MIME_TYPES = {
    '.mp4': 'video/mp4',
    '.mkv': 'video/x-matroska',
    '.avi': 'video/x-msvideo',
    '.mov': 'video/quicktime',
    '.mp3': 'audio/mpeg',
    '.pdf': 'application/pdf',
    '.zip': 'application/zip',
    '.exe': 'application/x-executable',
    '.apk': 'application/vnd.android.package-archive',
}

app = FastAPI(
    title="TurboGet Backend",
    description="Comprehensive file download server with YouTube and media support",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class DownloadResponse(BaseModel):
    id: str
    status: str
    filename: str
    url: str
    file_type: str
    size: Optional[int] = None
    message: str


class VideoInfo(BaseModel):
    id: str
    title: str
    duration: Optional[float]
    thumbnail: Optional[str]
    uploader: Optional[str]
    formats: List[Dict[str, Any]]
    url: str
    platform: str


class FileInfo(BaseModel):
    id: str
    filename: str
    url: str
    file_type: str
    mime_type: Optional[str]
    size: Optional[int]
    detected: bool


# Track download progress
download_tasks: Dict[str, Dict[str, Any]] = {}


def detect_file_type(url: str, content_type: Optional[str] = None, filename: Optional[str] = None) -> str:
    """Detect file type from URL, content-type, or filename."""
    
    # Check filename extension first
    if filename:
        ext = Path(filename).suffix.lower()
        for file_type, extensions in FILE_TYPES.items():
            if ext in extensions:
                return file_type
    
    # Check content-type
    if content_type:
        content_type = content_type.lower()
        if 'video' in content_type:
            return 'video'
        elif 'audio' in content_type:
            return 'audio'
        elif 'image' in content_type:
            return 'image'
        elif 'pdf' in content_type or 'document' in content_type or 'text' in content_type:
            return 'document'
        elif 'zip' in content_type or 'archive' in content_type or 'compressed' in content_type:
            return 'archive'
        elif 'executable' in content_type or 'application' in content_type:
            return 'software'
    
    # Check URL for common patterns
    url_lower = url.lower()
    
    # Video platforms
    for platform in VIDEO_PLATFORMS:
        if platform in url_lower:
            return 'video'
    
    # Common file extensions in URL
    for file_type, extensions in FILE_TYPES.items():
        for ext in extensions:
            if ext in url_lower:
                return file_type
    
    # Default to generic download
    return 'file'


def get_mime_type(filename: str) -> str:
    """Get MIME type from filename."""
    ext = Path(filename).suffix.lower()
    return MIME_TYPES.get(ext, mimetypes.guess_type(filename)[0] or 'application/octet-stream')


async def download_file_async(url: str, download_id: str, filename: Optional[str] = None) -> Dict[str, Any]:
    """Download a file from URL."""
    try:
        download_tasks[download_id] = {
            'status': 'downloading',
            'progress': 0,
            'url': url
        }
        
        async with httpx.AsyncClient(follow_redirects=True, timeout=120.0) as client:
            # Get headers first
            response = await client.head(url)
            content_type = response.headers.get('content-type', '')
            content_length = int(response.headers.get('content-length', 0))
            
            # Determine filename
            if not filename:
                # Try to get from Content-Disposition
                content_disp = response.headers.get('content-disposition', '')
                if 'filename=' in content_disp:
                    filename = content_disp.split('filename=')[1].strip('"\'')
                else:
                    # Generate from URL
                    filename = url.split('/')[-1].split('?')[0] or f'download_{download_id}'
            
            # Ensure filename has extension
            if '.' not in Path(filename).suffix:
                ext = mimetypes.guess_extension(content_type) or '.bin'
                filename += ext
            
            filepath = DOWNLOAD_DIR / filename
            
            # Download with progress tracking
            download_tasks[download_id]['status'] = 'downloading'
            download_tasks[download_id]['filename'] = filename
            
            downloaded = 0
            with open(filepath, 'wb') as f:
                async for chunk in client.stream('GET', url):
                    f.write(chunk)
                    downloaded += len(chunk)
                    if content_length:
                        progress = int((downloaded / content_length) * 100)
                        download_tasks[download_id]['progress'] = progress
            
            file_size = filepath.stat().st_size
            file_type = detect_file_type(url, content_type, filename)
            
            download_tasks[download_id] = {
                'status': 'completed',
                'progress': 100,
                'filename': filename,
                'filepath': str(filepath),
                'size': file_size,
                'file_type': file_type,
                'mime_type': get_mime_type(filename)
            }
            
            return download_tasks[download_id]
            
    except Exception as e:
        download_tasks[download_id] = {
            'status': 'failed',
            'error': str(e)
        }
        raise


def extract_youtube_info(url: str) -> VideoInfo:
    """Extract video information from YouTube or similar platforms."""
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'extract_flat': False,
    }
    
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=False)
        
        # Determine platform
        platform = 'unknown'
        for p in VIDEO_PLATFORMS:
            if p in url.lower():
                platform = p.split('.')[0]
                break
        
        # Format formats list for response
        formats = []
        if 'formats' in info:
            for f in info['formats']:
                formats.append({
                    'format_id': f.get('format_id', ''),
                    'ext': f.get('ext', ''),
                    'resolution': f.get('resolution', 'unknown'),
                    'filesize': f.get('filesize', 0),
                    'tbr': f.get('tbr', 0),
                    'vcodec': f.get('vcodec', 'none'),
                    'acodec': f.get('acodec', 'none'),
                    'fps': f.get('fps', 0),
                    'format_note': f.get('format_note', ''),
                })
        
        return VideoInfo(
            id=info.get('id', ''),
            title=info.get('title', 'Unknown'),
            duration=info.get('duration', 0),
            thumbnail=info.get('thumbnail', ''),
            uploader=info.get('uploader', info.get('channel', '')),
            formats=formats,
            url=url,
            platform=platform
        )


async def download_youtube_async(url: str, download_id: str, format_id: Optional[str] = None, quality: Optional[str] = None) -> Dict[str, Any]:
    """Download video from YouTube or similar platforms."""
    try:
        download_tasks[download_id] = {
            'status': 'preparing',
            'progress': 0,
            'url': url
        }
        
        # Prepare download options
        output_template = str(TEMP_DIR / f'{download_id}_%(title)s.%(ext)s')
        
        ydl_opts = {
            'format': format_id or 'best',
            'outtmpl': output_template,
            'quiet': True,
            'no_warnings': False,
            'progress_hooks': [lambda d: update_progress(download_id, d)],
        }
        
        # Apply quality preference if specified
        if quality:
            if quality == 'best':
                ydl_opts['format'] = 'best'
            elif quality == '1080p':
                ydl_opts['format'] = 'bestvideo[height<=1080]+bestaudio/best[height<=1080]'
            elif quality == '720p':
                ydl_opts['format'] = 'bestvideo[height<=720]+bestaudio/best[height<=720]'
            elif quality == '480p':
                ydl_opts['format'] = 'bestvideo[height<=480]+bestaudio/best[height<=480]'
            elif quality == 'audio':
                ydl_opts['format'] = 'bestaudio/best'
                ydl_opts['postprocessors'] = [{
                    'key': 'FFmpegExtractAudio',
                    'preferredcodec': 'mp3',
                    'preferredquality': '192',
                }]
        
        loop = asyncio.get_event_loop()
        
        def do_download():
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(url, download=True)
                return info
        
        info = await loop.run_in_executor(None, do_download)
        
        # Move to downloads folder
        temp_files = list(TEMP_DIR.glob(f'{download_id}_*'))
        if temp_files:
            final_file = DOWNLOAD_DIR / temp_files[0].name
            temp_files[0].rename(final_file)
            
            download_tasks[download_id] = {
                'status': 'completed',
                'progress': 100,
                'filename': final_file.name,
                'filepath': str(final_file),
                'size': final_file.stat().st_size,
                'file_type': 'video',
                'mime_type': get_mime_type(final_file.name),
                'title': info.get('title', ''),
                'thumbnail': info.get('thumbnail', ''),
            }
        
        return download_tasks[download_id]
        
    except Exception as e:
        download_tasks[download_id] = {
            'status': 'failed',
            'error': str(e)
        }
        raise


def update_progress(download_id: str, d: Dict):
    """Update download progress."""
    if d['status'] == 'downloading':
        if d.get('total_bytes'):
            progress = int((d['downloaded_bytes'] / d['total_bytes']) * 100)
        elif d.get('downloaded_bytes'):
            progress = min(99, d['downloaded_bytes'] // (1024 * 1024))  # Rough estimate
        else:
            progress = 0
        
        download_tasks[download_id]['progress'] = progress
        download_tasks[download_id]['filename'] = d.get('filename', '')
        
    elif d['status'] == 'finished':
        download_tasks[download_id]['progress'] = 100
        download_tasks[download_id]['status'] = 'processing'


# ============== API ENDPOINTS ==============

@app.get("/")
async def root():
    """Root endpoint with API info."""
    return {
        "name": "TurboGet Backend",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "detect": "/api/detect - Detect file type from URL",
            "download": "/api/download - Download any file",
            "video_info": "/api/video/info - Get YouTube/video info",
            "video_download": "/api/video/download - Download YouTube/video",
            "progress": "/api/progress/{id} - Get download progress",
            "health": "/health - Health check"
        }
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}


@app.post("/api/detect", response_model=FileInfo)
async def detect_file(
    url: str = Query(..., description="URL to detect file type")
):
    """Detect file type from URL."""
    try:
        async with httpx.AsyncClient(follow_redirects=True, timeout=30.0) as client:
            response = await client.head(url)
            content_type = response.headers.get('content-type', '')
            content_length = response.headers.get('content-length')
            
            # Try to get filename from Content-Disposition
            filename = None
            content_disp = response.headers.get('content-disposition', '')
            if 'filename=' in content_disp:
                filename = content_disp.split('filename=')[1].strip('"\'')
            
            file_type = detect_file_type(url, content_type, filename)
            
            return FileInfo(
                id=str(uuid.uuid4())[:8],
                filename=filename or url.split('/')[-1],
                url=url,
                file_type=file_type,
                mime_type=content_type or get_mime_type(filename or ''),
                size=int(content_length) if content_length else None,
                detected=True
            )
            
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to detect file: {str(e)}")


@app.post("/api/download", response_model=DownloadResponse)
async def download_file(
    background_tasks: BackgroundTasks,
    url: str = Query(..., description="URL to download"),
    filename: Optional[str] = Query(None, description="Custom filename")
):
    """Download any file from URL."""
    download_id = str(uuid.uuid4())[:12]
    
    # Check if it's a video platform
    url_lower = url.lower()
    is_video = any(platform in url_lower for platform in VIDEO_PLATFORMS)
    
    if is_video:
        raise HTTPException(
            status_code=400,
            detail="For YouTube/video downloads, use /api/video/download endpoint"
        )
    
    # Start background download
    background_tasks.add_task(download_file_async, url, download_id, filename)
    
    file_type = detect_file_type(url, filename=filename)
    
    return DownloadResponse(
        id=download_id,
        status="started",
        filename=filename or "pending",
        url=url,
        file_type=file_type,
        message="Download started"
    )


@app.post("/api/video/info", response_model=VideoInfo)
async def get_video_info(url: str = Query(..., description="Video URL")):
    """Get video information from YouTube or similar platforms."""
    try:
        return extract_youtube_info(url)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to extract video info: {str(e)}")


@app.post("/api/video/download", response_model=DownloadResponse)
async def download_video(
    background_tasks: BackgroundTasks,
    url: str = Query(..., description="Video URL"),
    format_id: Optional[str] = Query(None, description="Specific format ID"),
    quality: Optional[str] = Query(None, description="Quality: best, 1080p, 720p, 480p, audio")
):
    """Download video from YouTube or similar platforms."""
    download_id = str(uuid.uuid4())[:12]
    
    # Start background download
    background_tasks.add_task(
        download_youtube_async, url, download_id, format_id, quality
    )
    
    return DownloadResponse(
        id=download_id,
        status="started",
        filename="preparing...",
        url=url,
        file_type="video",
        message=f"Download started (quality: {quality or 'best'})"
    )


@app.get("/api/progress/{download_id}")
async def get_progress(download_id: str):
    """Get download progress."""
    if download_id not in download_tasks:
        return {"status": "not_found", "message": "Download ID not found"}
    
    return download_tasks[download_id]


@app.get("/api/downloads")
async def list_downloads():
    """List all completed downloads."""
    downloads = []
    for f in DOWNLOAD_DIR.iterdir():
        if f.is_file():
            downloads.append({
                "filename": f.name,
                "size": f.stat().st_size,
                "modified": datetime.fromtimestamp(f.stat().st_mtime).isoformat(),
                "type": detect_file_type(str(f), filename=f.name)
            })
    return {"downloads": downloads}


@app.get("/api/file/{filename}")
async def serve_file(filename: str):
    """Serve a downloaded file."""
    filepath = DOWNLOAD_DIR / filename
    if not filepath.exists():
        raise HTTPException(status_code=404, detail="File not found")
    
    return FileResponse(
        filepath,
        filename=filename,
        media_type=get_mime_type(filename)
    )


@app.delete("/api/file/{filename}")
async def delete_file(filename: str):
    """Delete a downloaded file."""
    filepath = DOWNLOAD_DIR / filename
    if not filepath.exists():
        raise HTTPException(status_code=404, detail="File not found")
    
    filepath.unlink()
    return {"message": f"File {filename} deleted"}


@app.get("/api/supported-platforms")
async def get_supported_platforms():
    """Get list of supported video platforms."""
    return {
        "platforms": VIDEO_PLATFORMS,
        "file_types": FILE_TYPES
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

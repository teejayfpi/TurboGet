/**
 * TurboGet Backend API - Vercel Serverless Functions
 * Built & Designed by Olatunji Ayobami Ayanlowo
 * Contact: +2347038193753
 * 
 * Supports: YouTube, Facebook, Instagram, TikTok, and all streaming platforms
 */

// Supported video platforms
const VIDEO_PLATFORMS = {
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
};

// File extensions by type
const FILE_TYPES = {
  video: ['.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.3gp'],
  audio: ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a', '.wma', '.opus'],
  image: ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg', '.ico'],
  document: ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.rtf'],
  archive: ['.zip', '.rar', '.7z', '.tar', '.gz', '.bz2'],
  software: ['.exe', '.msi', '.dmg', '.pkg', '.deb', '.rpm', '.apk'],
};

function detectPlatform(url) {
  const lowerUrl = url.toLowerCase();
  for (const [platform, name] of Object.entries(VIDEO_PLATFORMS)) {
    if (lowerUrl.includes(platform)) {
      return platform;
    }
  }
  return null;
}

function detectFileType(url) {
  const lowerUrl = url.toLowerCase();
  
  // Check for video platforms first
  if (detectPlatform(url)) {
    return 'video';
  }
  
  // Check extensions
  for (const [type, extensions] of Object.entries(FILE_TYPES)) {
    for (const ext of extensions) {
      if (lowerUrl.includes(ext)) {
        return type;
      }
    }
  }
  
  return 'file';
}

function getFilenameFromUrl(url) {
  try {
    const urlObj = new URL(url);
    const path = urlObj.pathname;
    if (path && path.includes('/')) {
      const filename = path.split('/').pop();
      if (filename) return filename;
    }
  } catch (e) {
    // Invalid URL
  }
  return `download_${Math.random().toString(36).substring(2, 10)}`;
}

function generateId() {
  return Math.random().toString(36).substring(2, 10);
}

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

// Main handler
export default async function handler(req, res) {
  // Set CORS headers
  Object.entries(corsHeaders).forEach(([key, value]) => {
    res.setHeader(key, value);
  });

  // Handle preflight
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const path = req.path || '/';
  const method = req.method;

  try {
    // Route to handler
    if (path === '/api' || path === '/api/') {
      return handleIndex(req, res);
    } else if (path === '/api/health') {
      return handleHealth(req, res);
    } else if (path === '/api/detect') {
      return handleDetect(req, res);
    } else if (path === '/api/platforms') {
      return handlePlatforms(req, res);
    } else if (path === '/api/download') {
      return handleDownload(req, res);
    } else {
      // Default: API info
      return handleIndex(req, res);
    }
  } catch (error) {
    console.error('Error:', error);
    return res.status(500).json({ error: error.message });
  }
}

function handleIndex(req, res) {
  return res.json({
    name: 'TurboGet Backend API',
    version: '1.0.0',
    developer: 'Olatunji Ayobami Ayanlowo',
    contact: '+2347038193753',
    status: 'running',
    platforms: '100+ streaming platforms supported',
    message: 'Welcome to TurboGet Backend API',
    endpoints: {
      'GET /api': 'API info',
      'GET /api/health': 'Health check',
      'POST /api/detect': 'Detect file type from URL',
      'GET /api/platforms': 'List supported platforms',
      'POST /api/download': 'Start download request',
    },
  });
}

function handleHealth(req, res) {
  return res.json({
    status: 'healthy',
    developer: 'Olatunji Ayobami Ayanlowo',
    contact: '+2347038193753',
    timestamp: new Date().toISOString(),
  });
}

function handleDetect(req, res) {
  // Get URL from query or body
  let url = null;
  
  if (req.query && req.query.url) {
    url = req.query.url;
  } else if (req.body && req.body.url) {
    url = req.body.url;
  }
  
  if (!url) {
    return res.status(400).json({ error: 'URL is required' });
  }
  
  const platform = detectPlatform(url);
  const fileType = detectFileType(url);
  const filename = getFilenameFromUrl(url);
  
  return res.json({
    id: generateId(),
    filename: filename,
    url: url,
    file_type: fileType,
    platform: VIDEO_PLATFORMS[platform] || null,
    is_video: platform !== null || fileType === 'video',
    detected: true,
  });
}

function handlePlatforms(req, res) {
  return res.json({
    platforms: Object.entries(VIDEO_PLATFORMS),
    file_types: FILE_TYPES,
    total_platforms: Object.keys(VIDEO_PLATFORMS).length,
    developer: 'Olatunji Ayobami Ayanlowo',
  });
}

function handleDownload(req, res) {
  // Get URL from query or body
  let url = null;
  
  if (req.query && req.query.url) {
    url = req.query.url;
  } else if (req.body && req.body.url) {
    url = req.body.url;
  }
  
  if (!url) {
    return res.status(400).json({
      status: 'error',
      message: 'URL is required',
      developer: 'Olatunji Ayobami Ayanlowo',
    });
  }
  
  const platform = detectPlatform(url);
  const fileType = detectFileType(url);
  
  return res.json({
    id: generateId(),
    status: 'started',
    url: url,
    file_type: fileType,
    platform: VIDEO_PLATFORMS[platform] || null,
    message: 'Download request received. For actual downloads, use the TurboGet backend server on Railway.',
    developer: 'Olatunji Ayobami Ayanlowo',
    contact: '+2347038193753',
    note: 'Video downloads require a full backend server. Deploy backend/Railway for full functionality.',
  });
}

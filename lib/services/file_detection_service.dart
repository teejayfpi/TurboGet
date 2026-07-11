/// File type categories for detection
enum FileCategory {
  video,
  audio,
  image,
  document,
  archive,
  software,
  code,
  unknown,
}

/// Supported video platforms
class VideoPlatform {
  static const List<String> supported = [
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
    'twitch.tv',
    'reddit.com',
    'vk.com',
    'mail.ru',
    'ok.ru',
    'imdb.com',
    'metacafe.com',
    'veoh.com',
    'dailymotion.com',
    'break.com',
  ];

  static const Map<String, String> displayNames = {
    'youtube.com': 'YouTube',
    'youtu.be': 'YouTube',
    'vimeo.com': 'Vimeo',
    'dailymotion.com': 'Dailymotion',
    'twitter.com': 'Twitter',
    'x.com': 'X (Twitter)',
    'instagram.com': 'Instagram',
    'facebook.com': 'Facebook',
    'tiktok.com': 'TikTok',
    'soundcloud.com': 'SoundCloud',
    'twitch.tv': 'Twitch',
    'reddit.com': 'Reddit',
    'vk.com': 'VK',
  };

  static String? detect(String url) {
    final lowerUrl = url.toLowerCase();
    for (final platform in supported) {
      if (lowerUrl.contains(platform)) {
        return platform;
      }
    }
    return null;
  }

  static String getDisplayName(String platform) {
    return displayNames[platform] ?? platform;
  }
}

/// File type detection utility
class FileTypeDetector {
  /// Common file extensions by category
  static const Map<FileCategory, List<String>> extensions = {
    FileCategory.video: [
      '.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm',
      '.m4v', '.3gp', '.ogv', '.ts', '.m2ts', '.mts', '.vob',
      '.mpeg', '.mpg', '.mod', '.tod', '.rec', '.dv',
    ],
    FileCategory.audio: [
      '.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a', '.wma',
      '.opus', '.ape', '.ac3', '.dsd', '.alac', '.tta', '.tak',
      '.mp2', '.amr', '.awb', '.opus', '.mid', '.midi',
    ],
    FileCategory.image: [
      '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg',
      '.ico', '.tiff', '.tif', '.raw', '.heic', '.heif', '.psd',
      '.xcf', '.ai', '.eps', '.indd', '.cdr', '.sketch',
    ],
    FileCategory.document: [
      '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
      '.txt', '.rtf', '.odt', '.ods', '.odp', '.csv', '.tsv',
      '.md', '.rst', '.tex', '.pages', '.numbers', '.key',
    ],
    FileCategory.archive: [
      '.zip', '.rar', '.7z', '.tar', '.gz', '.bz2', '.xz',
      '.tgz', '.tbz2', '.txz', '.lz', '.lzma', '.cab', '.iso',
      '.dmg', '.deb', '.rpm', '.pkg', '.appimage',
    ],
    FileCategory.software: [
      '.exe', '.msi', '.dmg', '.pkg', '.deb', '.rpm', '.apk',
      '.app', '.xap', '.ipa', '.jar', '.bat', '.sh', '.cmd',
      '.ps1', '.vbs', '.scr', '.pif', '.gadget',
    ],
    FileCategory.code: [
      '.py', '.js', '.java', '.cpp', '.c', '.h', '.hpp', '.php',
      '.rb', '.go', '.rs', '.swift', '.kt', '.scala', '.r',
      '.lua', '.pl', '.pm', '.sh', '.bash', '.zsh', '.fish',
      '.html', '.css', '.scss', '.sass', '.less', '.xml', '.json',
      '.yaml', '.yml', '.toml', '.ini', '.conf', '.config',
      '.sql', '.db', '.sqlite', '.graphql', '.proto',
    ],
  };

  /// MIME type patterns
  static const Map<FileCategory, List<String>> mimePatterns = {
    FileCategory.video: ['video/', 'application/x-mpegURL'],
    FileCategory.audio: ['audio/'],
    FileCategory.image: ['image/'],
    FileCategory.document: [
      'application/pdf',
      'application/msword',
      'application/vnd.ms-excel',
      'application/vnd.ms-powerpoint',
      'application/vnd.openxmlformats',
      'text/',
    ],
    FileCategory.archive: [
      'application/zip',
      'application/x-rar',
      'application/x-7z',
      'application/x-tar',
      'application/gzip',
    ],
    FileCategory.software: [
      'application/x-executable',
      'application/x-msdownload',
      'application/vnd.android.package',
      'application/x-apple',
    ],
  };

  /// Detect file category from URL
  static FileCategory detectFromUrl(String url) {
    final lowerUrl = url.toLowerCase();

    // Check for video platforms first
    if (VideoPlatform.detect(url) != null) {
      return FileCategory.video;
    }

    // Check for file extensions
    for (final entry in extensions.entries) {
      for (final ext in entry.value) {
        if (lowerUrl.contains(ext)) {
          return entry.key;
        }
      }
    }

    return FileCategory.unknown;
  }

  /// Detect file category from content type
  static FileCategory detectFromContentType(String? contentType) {
    if (contentType == null) return FileCategory.unknown;

    final lowerType = contentType.toLowerCase();

    for (final entry in mimePatterns.entries) {
      for (final pattern in entry.value) {
        if (lowerType.contains(pattern)) {
          return entry.key;
        }
      }
    }

    return FileCategory.unknown;
  }

  /// Get file extension from URL
  static String? getExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      if (path.contains('.')) {
        final parts = path.split('.');
        if (parts.length > 1) {
          return '.${parts.last.split('?').first}';
        }
      }
    } catch (e) {
      // Parse error
    }
    return null;
  }

  /// Get display name for file category
  static String getCategoryName(FileCategory category) {
    switch (category) {
      case FileCategory.video:
        return 'Video';
      case FileCategory.audio:
        return 'Audio';
      case FileCategory.image:
        return 'Image';
      case FileCategory.document:
        return 'Document';
      case FileCategory.archive:
        return 'Archive';
      case FileCategory.software:
        return 'Software';
      case FileCategory.code:
        return 'Code';
      case FileCategory.unknown:
        return 'File';
    }
  }

  /// Get icon name for file category
  static String getCategoryIcon(FileCategory category) {
    switch (category) {
      case FileCategory.video:
        return 'video_file';
      case FileCategory.audio:
        return 'audio_file';
      case FileCategory.image:
        return 'image';
      case FileCategory.document:
        return 'description';
      case FileCategory.archive:
        return 'folder_zip';
      case FileCategory.software:
        return 'apps';
      case FileCategory.code:
        return 'code';
      case FileCategory.unknown:
        return 'insert_drive_file';
    }
  }

  /// Check if URL is a supported video platform
  static bool isVideoPlatform(String url) {
    return VideoPlatform.detect(url) != null;
  }

  /// Get supported file extensions as a flat list
  static List<String> get allSupportedExtensions {
    return extensions.values.expand((e) => e).toList();
  }

  /// Check if extension is supported
  static bool isSupportedExtension(String? extension) {
    if (extension == null) return false;
    return allSupportedExtensions.contains(extension.toLowerCase());
  }
}

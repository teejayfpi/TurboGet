import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Supported video platforms
enum PlatformType {
  youtube,
  vimeo,
  dailymotion,
  generic,
}

/// Video quality options
class VideoQuality {
  final String quality; // e.g., "1080p", "720p"
  final String format; // e.g., "mp4", "webm"
  final String url;
  final int? fileSize;

  VideoQuality({
    required this.quality,
    required this.format,
    required this.url,
    this.fileSize,
  });
}

/// Platform analyzer for detecting video platforms and extracting metadata
class PlatformAnalyzer {
  static final Map<RegExp, PlatformType> _platformPatterns = {
    RegExp(r'(youtube\.com|youtu\.be)', caseSensitive: false): PlatformType.youtube,
    RegExp(r'vimeo\.com', caseSensitive: false): PlatformType.vimeo,
    RegExp(r'dailymotion\.com', caseSensitive: false): PlatformType.dailymotion,
  };

  /// Detects the platform type from a URL
  Future<PlatformType> detectPlatform(String url) async {
    for (var entry in _platformPatterns.entries) {
      if (entry.key.hasMatch(url)) {
        return entry.value;
      }
    }
    return PlatformType.generic;
  }

  /// Gets video metadata from URL
  Future<Map<String, String?>> getVideoMetadata(String url) async {
    final platform = await detectPlatform(url);
    
    // For generic URLs, do basic HTTP HEAD request
    try {
      final response = await http.head(Uri.parse(url));
      final contentLength = response.headers['content-length'];
      final contentType = response.headers['content-type'];
      
      return {
        'title': _extractFilename(url),
        'author': null,
        'thumbnailUrl': null,
        'contentLength': contentLength,
        'contentType': contentType,
      };
    } catch (e) {
      debugPrint('Error getting metadata: $e');
      return {
        'title': _extractFilename(url),
        'author': null,
        'thumbnailUrl': null,
      };
    }
  }

  /// Gets available video qualities for platform-specific URLs
  Future<List<VideoQuality>?> getVideoQualities(String url) async {
    final platform = await detectPlatform(url);
    
    // For YouTube, Vimeo, Dailymotion - in a real app, you'd use their APIs
    // For now, return a generic quality option
    if (platform == PlatformType.youtube || 
        platform == PlatformType.vimeo || 
        platform == PlatformType.dailymotion) {
      // In production, you would use yt-dlp or similar tools
      // to extract actual video URLs
      return [
        VideoQuality(
          quality: 'best',
          format: 'mp4',
          url: url,
        ),
      ];
    }
    
    return null;
  }

  /// Extracts filename from URL
  String _extractFilename(String url) {
    try {
      final uri = Uri.parse(url);
      var path = uri.path;
      
      // Get the last segment of the path
      if (path.isNotEmpty && path != '/') {
        final segments = path.split('/');
        final filename = segments.last;
        if (filename.contains('.')) {
          return filename.split('?').first;
        }
      }
      
      // Fallback: use query parameters or domain
      if (uri.queryParameters.containsKey('filename')) {
        return uri.queryParameters['filename']!;
      }
      
      // Final fallback: use domain + timestamp
      return '${uri.host}_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      return 'download_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}

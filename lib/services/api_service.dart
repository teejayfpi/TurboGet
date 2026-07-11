import 'dart:convert';
import 'package:http/http.dart' as http;

/// API response for file detection
class FileDetectionResult {
  final String id;
  final String filename;
  final String url;
  final String fileType;
  final String? mimeType;
  final int? size;
  final bool detected;

  FileDetectionResult({
    required this.id,
    required this.filename,
    required this.url,
    required this.fileType,
    this.mimeType,
    this.size,
    required this.detected,
  });

  factory FileDetectionResult.fromJson(Map<String, dynamic> json) {
    return FileDetectionResult(
      id: json['id']?.toString() ?? '',
      filename: json['filename']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      fileType: json['file_type']?.toString() ?? 'file',
      mimeType: json['mime_type']?.toString(),
      size: json['size'] as int?,
      detected: json['detected'] as bool? ?? true,
    );
  }
}

/// API response for video information
class VideoInfoResult {
  final String id;
  final String title;
  final double? duration;
  final String? thumbnail;
  final String? uploader;
  final List<VideoFormat> formats;
  final String url;
  final String platform;

  VideoInfoResult({
    required this.id,
    required this.title,
    this.duration,
    this.thumbnail,
    this.uploader,
    required this.formats,
    required this.url,
    required this.platform,
  });

  factory VideoInfoResult.fromJson(Map<String, dynamic> json) {
    return VideoInfoResult(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown',
      duration: (json['duration'] as num?)?.toDouble(),
      thumbnail: json['thumbnail']?.toString(),
      uploader: json['uploader']?.toString(),
      formats: (json['formats'] as List?)
          ?.map((f) => VideoFormat.fromJson(f as Map<String, dynamic>))
          .toList() ?? [],
      url: json['url']?.toString() ?? '',
      platform: json['platform']?.toString() ?? 'unknown',
    );
  }

  String get durationFormatted {
    if (duration == null) return '--:--';
    final mins = (duration! / 60).floor();
    final secs = (duration! % 60).floor();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// Video format information
class VideoFormat {
  final String formatId;
  final String ext;
  final String resolution;
  final int? filesize;
  final double? tbr;
  final String vcodec;
  final String acodec;
  final int? fps;
  final String? formatNote;

  VideoFormat({
    required this.formatId,
    required this.ext,
    required this.resolution,
    this.filesize,
    this.tbr,
    required this.vcodec,
    required this.acodec,
    this.fps,
    this.formatNote,
  });

  factory VideoFormat.fromJson(Map<String, dynamic> json) {
    return VideoFormat(
      formatId: json['format_id']?.toString() ?? '',
      ext: json['ext']?.toString() ?? '',
      resolution: json['resolution']?.toString() ?? 'unknown',
      filesize: json['filesize'] as int?,
      tbr: (json['tbr'] as num?)?.toDouble(),
      vcodec: json['vcodec']?.toString() ?? 'none',
      acodec: json['acodec']?.toString() ?? 'none',
      fps: json['fps'] as int?,
      formatNote: json['format_note']?.toString(),
    );
  }

  String get qualityLabel {
    if (resolution != 'unknown') return resolution;
    if (formatNote != null) return formatNote!;
    if (tbr != null) return '${tbr!.toInt()}kbps';
    return formatId;
  }

  bool get hasVideo => vcodec != 'none';
  bool get hasAudio => acodec != 'none';
  bool get isVideoOnly => hasVideo && !hasAudio;
  bool get isAudioOnly => !hasVideo && hasAudio;

  String get sizeFormatted {
    if (filesize == null) return 'Unknown size';
    return _formatBytes(filesize!);
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Download progress response
class DownloadProgress {
  final String status;
  final int progress;
  final String? filename;
  final String? filepath;
  final int? size;
  final String? fileType;
  final String? error;
  final String? message;
  final String? url;
  final String? thumbnail;
  final String? title;

  DownloadProgress({
    required this.status,
    required this.progress,
    this.filename,
    this.filepath,
    this.size,
    this.fileType,
    this.error,
    this.message,
    this.url,
    this.thumbnail,
    this.title,
  });

  factory DownloadProgress.fromJson(Map<String, dynamic> json) {
    return DownloadProgress(
      status: json['status']?.toString() ?? 'unknown',
      progress: json['progress'] as int? ?? 0,
      filename: json['filename']?.toString(),
      filepath: json['filepath']?.toString(),
      size: json['size'] as int?,
      fileType: json['file_type']?.toString(),
      error: json['error']?.toString(),
      message: json['message']?.toString(),
      url: json['url']?.toString(),
      thumbnail: json['thumbnail']?.toString(),
      title: json['title']?.toString(),
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isDownloading => status == 'downloading';
  bool get isPreparing => status == 'preparing';
  bool get isProcessing => status == 'processing';
}

/// Backend API Service
class ApiService {
  String _baseUrl;
  static ApiService? _instance;

  ApiService._internal() : _baseUrl = 'https://turboget.onrender.com';

  factory ApiService() {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  /// Get/set the backend server URL
  String get baseUrl => _baseUrl;
  set baseUrl(String url) => _baseUrl = url;

  /// Get backend health status
  Future<Map<String, dynamic>?> checkHealth() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/health'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Health check failed: $e');
    }
    return null;
  }

  /// Detect file type from URL using POST
  Future<Map<String, dynamic>?> detectFile(String url) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/detect?url=$url'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'url': url}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Detect failed: $e');
    }
    return null;
  }

  /// Get video info
  Future<Map<String, dynamic>?> getVideoInfo(String url) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/video/info'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'url': url}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Video info failed: $e');
    }
    return null;
  }

  /// Get download progress
  Future<Map<String, dynamic>?> getDownloadProgress(String downloadId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/progress/$downloadId'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Progress check failed: $e');
    }
    return null;
  }

  /// Set server URL and save to preferences
  Future<void> setServerUrl(String url) async {
    _baseUrl = url;
    // TODO: Save to SharedPreferences
  }

  /// Detect file type from URL
  Future<FileDetectionResult?> detectFile(String url) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/detect?url=${Uri.encodeComponent(url)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return FileDetectionResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('API Error (detectFile): $e');
      return null;
    }
  }

  /// Get video information
  Future<VideoInfoResult?> getVideoInfo(String url) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/video/info?url=${Uri.encodeComponent(url)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return VideoInfoResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('API Error (getVideoInfo): $e');
      return null;
    }
  }

  /// Download a file from URL
  Future<Map<String, dynamic>?> downloadFile(String url, {String? filename}) async {
    try {
      String endpoint = '$_baseUrl/api/download?url=${Uri.encodeComponent(url)}';
      if (filename != null) {
        endpoint += '&filename=${Uri.encodeComponent(filename)}';
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('API Error (downloadFile): $e');
      return null;
    }
  }

  /// Download a YouTube/video
  Future<Map<String, dynamic>?> downloadVideo(
    String url, {
    String? formatId,
    String quality = 'best',
  }) async {
    try {
      String endpoint = '$_baseUrl/api/video/download?url=${Uri.encodeComponent(url)}&quality=$quality';
      if (formatId != null) {
        endpoint += '&format_id=$formatId';
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('API Error (downloadVideo): $e');
      return null;
    }
  }

  /// Get download progress
  Future<DownloadProgress?> getProgress(String downloadId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/progress/$downloadId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return DownloadProgress.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('API Error (getProgress): $e');
      return null;
    }
  }

  /// List all downloads
  Future<List<Map<String, dynamic>>?> listDownloads() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/downloads'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final downloads = data['downloads'];
        if (downloads is List) {
          return downloads.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      }
      return null;
    } catch (e) {
      print('API Error (listDownloads): $e');
      return null;
    }
  }

  /// Get supported platforms
  Future<Map<String, dynamic>?> getSupportedPlatforms() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/supported-platforms'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('API Error (getSupportedPlatforms): $e');
      return null;
    }
  }

  /// Health check
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('API Error (healthCheck): $e');
      return false;
    }
  }
}

/// Video quality options
enum VideoQuality {
  best('best', 'Best Quality'),
  quality1080p('1080p', '1080p HD'),
  quality720p('720p', '720p HD'),
  quality480p('480p', '480p'),
  audio('audio', 'Audio Only');

  final String value;
  final String label;

  const VideoQuality(this.value, this.label);
}

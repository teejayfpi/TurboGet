import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/file_detection_service.dart';

/// Download dialog with quality selection for videos
class DownloadDialogScreen extends StatefulWidget {
  final String url;

  const DownloadDialogScreen({super.key, required this.url});

  @override
  State<DownloadDialogScreen> createState() => _DownloadDialogScreenState();
}

class _DownloadDialogScreenState extends State<DownloadDialogScreen> {
  final _apiService = ApiService();
  final _fileDetector = FileTypeDetector();

  bool _isLoading = true;
  bool _isVideo = false;
  bool _isSupportedVideo = false;
  String _fileType = 'file';
  String? _filename;
  VideoInfoResult? _videoInfo;
  VideoQuality _selectedQuality = VideoQuality.best;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _detectUrl();
  }

  Future<void> _detectUrl() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Detect file type locally first
      _isVideo = FileTypeDetector.isVideoPlatform(widget.url);
      _fileType = FileTypeDetector.detectFromUrl(widget.url).name;

      if (_isVideo) {
        _isSupportedVideo = true;
        // Try to get video info from API
        final info = await _apiService.getVideoInfo(widget.url);
        if (info != null) {
          _videoInfo = info;
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to analyze URL: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Options'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // URL Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getFileIcon(), size: 32, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fileType.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          if (_isSupportedVideo)
                            const Text(
                              'Supported Video Platform',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.url,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Video Info (if YouTube)
        if (_videoInfo != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Video Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _infoRow('Title', _videoInfo!.title),
                  if (_videoInfo!.uploader != null)
                    _infoRow('Channel', _videoInfo!.uploader!),
                  _infoRow('Duration', _videoInfo!.durationFormatted),
                  _infoRow('Platform', _videoInfo!.platform),
                  const SizedBox(height: 8),
                  _infoRow(
                    'Available Formats',
                    '${_videoInfo!.formats.length} formats',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quality Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Quality',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...VideoQuality.values.map((q) => RadioListTile<VideoQuality>(
                        title: Text(q.label),
                        value: q,
                        groupValue: _selectedQuality,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedQuality = value);
                          }
                        },
                      )),
                ],
              ),
            ),
          ),
        ],

        // Supported File Types Info
        if (!_isVideo && !_isSupportedVideo) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Supported File Types',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFileTypeChips(),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Download Button
        ElevatedButton.icon(
          onPressed: _startDownload,
          icon: const Icon(Icons.download),
          label: Text(_isSupportedVideo
              ? 'Download (${_selectedQuality.label})'
              : 'Start Download'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),

        const SizedBox(height: 8),

        // Backend Info
        Card(
          color: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Downloads are processed by the backend server at ${_apiService.baseUrl}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildFileTypeChips() {
    final types = [
      ('Videos', Icons.video_file, Colors.red),
      ('Audio', Icons.audio_file, Colors.orange),
      ('Images', Icons.image, Colors.green),
      ('Documents', Icons.description, Colors.blue),
      ('Archives', Icons.folder_zip, Colors.purple),
      ('Software', Icons.apps, Colors.teal),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) {
        return Chip(
          avatar: Icon(t.$2, size: 18, color: t.$3),
          label: Text(t.$1),
          backgroundColor: t.$3.withOpacity(0.1),
        );
      }).toList(),
    );
  }

  IconData _getFileIcon() {
    switch (_fileType) {
      case 'video':
        return Icons.video_file;
      case 'audio':
        return Icons.audio_file;
      case 'image':
        return Icons.image;
      case 'document':
        return Icons.description;
      case 'archive':
        return Icons.folder_zip;
      case 'software':
        return Icons.apps;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _startDownload() async {
    Navigator.pop(context, {
      'url': widget.url,
      'quality': _selectedQuality.value,
      'isVideo': _isSupportedVideo,
    });
  }
}

/// Quick download bottom sheet
class QuickDownloadSheet extends StatefulWidget {
  final String url;

  const QuickDownloadSheet({super.key, required this.url});

  @override
  State<QuickDownloadSheet> createState() => _QuickDownloadSheetState();
}

class _QuickDownloadSheetState extends State<QuickDownloadSheet> {
  final _apiService = ApiService();
  bool _isDownloading = false;

  Future<void> _startQuickDownload() async {
    setState(() => _isDownloading = true);

    try {
      final isVideo = FileTypeDetector.isVideoPlatform(widget.url);

      Map<String, dynamic>? result;
      if (isVideo) {
        result = await _apiService.downloadVideo(widget.url, quality: 'best');
      } else {
        result = await _apiService.downloadFile(widget.url);
      }

      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      setState(() => _isDownloading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = FileTypeDetector.isVideoPlatform(widget.url);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVideo ? Icons.video_file : Icons.download,
            size: 48,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          Text(
            isVideo ? 'Download Video' : 'Download File',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.url,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isDownloading ? null : _startQuickDownload,
                  child: _isDownloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Download'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

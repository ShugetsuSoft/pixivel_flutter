import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:universal_platform/universal_platform.dart';
import '../models/ugoira.dart';
import '../services/api_service.dart';

// Data class for isolate communication
class GifCreationData {
  final List<Uint8List> frames;
  final List<int> delays;

  GifCreationData(this.frames, this.delays);
}

// Background GIF creation function
Future<Uint8List?> _createGifInBackground(GifCreationData data) async {
  try {
    final List<img.Image> decodedFrames = [];
    final List<int> durations = [];

    for (int i = 0; i < data.frames.length; i++) {
      final decodedImage = img.decodeImage(data.frames[i]);
      if (decodedImage != null) {
        decodedFrames.add(decodedImage);
        // Convert milliseconds to centiseconds (GIF standard)
        final duration = (data.delays[i] / 10).round().clamp(1, 65535);
        durations.add(duration);
      }
    }

    if (decodedFrames.isEmpty) return null;

    // Create GIF encoder
    final gif = img.GifEncoder();
    
    // Start encoding with first frame
    gif.encode(decodedFrames.first);
    
    // Add remaining frames
    for (int i = 1; i < decodedFrames.length; i++) {
      gif.addFrame(decodedFrames[i], duration: durations[i]);
    }
    
    // Get final GIF bytes
    return gif.finish();
  } catch (e) {
    debugPrint('Error in background GIF creation: $e');
    return null;
  }
}

class UgoiraPlayer extends StatefulWidget {
  final Ugoira ugoira;
  final ApiService apiService;
  final BoxFit? fit;
  final double? width;
  final double? height;

  const UgoiraPlayer({
    super.key,
    required this.ugoira,
    required this.apiService,
    this.fit,
    this.width,
    this.height,
  });

  @override
  State<UgoiraPlayer> createState() => _UgoiraPlayerState();
}

class _UgoiraPlayerState extends State<UgoiraPlayer> {
  List<Uint8List>? _frames;
  int _currentFrame = 0;
  Timer? _animationTimer;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isPlaying = true;
  double _playbackSpeed = 1.0;
  bool _showControls = true;
  Timer? _controlsTimer;
  bool _firstFrameReady = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadUgoiraFrames();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _controlsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUgoiraFrames() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Get the ugoira zip URL
      final zipUrl = widget.apiService.getUgoiraZipUrl(
        widget.ugoira.image,
        widget.ugoira.id,
      );

      // Download the zip file
      final response = await http.get(Uri.parse(zipUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download ugoira zip');
      }

      // Extract frames from zip
      final archive = ZipDecoder().decodeBytes(response.bodyBytes);
      final frames = <Uint8List>[];

      // Sort files according to frame order
      for (final frame in widget.ugoira.frames) {
        final archiveFile = archive.files.firstWhere(
          (file) => file.name == frame.file,
          orElse: () => throw Exception('Frame ${frame.file} not found in zip'),
        );
        frames.add(Uint8List.fromList(archiveFile.content));
      }

      setState(() {
        _frames = frames;
        _isLoading = false;
      });

      // Wait for first frame to be rendered before starting animation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _firstFrameReady = true;
          });
          // Small delay before starting animation
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) {
              _startAnimation();
            }
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading ugoira frames: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _startAnimation() {
    if (_frames == null || _frames!.isEmpty) return;

    _animationTimer?.cancel();
    _scheduleNextFrame();
  }

  void _scheduleNextFrame() {
    if (!_isPlaying || _frames == null || _frames!.isEmpty) return;

    final baseDelay = widget.ugoira.frames[_currentFrame].delay;
    final adjustedDelay = (baseDelay / _playbackSpeed).round();
    _animationTimer = Timer(Duration(milliseconds: adjustedDelay), () {
      if (mounted && _isPlaying) {
        setState(() {
          _currentFrame = (_currentFrame + 1) % _frames!.length;
        });
        _scheduleNextFrame();
      }
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _scheduleNextFrame();
    } else {
      _animationTimer?.cancel();
    }
  }

  void _previousFrame() {
    if (_frames == null || _frames!.isEmpty) return;
    setState(() {
      _currentFrame = (_currentFrame - 1 + _frames!.length) % _frames!.length;
    });
  }

  void _nextFrame() {
    if (_frames == null || _frames!.isEmpty) return;
    setState(() {
      _currentFrame = (_currentFrame + 1) % _frames!.length;
    });
  }

  void _changeSpeed(double newSpeed) {
    setState(() {
      _playbackSpeed = newSpeed;
    });
    if (_isPlaying) {
      _animationTimer?.cancel();
      _scheduleNextFrame();
    }
  }

  void _showControlsTemporarily() {
    _controlsTimer?.cancel();
    setState(() {
      _showControls = true;
    });
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _controlsTimer?.cancel();
      _controlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  Future<void> _downloadAnimation() async {
    if (_isDownloading || _frames == null || _frames!.isEmpty) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      // Prepare data for background processing
      final delays = widget.ugoira.frames.map((frame) => frame.delay).toList();
      final gifData = GifCreationData(_frames!, delays);

      // Create GIF in background to avoid blocking UI
      final gifBytes = await compute(_createGifInBackground, gifData);

      if (gifBytes != null) {
        // Save to device
        if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
          // Mobile: Save to gallery
          final tempDir = await getTemporaryDirectory();
          final fileName = 'ugoira_${widget.ugoira.id}_${DateTime.now().millisecondsSinceEpoch}.gif';
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(gifBytes);

          // Save to gallery
          await Gal.putImage(file.path);
          
          // Clean up temp file
          await file.delete();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Animation saved to gallery'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Desktop: Save to downloads folder
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir != null) {
            final fileName = 'ugoira_${widget.ugoira.id}.gif';
            final file = File('${downloadsDir.path}/$fileName');
            await file.writeAsBytes(gifBytes);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Animation saved to ${file.path}'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            throw Exception('Could not access downloads directory');
          }
        }
      } else {
        throw Exception('Failed to encode GIF');
      }
    } catch (e) {
      debugPrint('Error downloading animation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save animation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey.withValues(alpha: 0.1),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading animation...'),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey.withValues(alpha: 0.1),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text('Failed to load animation'),
            ],
          ),
        ),
      );
    }

    if (_frames == null || _frames!.isEmpty || !_firstFrameReady) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white70,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleControls,
      onPanUpdate: (_) => _showControlsTemporarily(),
      child: Container(
        width: widget.width,
        height: widget.height,
        color: Colors.black,
        child: Stack(
          children: [
            // Centered animation
            Center(
              child: Image.memory(
                _frames![_currentFrame],
                fit: widget.fit ?? BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
            
            // Controls overlay
            if (_showControls) ...[
              // Bottom control bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Frame progress bar
                      Row(
                        children: [
                          Text(
                            '${_currentFrame + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: _currentFrame.toDouble(),
                              min: 0,
                              max: (_frames!.length - 1).toDouble(),
                              divisions: _frames!.length - 1,
                              onChanged: (value) {
                                setState(() {
                                  _currentFrame = value.round();
                                });
                              },
                              activeColor: Colors.white,
                              inactiveColor: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          Text(
                            '${_frames!.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      
                      // Control buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Previous frame
                          IconButton(
                            onPressed: _previousFrame,
                            icon: const Icon(Icons.skip_previous, color: Colors.white),
                          ),
                          
                          // Play/Pause
                          IconButton(
                            onPressed: _togglePlayPause,
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          
                          // Next frame
                          IconButton(
                            onPressed: _nextFrame,
                            icon: const Icon(Icons.skip_next, color: Colors.white),
                          ),
                          
                          // Download button
                          IconButton(
                            onPressed: _isDownloading ? null : _downloadAnimation,
                            icon: _isDownloading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.download, color: Colors.white),
                          ),
                          
                          // Speed control
                          PopupMenuButton<double>(
                            onSelected: _changeSpeed,
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 0.25, child: Text('0.25x')),
                              const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                              const PopupMenuItem(value: 1.0, child: Text('1.0x')),
                              const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                              const PopupMenuItem(value: 2.0, child: Text('2.0x')),
                            ],
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.speed, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_playbackSpeed}x',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
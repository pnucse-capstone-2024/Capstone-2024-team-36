import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';

class VideoPlaybackView extends StatefulWidget {
  final int videoId; // 재생할 비디오의 ID

  const VideoPlaybackView({Key? key, required this.videoId}) : super(key: key);

  @override
  State<VideoPlaybackView> createState() => _VideoPlaybackViewState();
}

class _VideoPlaybackViewState extends State<VideoPlaybackView> {
  VideoPlayerController? _videoController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAndPlayVideo();
  }

  Future<void> _fetchAndPlayVideo() async {
    final url = "http://192.168.200.197:7777/websocket/video/${widget.videoId}";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Uint8List videoBytes = response.bodyBytes;
        await _initializeVideoPlayer(videoBytes);
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError("Failed to load video: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError("Error occurred while fetching video: $e");
    }
  }

  Future<void> _initializeVideoPlayer(Uint8List videoBytes) async {
    final tempDir = await getTemporaryDirectory();
    final tempVideoFile = File('${tempDir.path}/temp_video.mp4');
    await tempVideoFile.writeAsBytes(videoBytes);

    _videoController = VideoPlayerController.file(tempVideoFile)
      ..initialize().then((_) {
        setState(() {
          _isLoading = false;
        });
        _videoController!.play();
      }).catchError((error) {
        _showError("Failed to initialize video player: $error");
      });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video Playback")),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : (_videoController != null && _videoController!.value.isInitialized)
            ? AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        )
            : const Text("Failed to load video."),
      ),
      floatingActionButton: _videoController != null
          ? FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_videoController!.value.isPlaying) {
              _videoController!.pause();
            } else {
              _videoController!.play();
            }
          });
        },
        child: Icon(
          _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      )
          : null,
    );
  }
}

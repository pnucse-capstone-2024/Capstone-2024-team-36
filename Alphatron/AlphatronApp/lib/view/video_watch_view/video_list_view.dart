import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:http/http.dart' as http;
import 'video_play_view.dart'; // 비디오 재생 페이지 임포트

class VideoListView extends StatefulWidget {
  @override
  _VideoListViewState createState() => _VideoListViewState();
}

class _VideoListViewState extends State<VideoListView> {
  List<Map<String, dynamic>> _videoFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVideoList();
  }

  Future<void> _fetchVideoList() async {
    final url = "http://192.168.200.197:7777/websocket/videos";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> videoList = json.decode(response.body);
        setState(() {
          _videoFiles = videoList
              .map((item) => {'id': item['id'], 'fileName': item['fileName']})
              .toList();
          _isLoading = false;
        });
      } else {
        _showError("Failed to load video list: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error occurred while fetching video list: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video List")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _videoFiles.length,
        itemBuilder: (context, index) {
          final video = _videoFiles[index];
          return ListTile(
            title: Text(video['fileName']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlaybackView(videoId: video['id']),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
      onPressed: () {
        Get.toNamed('/root');
      },
      child: const Icon(Icons.video_camera_back),
      tooltip: "Go to Live Video",
    ),
    );
  }
}

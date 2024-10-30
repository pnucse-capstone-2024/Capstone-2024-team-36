import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import '../../provider/rtc_streaming/webrtc_provider.dart';

class WebRTCVideoView extends StatefulWidget {
  @override
  _WebRTCVideoViewState createState() => _WebRTCVideoViewState();
}

class _WebRTCVideoViewState extends State<WebRTCVideoView> {
  final _renderer = RTCVideoRenderer();
  final WebRTCController _controller = Get.put(WebRTCController());

  @override
  void initState() {
    super.initState();
    _renderer.initialize();
    _controller.initializePeerConnection();
  }

  @override
  void dispose() {
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!_controller.model.isConnected ||
          _controller.model.remoteStream == null) {
        return Center(child: CircularProgressIndicator());
      }
      _renderer.srcObject = _controller.model.remoteStream;
      return RTCVideoView(
        _renderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      );
    });
  }
}

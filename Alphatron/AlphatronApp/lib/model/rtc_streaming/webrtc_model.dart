import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCModel {
  RTCPeerConnection? peerConnection;
  MediaStream? remoteStream;
  bool isConnected = false;

  WebRTCModel();

  void updateConnection(RTCPeerConnection connection, MediaStream stream) {
    peerConnection = connection;
    remoteStream = stream;
    isConnected = true;
  }

  void closeConnection() {
    peerConnection?.close();
    remoteStream?.dispose();
    isConnected = false;
  }
}
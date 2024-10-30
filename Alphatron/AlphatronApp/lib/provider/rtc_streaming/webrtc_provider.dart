import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../model/rtc_streaming/webrtc_model.dart';

/// WebRTC 연결을 관리하는 GetX 컨트롤러
class WebRTCController extends GetxController {
  // WebRTC 모델을 observable로 선언
  final _model = WebRTCModel().obs;

  // 모델에 대한 getter
  WebRTCModel get model => _model.value;

  /// Peer Connection 초기화 메서드
  Future<void> initializePeerConnection() async {
    // STUN 서버 설정
    // TODO: 필요에 따라 TURN 서버도 추가해야 합니다.
    final Map<String, dynamic> configuration = {
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
      ]
    };

    // Peer Connection 생성
    final peerConnection = await createPeerConnection(configuration);

    // ICE 후보 생성 시 호출되는 콜백
    peerConnection.onIceCandidate = (candidate) {
      // TODO: ICE 후보를 시그널링 서버로 전송하는 로직을 구현해야 합니다.
      // 예: _sendIceCandidateToSignalingServer(candidate);
    };

    // 원격 스트림 추가 시 호출되는 콜백
    peerConnection.onAddStream = (stream) {
      // 모델 업데이트
      _model.update((val) {
        val?.updateConnection(peerConnection, stream);
      });
    };

    // TODO: 시그널링 메커니즘 설정
    // WebSocket이나 다른 방법으로 백엔드와 통신하여 SDP와 ICE 후보를 교환하는 로직을 구현해야 합니다.
    // 예: _setupSignalingMechanism();

    // 상태 업데이트 알림
    update();
  }

  /// SDP Offer 처리 메서드
  Future<void> handleIncomingSDPOffer(String sdpOffer) async {
    if (_model.value.peerConnection == null) return;

    // SDP Offer를 SessionDescription 객체로 변환
    RTCSessionDescription description =
        RTCSessionDescription(sdpOffer, 'offer');

    // 원격 설명 설정
    await _model.value.peerConnection!.setRemoteDescription(description);

    // SDP Answer 생성
    RTCSessionDescription answer =
        await _model.value.peerConnection!.createAnswer();

    // 로컬 설명 설정
    await _model.value.peerConnection!.setLocalDescription(answer);

    // TODO: 생성된 Answer를 시그널링 서버로 전송하는 로직을 구현해야 합니다.
    // 예: _sendAnswerToSignalingServer(answer);
  }

  /// 컨트롤러가 제거될 때 호출되는 메서드
  @override
  void onClose() {
    // WebRTC 연결 종료 및 리소스 해제
    _model.value.closeConnection();
    super.onClose();
  }
}

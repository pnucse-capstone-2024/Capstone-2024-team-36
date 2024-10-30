import 'dart:async';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// VideoStreamModel 클래스는 WebSocket을 통해 서버와 비디오 스트리밍 데이터를 주고받는 모델을 정의합니다.
class VideoStreamModel {
  late WebSocketChannel channel; // WebSocketChannel 객체를 통해 WebSocket 연결을 관리합니다.
  RxBool isConnected = false
      .obs; // RxBool을 사용하여 WebSocket 연결 상태를 관찰할 수 있습니다. GetX의 리액티브 프로그래밍 기능을 활용합니다.
  final streamController = StreamController<
      Uint8List>.broadcast(); // Uint8List 타입의 데이터를 스트리밍하기 위한 StreamController를 생성합니다. broadcast()를 사용하여 여러 리스너가 스트림을 구독할 수 있게 합니다.

  // 서버에 WebSocket을 통해 연결을 시도하는 비동기 함수입니다.
  Future<void> connectToServer() async {
    try {
      // TODO : 웹소캣 서버 url 수정
      // WebSocket 서버에 연결합니다. Uri.parse()를 사용하여 WebSocket 서버의 주소를 지정합니다.
      channel = WebSocketChannel.connect(Uri.parse('ws://172.30.1.11:7777/test'));
      isConnected.value = true; // 연결에 성공하면 isConnected의 값을 true로 설정합니다.

      // WebSocket 스트림을 구독하여 서버로부터 데이터를 수신합니다.
      channel.stream.listen(
        (dynamic data) {
          // 수신한 데이터가 Uint8List 타입인지 확인합니다.
          if (data is Uint8List) {
            streamController.add(data); // 데이터를 StreamController를 통해 스트림에 추가합니다.
            print("data 추가잘됨!");
          }
        },
        onError: (error) {
          // WebSocket에서 오류가 발생한 경우 오류를 출력하고, 서버 연결을 해제합니다.
          print('Error from WebSocket: $error');
          disconnectFromServer(); // 서버와의 연결을 해제하는 함수 호출
        },
        onDone: () {
          // WebSocket 연결이 종료되었을 때 호출됩니다.
          print('WebSocket connection closed');
          disconnectFromServer(); // 서버와의 연결을 해제하는 함수 호출
        },
      );
    } catch (e) {
      // WebSocket 연결 시도 중 오류가 발생한 경우 오류를 출력하고, 연결 상태를 false로 설정합니다.
      print('Error connecting to WebSocket: $e');
      isConnected.value = false;
    }
  }

  // WebSocket 서버와의 연결을 해제하는 함수입니다.
  void disconnectFromServer() {
    channel.sink.close(); // WebSocket 연결을 닫습니다.
    isConnected.value = false; // 연결 상태를 false로 설정합니다.
    streamController.close(); // StreamController를 닫아 스트림을 종료합니다.
  }
}

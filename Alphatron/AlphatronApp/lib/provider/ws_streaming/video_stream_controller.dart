import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import '../../model/ws_streaming/video_stream_model.dart';

// VideoStreamController 클래스는 비디오 스트리밍의 제어를 담당합니다.
// WebSocket을 통해 서버와 연결하고, 수신된 비디오 데이터를 파일에 저장한 후, VLC Player를 사용하여 재생합니다.
class VideoStreamController extends GetxController {
  final VideoStreamModel _model =
      VideoStreamModel(); // 비디오 스트리밍 모델 인스턴스를 생성합니다.
  late VlcPlayerController vlcController; // VLC Player 컨트롤러를 선언합니다.
  RxBool isPlaying = false.obs; // 비디오 재생 상태를 추적하는 RxBool 변수입니다.
  File? tempFile; // 스트리밍 데이터를 임시로 저장할 파일입니다.

  // WebSocket 연결 상태를 외부에서 접근할 수 있도록 getter로 제공
  RxBool get isConnected => _model.isConnected;

  // 새로 추가된 getter : 데이터 스트림을 텍스트로 확인해볼 수 있도
  Stream<List<int>> get dataStream => _model.streamController.stream;

  // Controller 초기화 시 호출되는 메서드로, VLC Player Controller의 초기화를 수행합니다.
  @override
  void onInit() {
    super.onInit();
    _initVlcController(); // VLC Player Controller 초기화 함수 호출
  }

  // VLC Player Controller를 초기화하고, 스트리밍 데이터를 저장할 임시 파일을 생성합니다.
  Future<void> _initVlcController() async {
    final directory = await getTemporaryDirectory(); // 임시 디렉토리를 가져옵니다.
    tempFile = File('${directory.path}/temp_video.ts'); // 임시 파일을 생성합니다.

    // 파일이 생성되기 전까지 VLC Player 초기화를 미루거나, 필요시 재초기화하는 방법 고려
    if (await tempFile!.length() > 102400) {
      vlcController = VlcPlayerController.file(
        tempFile!,
        hwAcc: HwAcc.full,
        options: VlcPlayerOptions(),
      );
    } else {
      print('File is empty during initialization, VLC Player not initialized yet.');
    }
    // // VlcPlayerController를 파일과 연동하여 초기화합니다.
    // vlcController = VlcPlayerController.file(
    //   tempFile!, // 재생할 파일을 지정합니다.
    //   hwAcc: HwAcc.full, // 하드웨어 가속을 풀로 설정합니다.
    //   options: VlcPlayerOptions(), // 추가 옵션을 설정할 수 있습니다.
    // );
  }

  // WebSocket 서버에 연결을 시도하고, 연결되면 스트리밍을 시작합니다.
  Future<void> connectToServer() async {
    await _model.connectToServer(); // WebSocket 서버에 연결을 시도합니다.
    if (isConnected.value) {
      _startStreamingToFile(); // 연결에 성공하면 스트리밍을 시작합니다.
    }
  }

  // // WebSocket에서 수신한 데이터를 파일에 저장하고, VLC  재생을 시작합니다.
  // void _startStreamingToFile() {
  //   // 스트림에서 데이터를 수신하여 처리합니다.
  //   // TODO : 현재 받아오는 데이터가 없으면 오류 발생 -> 받아오는 데이터가 없을때,
  //   // TODO : 즉 침입자가 이미 나가서 영상만 저장되어 있는 상황의 분기로 넘어갈 것
  //   _model.streamController.stream.listen((data) async {
  //     await tempFile!
  //         .writeAsBytes(data, mode: FileMode.append); // 데이터를 파일에 추가로 씁니다.
  //     if (!isPlaying.value) {
  //       // 만약 비디오가 재생 중이 아니라면
  //       await vlcController.play(); // VLC Player에서 비디오 재생을 시작합니다.
  //       isPlaying.value = true; // 비디오 재생 상태를 true로 설정합니다.
  //     }
  //   });
  // }
  void _startStreamingToFile() {
    // 스트림에서 데이터를 수신하여 처리합니다.
    _model.streamController.stream.listen((data) async {
      if (data.isNotEmpty) {
        print('Received data, writing to file...');
        await tempFile!.writeAsBytes(data, mode: FileMode.append); // 데이터를 파일에 추가로 씁니다.

        if (!isPlaying.value) {
          // 파일이 일정 크기 이상일 때만 재생 시작
          if (await tempFile!.length() > 1024) { // 예를 들어, 1KB 이상의 데이터가 쌓인 후
            print('Starting VLC Player...');
            await vlcController.play();
            isPlaying.value = true;
          } else {
            print('File is still too small, not starting VLC Player.');
          }
        } else {
          await vlcController.setMediaFromFile(tempFile!);
        }
      } else {
        print('No data received');
      }
      // await tempFile!.writeAsBytes(data, mode: FileMode.append); // 데이터를 파일에 추가로 씁니다.
      //
      // // VLC Player가 이미 재생 중이지 않다면 재생을 시작합니다.
      // if (!isPlaying.value) {
      //   await vlcController.play(); // VLC Player에서 비디오 재생을 시작합니다.
      //   isPlaying.value = true; // 비디오 재생 상태를 true로 설정합니다.
      // } else {
      //   // VLC Player가 이미 재생 중이라면, 재생을 갱신하도록 요청할 수 있습니다.
      //   await vlcController.setMediaFromFile(tempFile!); // 파일을 다시 로드하여 재생을 갱신합니다.
      // }
    });
  }


  // WebSocket 서버와의 연결을 해제하고, VLC Player를 정지시키며, 임시 파일을 삭제합니다.
  void disconnectFromServer() {
    _model.disconnectFromServer(); // WebSocket 서버와의 연결을 해제합니다.
    vlcController.stop(); // VLC Player에서 재생을 중지합니다.
    isPlaying.value = false; // 비디오 재생 상태를 false로 설정합니다.
    tempFile?.delete(); // 임시 파일을 삭제합니다.
  }

  // Controller가 종료될 때 호출되는 메서드로, 리소스를 정리합니다.
  @override
  void onClose() {
    vlcController.dispose(); // VLC Player Controller를 해제합니다.
    tempFile?.delete(); // 임시 파일을 삭제합니다.
    super.onClose(); // 상위 클래스의 onClose 메서드를 호출하여 정리 작업을 수행합니다.
  }
}

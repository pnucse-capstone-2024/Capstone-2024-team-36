import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart'; // fluttertoast 패키지 추가
import 'dart:convert';
import 'dart:async'; // 타이머를 위해 추가
import '../../model/websocket/websocket.dart';

class VideoStream extends StatefulWidget {
  const VideoStream({Key? key}) : super(key: key);

  @override
  State<VideoStream> createState() => _VideoStreamState();
}

class _VideoStreamState extends State<VideoStream> {
  final WebSocket _socket = WebSocket("ws://192.168.200.197:7777/flutter");
  bool _isConnected = false;
  Uint8List? _currentFrame; // 현재 프레임을 저장할 변수
  List<Map<String, dynamic>> _centroids = []; // 중점 좌표를 저장할 변수
  Timer? _timeoutTimer;  // 사진 수신 타임아웃을 위한 타이머

  void connect(BuildContext context) async {
    _socket.connect();
    _socket.stream.listen((data) {
      _timeoutTimer?.cancel(); // 새로운 데이터가 오면 타이머를 취소
      setState(() {
        // 수신한 데이터를 처리하여 중점 좌표와 이미지 프레임을 분리
        _processData(data as Uint8List);
      });

      // 데이터 수신이 멈추었는지 확인하기 위해 2초 타이머 설정
      _timeoutTimer = Timer(Duration(seconds: 1), () {
        _handleStopReceiving();  // 타이머가 만료되면 멈춘 것으로 간주하고 처리
      });
    });
    setState(() {
      _isConnected = true;
    });
  }

  // 비동기 처리 필요 없이 WebSocket 닫기만 처리
  void disconnect() {
    _socket.disconnect(); // WebSocket 연결 해제
    setState(() {
      _isConnected = false;
      _currentFrame = null;
      _centroids = [];
    });
  }

  Future<void> _handleStopReceiving() async {
    // Toast 메시지로 블랙박스 다운로드 중 메시지 표시
    _showToast("블랙박스 영상 다운로드중");

    try {
      var response = await http.post(Uri.parse("http://192.168.200.197:7777/websocket/download"));

      if (response.statusCode == 200) {
        _showToast("블랙박스 영상 다운완료");
      } else {
        _showToast("다운로드 실패: ${response.statusCode}");
      }
    } catch (e) {
      _showToast("다운로드 중 에러 발생: $e");
      print("Exception details: $e");
    }
  }

  // Toast 메시지를 보여주는 함수
  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,  // 토스트 메시지가 화면 하단에 표시됩니다.
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _processData(Uint8List data) {
    int offset = 0;

    // 1. 중점 좌표 데이터 길이 (4바이트)
    if (offset + 4 > data.length) return;
    int centroidLength = ByteData.sublistView(data, offset, offset + 4).getInt32(0, Endian.big);
    offset += 4;

    // 2. 중점 좌표 데이터 (JSON 형식)
    if (offset + centroidLength > data.length) return;
    String centroidsJson = utf8.decode(data.sublist(offset, offset + centroidLength));
    offset += centroidLength;

    // 중점 좌표 데이터를 JSON으로 파싱
    _centroids = (json.decode(centroidsJson) as List)
        .map((item) => {'id': item['id'], 'cx': item['cx'], 'cy': item['cy']})
        .toList();


    // 3. 이미지 프레임 크기 (4바이트)
    if (offset + 4 > data.length) return;
    int frameSize = ByteData.sublistView(data, offset, offset + 4).getInt32(0, Endian.big);
    offset += 4;

    // 4. 이미지 데이터 (JPEG 형식)
    if (offset + frameSize > data.length) return;
    _currentFrame = data.sublist(offset, offset + frameSize);
  }

  // 각 id에 대한 버튼을 생성하는 위젯
  List<Widget> _buildIdButtons() {
    return _centroids.map((centroid) {
      return ElevatedButton(
        onPressed: () async {
          // ID 값을 포함한 HTTP 요청
          print(centroid['id']);
          String url = "http://192.168.200.197:9999/target/${centroid['id']}";
          try {
            final response = await http.post(Uri.parse(url));
            if (response.statusCode == 200) {
              _showToast("ID ${centroid['id']} 전송 성공");
            } else {
              _showToast("전송 실패: ${response.statusCode}");
            }
          } catch (e) {
            _showToast("전송 중 에러 발생: $e");
            print("Exception details: $e");
          }
        },
        child: Text('ID: ${centroid['id']}'),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Video"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      connect(context);
                    },
                    child: const Text("Connect"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      disconnect();  // WebSocket 연결을 닫고
                      // await _handleStopReceiving();  // 이후에 비동기 작업 수행
                    },
                    child: const Text("Disconnect"),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              _isConnected
                  ? (_currentFrame != null
                  ? Column(
                children: [
                  Image.memory(
                    _currentFrame!,
                    gaplessPlayback: true,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(height: 20),
                  // 실시간 id 버튼 생성
                  Wrap(
                    spacing: 10.0, // 버튼 간 간격
                    children: _buildIdButtons(),
                  ),
                ],
              )
                  : const CircularProgressIndicator())
                  : const Text("Initiate Connection"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Get.toNamed('/video_list');
                },
                child: const Text("Go to Video List"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

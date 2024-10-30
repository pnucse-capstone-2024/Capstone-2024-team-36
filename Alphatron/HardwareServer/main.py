import socket
import cv2
import numpy as np
from ultralytics import YOLO
from boxmot import DeepOCSORT
from pathlib import Path
import websocket
import json
import struct
import threading
from flask import Flask, jsonify

# 서버 설정
HOST = '0.0.0.0'
PORT = 5000
FLASK_PORT = 5001

# YOLOv8n 모델 로드
model = YOLO('yolov8n.pt')

# DeepOCSORT 트래커 초기화
weights_path = Path(r"C:\Work\alphatronPython\osnet_x0_25_msmt17.pt")  # 모델 가중치 경로 설정
tracking_config = 'DeepOCSORT/config.yaml'  # 트래킹 설정 파일 경로 설정

tracking_method = DeepOCSORT(
    model_weights=weights_path,
    device='cpu',
    fp16=False,
    config_file=tracking_config
)

# 전역 변수 선언
raspberry_pi_conn = None
raspberry_pi_conn_lock = threading.Lock()

# 현재 프레임의 중점 좌표 저장소
current_frame_ids = set()
current_frame_ids_lock = threading.Lock()

# 이전 프레임의 중점 좌표 저장소
previous_centroid_data = {}

# 요청된 타겟 ID
requested_id = None
requested_id_lock = threading.Lock()

# 사격 요청 플래그
shoot_requested = False
shoot_requested_lock = threading.Lock()

# Flask 서버 생성
app = Flask(__name__)


@app.route('/target/<int:target_id>', methods=['POST'])
def receive_id(target_id):
    """
    특정 ID의 중점 좌표 요청을 처리하는 엔드포인트
    """
    global requested_id
    print("Received POST request at /target/id")
    with requested_id_lock:
        requested_id = target_id
    return jsonify({"message": f"Target ID {target_id} received"}), 200


@app.route('/shoot/true', methods=['POST'])
def shoot_request():
    """
    사격 요청을 처리하는 엔드포인트
    """
    global shoot_requested
    print("Received POST request at /shoot/true")
    with current_frame_ids_lock:
        if current_frame_ids:
            # 현재 프레임에 ID가 존재하면 사격 요청 성공
            with shoot_requested_lock:
                shoot_requested = True  # 다음 ACK에 포함하기 위해 플래그 설정
            return jsonify({"message": "Shoot request successful"}), 200
        else:
            # 현재 프레임에 ID가 없으면 사격 요청 실패
            return jsonify({"error": "No IDs detected in the current frame"}), 400  # 200 이외의 응답


def flask_thread():
    """Flask 서버를 별도의 스레드에서 실행"""
    app.run(host='0.0.0.0', port=FLASK_PORT, debug=True, use_reloader=False)


def receive_all(conn, length):
    """주어진 길이만큼 데이터를 모두 수신하는 함수"""
    data = b''
    while len(data) < length:
        to_read = length - len(data)
        packet = conn.recv(4096 if to_read > 4096 else to_read)
        if not packet:
            return None
        data += packet
    return data


def process_frame(frame):
    """
    프레임을 처리하여 객체 탐지 및 추적을 수행하고, 중점 좌표를 반환합니다.
    """
    global previous_centroid_data
    global current_frame_ids

    # YOLOv8n 모델로 객체 탐지 수행
    results = model(frame, classes=[0], verbose=False)  # 클래스 0(person)만 탐지
    detections = results[0].boxes.data.cpu().numpy()

    # DeepOCSORT로 객체 추적
    tracks = tracking_method.update(detections, frame)

    centroids = []  # 중점 좌표 리스트
    current_frame_ids_local = set()  # 현재 프레임의 ID 집합

    # 추적된 객체 그리기 및 중점 계산
    for track in tracks:
        x1, y1, x2, y2, track_id, class_id, conf = map(int, track[:7])
        cx = (x1 + x2) // 2  # 중점 x 좌표
        cy = (y1 + y2) // 2  # 중점 y 좌표
        centroids.append({'id': track_id, 'cx': cx, 'cy': cy})  # 현재 프레임의 중점 좌표 리스트에 추가

        # 이전 중점 데이터 업데이트
        previous_centroid_data[track_id] = {'cx': cx, 'cy': cy}

        # 현재 프레임의 ID에 추가
        current_frame_ids_local.add(track_id)

        # 바운딩 박스 및 ID 표시
        cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
        cv2.putText(frame, f'ID: {track_id}', (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.9,
                    (0, 255, 0), 2)

    # 현재 프레임의 ID를 전역 변수로 업데이트
    with current_frame_ids_lock:
        current_frame_ids = current_frame_ids_local

    return frame, centroids


def process_and_send_frame(frame, ws):
    """
    프레임을 처리하고, 결과를 WebSocket으로 전송합니다.
    """
    # 프레임 처리
    processed_frame, centroids = process_frame(frame)

    # WebSocket으로 데이터 전송
    try:
        centroids_json = json.dumps(centroids)
        centroids_bytes = centroids_json.encode('utf-8')
        centroid_length = len(centroids_bytes)

        # 프레임을 JPEG로 인코딩
        _, buffer = cv2.imencode('.jpg', processed_frame)
        frame_data = buffer.tobytes()
        frame_length = len(frame_data)

        # 데이터 패킹
        message = struct.pack('>I', centroid_length) + centroids_bytes + struct.pack('>I', frame_length) + frame_data

        # WebSocket으로 데이터 전송
        ws.send(message, opcode=websocket.ABNF.OPCODE_BINARY)
        # print("Sent frame and centroids over websocket")

    except Exception as e:
        print(f"Error sending data over websocket: {e}")

    return processed_frame, centroids


def receive_frame(conn):
    """
    소켓으로부터 프레임 데이터를 수신합니다.
    """
    # 이미지 데이터 크기 수신
    length_data = receive_all(conn, 4)
    if length_data is None:
        print("No length data received. Exiting.")
        return None
    data_length = int.from_bytes(length_data, byteorder='big')
    # print(f"Expected data length: {data_length} bytes")

    # 이미지 데이터 수신
    img_data = receive_all(conn, data_length)
    if img_data is None:
        print("No image data received. Exiting.")
        return None
    # print(f"Received image data of length: {len(img_data)} bytes")

    # 데이터를 NumPy 배열로 변환 및 이미지 디코딩
    img_array = np.frombuffer(img_data, dtype=np.uint8)
    frame = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
    if frame is None:
        print("Failed to decode image.")
        return None

    return frame


def send_ack_with_data(conn):
    """
    프레임 처리가 완료된 후 Raspberry Pi에 ACK를 전송합니다.
    요청된 ID의 중점 좌표와 사격 명령을 포함합니다.
    """
    global requested_id
    global shoot_requested

    # 사격 요청 상태 가져오기
    with shoot_requested_lock:
        shoot_value = 1 if shoot_requested else 0
        shoot_requested = False  # ACK에 포함 후 플래그 초기화

    # 요청된 ID와 중점 좌표 가져오기
    with requested_id_lock:
        target_id = requested_id

    if target_id is not None:
        # 요청된 ID가 있을 경우
        if target_id in previous_centroid_data:
            centroid = previous_centroid_data[target_id]
            message = f"{target_id},{centroid['cx']},{centroid['cy']},{shoot_value}"
        else:
            # 요청된 ID에 대한 데이터가 없을 경우
            message = f"None,None,None,{shoot_value}"
    else:
        # 요청된 ID가 없을 경우
        message = f"None,None,None,{shoot_value}"

    try:
        conn.sendall(message.encode())
        print(f"Sent ACK: {message}")
    except Exception as e:
        print(f"Error sending ACK: {e}")


def handle_connection(conn, addr, ws):
    """클라이언트 연결을 처리하는 함수"""
    global raspberry_pi_conn
    with raspberry_pi_conn_lock:
        raspberry_pi_conn = conn  # 라즈베리파이의 소켓 연결 저장
    with conn:
        print(f"Connected by {addr}")
        while True:
            try:
                frame = receive_frame(conn)
                if frame is None:
                    break

                # 프레임 처리 및 WebSocket으로 전송
                processed_frame, _ = process_and_send_frame(frame, ws)

                send_ack_with_data(conn)

                # 이미지 출력
                cv2.imshow('YOLO + DeepOCSORT Tracking', processed_frame)

                # 'q' 키로 종료
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    break
            except Exception as e:
                print(f"Error processing frame: {e}")
                break

        # 연결이 종료되면 소켓 제거
        with raspberry_pi_conn_lock:
            raspberry_pi_conn = None
        conn.close()


def main():
    # Flask 서버를 별도의 스레드에서 실행
    flask_thread_obj = threading.Thread(target=flask_thread, daemon=True)
    flask_thread_obj.start()

    # TCP/IP 소켓 생성
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((HOST, PORT))
        s.listen(1)
        print(f"Listening on {HOST}:{PORT}...")

        # WebSocket 연결 설정 (프로그램 시작 시 한 번만 연결)
        try:
            ws = websocket.create_connection("ws://192.168.47.124:7777/python", ping_interval=None)
            print("WebSocket client connected to ws://192.168.47.124:7777/python")
        except Exception as e:
            print(f"Error connecting to WebSocket server: {e}")
            return

        try:
            while True:
                conn, addr = s.accept()
                print(f"Accepted connection from {addr}")
                handle_connection(conn, addr, ws)
        except KeyboardInterrupt:
            print("Server shutting down...")
        finally:
            # 프로그램 종료 시 WebSocket 연결 종료
            ws.close()
            cv2.destroyAllWindows()


if __name__ == "__main__":
    main()

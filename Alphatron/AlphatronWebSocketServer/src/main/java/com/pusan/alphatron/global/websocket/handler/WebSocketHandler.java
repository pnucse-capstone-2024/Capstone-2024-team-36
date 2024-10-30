package com.pusan.alphatron.global.websocket.handler;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.concurrent.*;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.BinaryMessage;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.BinaryWebSocketHandler;
import java.io.File;
import java.io.FileOutputStream;


@RequiredArgsConstructor
@Component
public class WebSocketHandler extends BinaryWebSocketHandler {

    private final ConcurrentMap<String, WebSocketSession> sessions = new ConcurrentHashMap<>();

    private void clearImageFolder() {
        File folder = new File(IMAGE_SAVE_DIR);
        File[] files = folder.listFiles();

        if (files != null) {
            for (File file : files) {
                if (!file.isDirectory()) {
                    file.delete();
                }
            }
        }
    }
    // 저장할 디렉토리 경로
    private static final String IMAGE_SAVE_DIR = "images/";

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
//        System.out.println("afterConnectionEstablished: 시작");
        sessions.put(session.getId(), session);
        System.out.println("해당 세션 ID로 연결했습니다: " + session.getId());

      if( isPythonClient(session)){
          clearImageFolder();

      }



//        System.out.println("Binary message buffer size: " + session.getBinaryMessageSizeLimit());
//        System.out.println("Text message buffer size: " + session.getTextMessageSizeLimit());


    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        sessions.remove(session.getId());
        System.out.println("해당 세션 ID는 종료되었습니다: " + session.getId());
//        System.out.println("afterConnectionClosed: 종료");
    }


    @Override
    protected void handleBinaryMessage(WebSocketSession session, BinaryMessage message) throws IOException {
        try {
            ByteBuffer buffer = message.getPayload();

            // 중점 좌표 데이터의 길이(4바이트)를 먼저 읽습니다.
            int centroidLength = buffer.getInt();

            // 중점 좌표 데이터(centroidLength 바이트) 읽기
            byte[] centroidBytes = new byte[centroidLength];
            buffer.get(centroidBytes);
//            String centroidsJson = new String(centroidBytes);

//            // JSON으로 변환
//            ObjectMapper objectMapper = new ObjectMapper();
//            Centroid[] centroids = objectMapper.readValue(centroidsJson, Centroid[].class);
//            System.out.println("Received centroids: ");
//            for (Centroid centroid : centroids) {
//                System.out.println(centroid);
//            }

            // 이미지 프레임의 크기(4바이트)를 읽습니다.
            int frameLength = buffer.getInt();

            // 이미지 데이터 읽기
            byte[] frameBytes = new byte[frameLength];
            buffer.get(frameBytes);

            // 이미지 저장 디렉토리 설정
            File directory = new File(IMAGE_SAVE_DIR);

            // 디렉토리가 없으면 생성
            if (!directory.exists()) {
                directory.mkdir();
                System.out.println("Created directory: " + IMAGE_SAVE_DIR);
            }

            // 이미지 파일 이름 설정 (예: 이미지 파일을 타임스탬프로 저장)
            String fileName = IMAGE_SAVE_DIR + "received_frame_" + System.currentTimeMillis() + ".jpg";

            // 이미지 파일로 저장
            try (FileOutputStream fos = new FileOutputStream(fileName)) {
                fos.write(frameBytes);
            }



            // 받은 데이터 다시 Flutter로 브로드캐스트
            broadcastToFlutterSessions(centroidBytes,frameBytes);


        } catch (Exception e) {
            System.err.println("Error handling binary message: " + e.getMessage());
            e.printStackTrace();
        }
    }






    private final ExecutorService executorService = Executors.newCachedThreadPool();

    private void broadcastToFlutterSessions(byte[] centroidBytes,byte[] frameBytes) {
        // 바이너리 메시지를 전송하기 위해 중점 좌표와 이미지 프레임을 패킹
        ByteBuffer buffer = ByteBuffer.allocate(4 + centroidBytes.length + 4 + frameBytes.length);


        // 중점 좌표 길이 및 데이터 추가
        buffer.putInt(centroidBytes.length);
        buffer.put(centroidBytes);



        // 이미지 프레임 길이 및 데이터 추가
        buffer.putInt(frameBytes.length);
        buffer.put(frameBytes);


        BinaryMessage message = new BinaryMessage(buffer.array());
        System.out.println("Broadcasting centroids and frame data to Flutter sessions...");

        for (WebSocketSession wsSession : sessions.values()) {
            if (wsSession.isOpen() && isFlutterClient(wsSession)) {  // Flutter 클라이언트만 필터링
                executorService.submit(() -> {
                    try {
                        wsSession.sendMessage(message);
                        System.out.println("Data sent to Flutter session ID: " + wsSession.getId());
                    } catch (IOException e) {
                        System.err.println("Failed to send data to Flutter session " + wsSession.getId() + ": " + e.getMessage());
                        e.printStackTrace();
                    }
                });
            }
        }

        System.out.println("Broadcast complete.");
    }


    private boolean isFlutterClient(WebSocketSession session) {
        return session.getUri().toString().contains("/flutter");
    }

    private boolean isPythonClient(WebSocketSession session) {
        return session.getUri().toString().contains("/python");
    }


    static class Centroid {
        public int id;
        public int cx;
        public int cy;

        @Override
        public String toString() {
            return "ID: " + id + ", CX: " + cx + ", CY: " + cy;
        }
    }
}










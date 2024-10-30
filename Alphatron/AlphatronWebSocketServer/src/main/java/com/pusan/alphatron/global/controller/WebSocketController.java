package com.pusan.alphatron.global.controller;

import com.pusan.alphatron.global.entity.VideoFile;
import com.pusan.alphatron.global.service.VideoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/websocket")
@CrossOrigin(origins = "*")  // 모든 출처 허용
public class WebSocketController {

    private static final String IMAGE_FOLDER = "images/";  // 이미지가 저장된 폴더

    @Autowired
    private VideoService videoService;


    @GetMapping("/videos")
    public ResponseEntity<List<VideoFile>> getAllVideoFiles() {
        try {
            List<VideoFile> videoFiles = videoService.getAllVideoFiles();
            return ResponseEntity.ok(videoFiles);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(null);
        }
    }
    @GetMapping("/video/{id}")
    public ResponseEntity<byte[]> getVideoFile(@PathVariable Long id) {
        Optional<VideoFile> videoFileOptional = videoService.getVideoFileById(id);

        if (videoFileOptional.isPresent()) {
            VideoFile videoFile = videoFileOptional.get();
            byte[] videoData = videoFile.getVideoData();

            HttpHeaders headers = new HttpHeaders();
            headers.set("Content-Type", "video/mp4");
            headers.set("Content-Disposition", "attachment; filename=\"" + videoFile.getFileName() + "\"");

            return new ResponseEntity<>(videoData, headers, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }


    @PostMapping("/download")
    public ResponseEntity<String> downloadBlackboxVideo() {
        try {
            // 이미지 파일 이름을 순차적으로 재명명
            renameImageFiles();

            // 현재 시간을 기반으로 비디오 파일 이름 생성
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");
            String currentTime = LocalDateTime.now().format(formatter);
            String outputVideoFileName = "output_video_" + currentTime + ".mp4";

            // 비디오 파일 생성
            File videoFile = convertImagesToVideo(outputVideoFileName);

            // 비디오 파일을 H2 DB에 저장
            videoService.saveVideoFile(outputVideoFileName, videoFile);

            // 비디오 변환 후 이미지 폴더 비우기
            clearImageFolder();

            return ResponseEntity.ok("블랙박스 영상 다운로드가 완료되었습니다.");
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("블랙박스 영상 다운로드 중 오류가 발생했습니다.");
        }
    }

    private File convertImagesToVideo(String outputVideoFileName) throws IOException, InterruptedException {
        String command = "ffmpeg -framerate 30 -i " + IMAGE_FOLDER + "received_frame_%d.jpg -c:v libx264 -pix_fmt yuv420p " + outputVideoFileName;

        ProcessBuilder processBuilder = new ProcessBuilder(command.split(" "));
        processBuilder.redirectErrorStream(true);
        Process process = processBuilder.start();

        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                System.out.println(line);
            }
        }

        int exitCode = process.waitFor();
        if (exitCode != 0) {
            throw new IOException("FFmpeg 명령어 실행 중 오류가 발생했습니다. Exit code: " + exitCode);
        }

        File videoFile = new File(outputVideoFileName);

        if (!videoFile.exists()) {
            throw new IOException("비디오 파일이 생성되지 않았습니다: " + outputVideoFileName);
        }

        return videoFile;
    }


    private void renameImageFiles() {
        File folder = new File(IMAGE_FOLDER);
        File[] files = folder.listFiles((dir, name) -> name.startsWith("received_frame_") && name.endsWith(".jpg"));

        if (files != null && files.length > 0) {
            Arrays.sort(files, Comparator.comparingLong(file -> {
                // 숫자 부분을 추출하여 비교 (파일 이름에서 숫자를 추출)
                String fileName = file.getName();
                String numberPart = fileName.replaceAll("\\D+", ""); // 숫자만 추출
                return Long.parseLong(numberPart);
            }));

            // 순차적으로 이름 변경
            for (int i = 0; i < files.length; i++) {
                File oldFile = files[i];
                File newFile = new File(IMAGE_FOLDER + "received_frame_" + i + ".jpg");
                oldFile.renameTo(newFile);
            }
        }
    }



    private void clearImageFolder() {
        File folder = new File(IMAGE_FOLDER);
        File[] files = folder.listFiles();

        if (files != null) {
            for (File file : files) {
                if (!file.isDirectory()) {
                    file.delete();
                }
            }
        }
    }
}

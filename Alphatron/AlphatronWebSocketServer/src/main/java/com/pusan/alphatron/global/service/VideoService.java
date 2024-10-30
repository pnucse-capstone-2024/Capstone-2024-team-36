package com.pusan.alphatron.global.service;

import com.pusan.alphatron.global.entity.VideoFile;
import com.pusan.alphatron.global.repository.VideoFileRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.util.List;
import java.util.Optional;

@Service
public class VideoService {

    @Autowired
    private VideoFileRepository videoFileRepository;

    public void saveVideoFile(String fileName, File videoFile) throws IOException {
        VideoFile videoFileEntity = new VideoFile();
        videoFileEntity.setFileName(fileName);
        videoFileEntity.setVideoData(Files.readAllBytes(videoFile.toPath()));

        videoFileRepository.save(videoFileEntity);
    }

    public Optional<VideoFile> getVideoFileById(Long id) {
        return videoFileRepository.findById(id);
    }

    public List<VideoFile> getAllVideoFiles() {
        return videoFileRepository.findAll();
    }
}

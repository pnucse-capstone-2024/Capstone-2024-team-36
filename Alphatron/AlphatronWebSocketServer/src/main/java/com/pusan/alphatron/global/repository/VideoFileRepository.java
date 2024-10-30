package com.pusan.alphatron.global.repository;

import com.pusan.alphatron.global.entity.VideoFile;
import org.springframework.data.jpa.repository.JpaRepository;

public interface VideoFileRepository extends JpaRepository<VideoFile, Long> {
}

package com.pusan.alphatron.global.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;


@Entity
@Getter
public class VideoFile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Setter
    private String fileName;

    @Setter
    @Lob
    private byte[] videoData;

    // 생성자, Getter 및 Setter 생략
}

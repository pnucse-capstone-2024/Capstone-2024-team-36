
package com.pusan.alphatron.global.h264;

import org.bytedeco.javacv.FFmpegFrameGrabber;
import org.bytedeco.javacv.FFmpegLogCallback;
import org.bytedeco.javacv.Frame;
import org.bytedeco.javacv.Java2DFrameConverter;
import org.springframework.stereotype.Component;

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.IOException;

@Component
public class H264Decoder {

    public BufferedImage decodeH264ToImage(byte[] h264Data) {
        FFmpegLogCallback.set();

        FFmpegFrameGrabber grabber = null;
        Java2DFrameConverter converter = new Java2DFrameConverter();
        try {
            // Byte array를 ByteArrayInputStream으로 변환
            ByteArrayInputStream inputStream = new ByteArrayInputStream(h264Data);

            // FFmpegFrameGrabber로 inputStream 설정
            grabber = new FFmpegFrameGrabber(inputStream);
            grabber.setFormat("h264");
            grabber.start();

            System.out.println("Attempting to grab frame...");
            Frame frame = grabber.grabImage();
            if (frame == null) {
                System.out.println("Failed to grab frame: frame is null.");
            } else {
                System.out.println("Frame grabbed successfully.");
            }

            // 프레임이 유효한 경우 BufferedImage로 변환
            if (frame != null) {
                BufferedImage bufferedImage = converter.convert(frame);
                return bufferedImage;
            } else {
                System.out.println("Failed to grab frame.");
                return null;
            }

        } catch (IOException e) {
            System.out.println("IOException occured.");
            e.printStackTrace();
            return null;
        } finally {
            if (grabber != null) {
                try {
                    grabber.stop();
                } catch (FFmpegFrameGrabber.Exception e) {
                    System.out.println("ffpemng occured.");
                    e.printStackTrace();
                }
            }
        }
    }
}

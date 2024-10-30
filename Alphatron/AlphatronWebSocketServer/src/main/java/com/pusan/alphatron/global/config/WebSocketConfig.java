package com.pusan.alphatron.global.config;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;
import org.springframework.web.socket.server.standard.ServletServerContainerFactoryBean;

@Configuration
@EnableWebSocket
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketConfigurer {

    private final WebSocketHandler webSocketHandler;

    @Override
    //웹소켓핸들러 추가
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(webSocketHandler, "/python")
                .setAllowedOrigins("*");
        registry.addHandler(webSocketHandler, "/flutter")
                .setAllowedOrigins("*");
    }


    // WebSocket 버퍼 크기 및 설정 조정
    @Bean
    public ServletServerContainerFactoryBean createWebSocketContainer() {
        ServletServerContainerFactoryBean container = new ServletServerContainerFactoryBean();
        container.setMaxTextMessageBufferSize(50 * 1024 * 1024); // 5MB로 조정
        container.setMaxBinaryMessageBufferSize(50 * 1024 * 1024); // 5MB로 조정
        container.setMaxSessionIdleTimeout(600000L); // 세션 타임아웃 조정 (10분)
        container.setAsyncSendTimeout(600000L); // 비동기 전송 타임아웃 설정 (10분)
        return container;
    }




}
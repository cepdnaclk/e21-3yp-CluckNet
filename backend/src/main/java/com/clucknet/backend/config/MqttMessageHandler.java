package com.clucknet.backend.config;

import com.clucknet.backend.dto.SensorDataRequest;
import com.clucknet.backend.service.SensorDataService;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageHandler;
import org.springframework.messaging.MessagingException;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class MqttMessageHandler implements MessageHandler {

    private final SensorDataService sensorDataService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public void handleMessage(Message<?> message) throws MessagingException {
        try {
            String payload = message.getPayload().toString();

            System.out.println("MQTT message received:");
            System.out.println(payload);

            SensorDataRequest request =
                    objectMapper.readValue(payload, SensorDataRequest.class);

            sensorDataService.saveSensorData(request);

            System.out.println("MQTT data saved to database.");

        } catch (Exception e) {
            System.out.println("Failed to process MQTT message.");
            e.printStackTrace();
        }
    }
}
package com.clucknet.backend.service;

import com.clucknet.backend.dto.SensorDataRequest;
import com.clucknet.backend.entity.SensorData;
import com.clucknet.backend.repository.SensorDataRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class SensorDataService {

    private final SensorDataRepository sensorDataRepository;

    public SensorData saveSensorData(SensorDataRequest request) {

        SensorData data = SensorData.builder()
                .nodeId(request.getNodeId())
                .messageType(request.getMessageType())
                .avgTemperature(request.getAvgTemperature())
                .avgHumidity(request.getAvgHumidity())
                .avgNH3(request.getAvgNH3())
                .lpgRaw(request.getLpgRaw())
                .lpgThreshold(request.getLpgThreshold())
                .lpgDetected(request.getLpgDetected())
                .buzzerStatus(request.getBuzzerStatus())
                .servoClosed(request.getServoClosed())
                .createdAt(LocalDateTime.now())
                .build();

        return sensorDataRepository.save(data);
    }

    public List<SensorData> getLatestData() {
        return sensorDataRepository.findTop20ByOrderByCreatedAtDesc();
    }

    public List<SensorData> getDataByNode(String nodeId) {
        return sensorDataRepository.findByNodeIdOrderByCreatedAtDesc(nodeId);
    }

    public List<SensorData> getLpgAlerts() {
        return sensorDataRepository.findByMessageTypeOrderByCreatedAtDesc("LPG_ALERT");
    }
}
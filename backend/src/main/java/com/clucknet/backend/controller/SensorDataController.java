package com.clucknet.backend.controller;

import com.clucknet.backend.entity.SensorData;
import com.clucknet.backend.service.SensorDataService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/sensor-data")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class SensorDataController {

    private final SensorDataService sensorDataService;

    @GetMapping("/latest")
    public List<SensorData> getLatestData() {
        return sensorDataService.getLatestData();
    }

    @GetMapping("/node/{nodeId}")
    public List<SensorData> getDataByNode(@PathVariable String nodeId) {
        return sensorDataService.getDataByNode(nodeId);
    }

    @GetMapping("/lpg-alerts")
    public List<SensorData> getLpgAlerts() {
        return sensorDataService.getLpgAlerts();
    }
}
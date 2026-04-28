package com.clucknet.backend.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class SensorDataRequest {

    private String nodeId;
    private String messageType;

    private Float avgTemperature;
    private Float avgHumidity;
    private Integer avgNH3;

    private Integer lpgRaw;
    private Integer lpgThreshold;

    private Boolean lpgDetected;
    private Boolean buzzerStatus;
    private Boolean servoClosed;
}

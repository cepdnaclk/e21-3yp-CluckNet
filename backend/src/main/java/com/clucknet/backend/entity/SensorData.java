package com.clucknet.backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SensorData {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

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

    private LocalDateTime createdAt;
}

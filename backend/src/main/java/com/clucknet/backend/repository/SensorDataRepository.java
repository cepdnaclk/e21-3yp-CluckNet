package com.clucknet.backend.repository;

import com.clucknet.backend.entity.SensorData;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SensorDataRepository extends JpaRepository<SensorData, Long> {

    List<SensorData> findTop20ByOrderByCreatedAtDesc();

    List<SensorData> findByNodeIdOrderByCreatedAtDesc(String nodeId);

    List<SensorData> findByMessageTypeOrderByCreatedAtDesc(String messageType);
}
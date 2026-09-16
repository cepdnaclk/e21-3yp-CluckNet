import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_client.dart';
import 'api_constants.dart';
import '../../features/shared/data/models/api_response.dart';
import '../../features/shared/data/models/dashboard_models.dart';
import '../../features/shared/data/models/zone_models.dart';
import '../../features/shared/data/models/telemetry_models.dart';
import '../../features/shared/data/models/alert_models.dart';
import '../../features/shared/data/models/notification_models.dart';
import '../../features/shared/data/models/auth_models.dart';
import '../../features/shared/data/models/device_models.dart';

class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  String _handleError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      try {
        final errJson = e.response?.data as Map<String, dynamic>;
        return errJson['message'] as String? ?? 'An API error occurred.';
      } catch (_) {
        return e.response?.statusMessage ?? 'Request failed.';
      }
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Server connection timed out.';
      case DioExceptionType.connectionError:
        return 'No internet connection detected.';
      default:
        return 'Network request failed.';
    }
  }

  // Dashboard
  Future<DashboardSummaryResponse> getDashboardSummary() async {
    try {
      final response = await _dio.get(ApiConstants.dashboardSummary);
      final apiResponse = ApiResponse<DashboardSummaryResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => DashboardSummaryResponse.fromJson(json as Map<String, dynamic>),
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Zones
  Future<List<ZoneResponse>> getZones() async {
    try {
      final response = await _dio.get(ApiConstants.zones);
      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as List<dynamic>,
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!
            .map((item) => ZoneResponse.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ZoneResponse> createZone(String name) async {
    try {
      final response = await _dio.post(
        ApiConstants.zones,
        data: {'name': name},
      );
      final apiResponse = ApiResponse<ZoneResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ZoneResponse.fromJson(json as Map<String, dynamic>),
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteZone(int zoneId) async {
    try {
      final response = await _dio.delete('${ApiConstants.zones}/$zoneId');
      final apiResponse = ApiResponse<void>.fromJson(
        response.data as Map<String, dynamic>,
        (_) => null,
      );
      if (!apiResponse.success) {
        throw apiResponse.message;
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ZoneResponse> getZoneById(int zoneId) async {
    try {
      final response = await _dio.get('${ApiConstants.zones}/$zoneId');
      final apiResponse = ApiResponse<ZoneResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ZoneResponse.fromJson(json as Map<String, dynamic>),
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Live Telemetry
  Future<LiveTelemetryResponse> getLiveTelemetry(int zoneId) async {
    try {
      final response = await _dio.get(ApiConstants.liveTelemetry(zoneId));
      final apiResponse = ApiResponse<LiveTelemetryResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => LiveTelemetryResponse.fromJson(json as Map<String, dynamic>),
      );
      if (apiResponse.success && apiResponse.data != null) {
        final data = apiResponse.data!;
        String localTimestamp = data.timestamp;
        if (localTimestamp.isNotEmpty) {
          try {
            localTimestamp = DateTime.parse(data.timestamp).toLocal().toIso8601String();
          } catch (_) {}
        }
        return LiveTelemetryResponse(
          temperature: data.temperature,
          humidity: data.humidity,
          nh3: data.nh3,
          lpg: data.lpg,
          timestamp: localTimestamp,
        );
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Telemetry History
  // Telemetry History
  Future<List<TelemetryResponse>> getTelemetryHistory(int zoneId, String range) async {
    try {
      final response = await _dio.get(
        ApiConstants.telemetryHistory(zoneId),
        queryParameters: {'range': range},
      );
      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
            (json) => json as List<dynamic>,
      );
      if (apiResponse.success && apiResponse.data != null) {
        // FIXED HERE: Map through data and convert UTC strings to Local Time
        return apiResponse.data!.map((item) {
          final model = TelemetryResponse.fromJson(item as Map<String, dynamic>);

          // 1. Parse the UTC string from Spring Boot ("2026-06-08T00:45:00Z")
          // 2. Convert it to local time bounds (.toLocal())
          final localTimestamp = DateTime.parse(model.timestamp).toLocal().toIso8601String();

          // 3. Return the updated model
          return model.copyWith(timestamp: localTimestamp);
        }).toList();
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Thresholds
  Future<ThresholdResponse> getThresholdByZoneId(int zoneId) async {
    try {
      final response = await _dio.get(ApiConstants.thresholds(zoneId));
      final apiResponse = ApiResponse<ThresholdResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ThresholdResponse.fromJson(json as Map<String, dynamic>),
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ThresholdResponse> updateThresholds(
    int zoneId, {
    required double minTemp,
    required double maxTemp,
    required double minHum,
    required double maxHum,
    required double maxNh3,
    required double maxLpg,
    required bool autoThresholdEnabled,
    String? placementDate,
    required bool manualOverrideEnabled,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.thresholds(zoneId),
        data: {
          'minTemperature': minTemp,
          'maxTemperature': maxTemp,
          'minHumidity': minHum,
          'maxHumidity': maxHum,
          'maxNh3': maxNh3,
          'maxLpg': maxLpg,
          'autoThresholdEnabled': autoThresholdEnabled,
          'placementDate': placementDate,
          'manualOverrideEnabled': manualOverrideEnabled,
        },
      );
      final apiResponse = ApiResponse<ThresholdResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ThresholdResponse.fromJson(json as Map<String, dynamic>),
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<GrowthScheduleStageResponse>> getScheduleStages(int zoneId) async {
    try {
      final response = await _dio.get(ApiConstants.schedule(zoneId));
      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as List<dynamic>,
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!
            .map((item) => GrowthScheduleStageResponse.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<GrowthScheduleStageResponse>> updateScheduleStages(
      int zoneId, List<GrowthScheduleStageResponse> stages) async {
    try {
      final response = await _dio.put(
        ApiConstants.schedule(zoneId),
        data: stages.map((s) => s.toJson()).toList(),
      );
      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as List<dynamic>,
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!
            .map((item) => GrowthScheduleStageResponse.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> assignZonesToFarmer(String username, List<int> zoneIds) async {
    try {
      final response = await _dio.put(
        ApiConstants.userZones(username),
        data: zoneIds,
      );
      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json,
      );
      if (!apiResponse.success) {
        throw apiResponse.message;
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Alerts
  Future<List<AlertResponse>> getAlerts({int? zoneId}) async {
    try {
      final response = await _dio.get(
        ApiConstants.alerts,
        queryParameters: zoneId != null ? {'zoneId': zoneId} : null,
      );
      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as List<dynamic>,
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!
            .map((item) => AlertResponse.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<AlertResponse> resolveAlert(int alertId) async {
    try {
      final response = await _dio.patch(ApiConstants.resolveAlert(alertId));
      final apiResponse = ApiResponse<AlertResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => AlertResponse.fromJson(json as Map<String, dynamic>),
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Notifications
  Future<List<NotificationResponse>> getNotifications() async {
    try {
      final response = await _dio.get(ApiConstants.notifications);
      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as List<dynamic>,
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!
            .map((item) => NotificationResponse.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      final response = await _dio.post(ApiConstants.markAllRead);
      final apiResponse = ApiResponse<void>.fromJson(
        response.data as Map<String, dynamic>,
        (_) => null,
      );
      if (!apiResponse.success) {
        throw apiResponse.message;
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<NotificationResponse> markNotificationRead(int id) async {
    try {
      final response = await _dio.post(ApiConstants.markNotificationRead(id));
      final apiResponse = ApiResponse<NotificationResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => NotificationResponse.fromJson(json as Map<String, dynamic>),
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Farmer management helper (registers farmer role users)
  Future<void> registerFarmer({
    required String username,
    required String password,
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'username': username,
          'password': password,
          'email': email,
          'role': 'FARMER',
        },
      );
      final apiResponse = ApiResponse<void>.fromJson(
        response.data as Map<String, dynamic>,
        (_) => null,
      );
      if (!apiResponse.success) {
        throw apiResponse.message;
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteFarmer(String username) async {
    try {
      final response = await _dio.delete('${ApiConstants.users}/$username');
      final apiResponse = ApiResponse<void>.fromJson(
        response.data as Map<String, dynamic>,
        (_) => null,
      );
      if (!apiResponse.success) {
        throw apiResponse.message;
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Device Management APIs
  Future<List<DeviceResponse>> getAllDevices() async {
    try {
      final response = await _dio.get(ApiConstants.devices);
      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as List<dynamic>,
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!
            .map((e) => DeviceResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<DeviceResponse> registerDevice({
    required String id,
    required String name,
    int? zoneId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.devices,
        data: {
          'id': id,
          'name': name,
          if (zoneId != null) 'zoneId': zoneId,
        },
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      if (apiResponse.success && apiResponse.data != null) {
        return DeviceResponse.fromJson(apiResponse.data!);
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<DeviceResponse> updateDevice({
    required String id,
    required String name,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.devices}/$id',
        data: {'name': name},
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      if (apiResponse.success && apiResponse.data != null) {
        return DeviceResponse.fromJson(apiResponse.data!);
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteDevice(String id) async {
    try {
      final response = await _dio.delete('${ApiConstants.devices}/$id');
      final apiResponse = ApiResponse<void>.fromJson(
        response.data as Map<String, dynamic>,
        (_) => null,
      );
      if (!apiResponse.success) {
        throw apiResponse.message;
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Device & Zone Assignments APIs
  Future<List<DeviceResponse>> getDevicesByZoneId(int zoneId) async {
    try {
      final response = await _dio.get(ApiConstants.zoneDevices(zoneId));
      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as List<dynamic>,
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!
            .map((e) => DeviceResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<DeviceResponse>> getUnassignedDevices() async {
    try {
      final response = await _dio.get(ApiConstants.unassignedDevices);
      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as List<dynamic>,
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!
            .map((e) => DeviceResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<DeviceResponse> assignDeviceToZone(int zoneId, String deviceId) async {
    try {
      final response = await _dio.post(
        ApiConstants.zoneDevices(zoneId),
        data: {'deviceId': deviceId},
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      if (apiResponse.success && apiResponse.data != null) {
        return DeviceResponse.fromJson(apiResponse.data!);
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<DeviceResponse> updateDeviceAssignment(int zoneId, String deviceId) async {
    try {
      final response = await _dio.put(
        ApiConstants.zoneDeviceById(zoneId, deviceId),
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      if (apiResponse.success && apiResponse.data != null) {
        return DeviceResponse.fromJson(apiResponse.data!);
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> removeDeviceAssignment(int zoneId, String deviceId) async {
    try {
      final response = await _dio.delete(
        ApiConstants.zoneDeviceById(zoneId, deviceId),
      );
      final apiResponse = ApiResponse<void>.fromJson(
        response.data as Map<String, dynamic>,
        (_) => null,
      );
      if (!apiResponse.success) {
        throw apiResponse.message;
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<DeviceResponse> reassignDevice(String deviceId, int zoneId) async {
    try {
      final response = await _dio.put(
        ApiConstants.reassignDevice(deviceId),
        queryParameters: {'zoneId': zoneId},
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      if (apiResponse.success && apiResponse.data != null) {
        return DeviceResponse.fromJson(apiResponse.data!);
      }
      throw apiResponse.message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiService(dio);
});

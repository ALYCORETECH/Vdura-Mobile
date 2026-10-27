// lib/core/services/location/location_tracking_service.dart
import 'dart:async';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;

// Import Core Services
import 'package:sales_management/core/services/base_api_service.dart';
import 'package:sales_management/core/services/auth/token_service.dart';
import 'package:sales_management/core/services/location/ping_queue.dart';
import 'package:sales_management/core/utils/ui_feedback_service.dart';

// Import Feature Models & Services
import 'package:sales_management/features/attendance/models/ping_model.dart';
import 'package:sales_management/features/attendance/services/trip_service.dart';
import 'package:sales_management/core/utils/file_logger.dart';

const _channelId = 'vanguarde_tracking_channel';
const _notificationId = 888;

class LocationTrackingService {
  LocationTrackingService._();
  static final LocationTrackingService instance = LocationTrackingService._();

  final _positionController = StreamController<Position>.broadcast();
  StreamSubscription? _serviceUpdateSub;
  bool _isTracking = false;

  Stream<Position> get positionStream => _positionController.stream;
  bool get isTracking => _isTracking;

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      'Location Tracking',
      description: 'Shown while your visits are being tracked during punch-in.',
      importance: Importance.low,
    );

    final notificationsPlugin = FlutterLocalNotificationsPlugin();
    final androidImplementation = notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(androidChannel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onServiceStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: 'Vanguarde',
        initialNotificationContent: 'Waiting for punch-in…',
        foregroundServiceNotificationId: _notificationId,
        foregroundServiceTypes: [AndroidForegroundType.location],
        autoStartOnBoot: true,
      ),
      iosConfiguration: IosConfiguration(),
    );

    instance._serviceUpdateSub = service.on('positionUpdate').listen((event) {
      if (event == null) return;
      final pos = Position(
        latitude: (event['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (event['longitude'] as num?)?.toDouble() ?? 0.0,
        timestamp: event['timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(event['timestamp'] as int)
            : DateTime.now(),
        accuracy: (event['accuracy'] as num?)?.toDouble() ?? 0.0,
        altitude: (event['altitude'] as num?)?.toDouble() ?? 0.0,
        altitudeAccuracy: (event['altitudeAccuracy'] as num?)?.toDouble() ?? 0.0,
        heading: (event['heading'] as num?)?.toDouble() ?? 0.0,
        headingAccuracy: (event['headingAccuracy'] as num?)?.toDouble() ?? 0.0,
        speed: (event['speed'] as num?)?.toDouble() ?? 0.0,
        speedAccuracy: (event['speedAccuracy'] as num?)?.toDouble() ?? 0.0,
      );
      instance._positionController.add(pos);
    });
  }

  /// Returns true only when tracking can survive a background restart:
  /// "Allow all the time" location, notifications, and battery exemption.
  static Future<bool> ensureTrackingPermissions() async {
    var perm = await Geolocator.checkPermission();
    FileLogger().i("Permissions Check: Initial Location Permission = $perm");
    
    if (perm == LocationPermission.denied) {
      FileLogger().i("Permissions Check: Requesting Location Permission...");
      perm = await Geolocator.requestPermission();
      FileLogger().i("Permissions Check: After Request = $perm");
    }
    
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      FileLogger().w("Permissions Check: Location Permission Denied.");
      return false;
    }

    if (perm == LocationPermission.whileInUse) {
      FileLogger().i("Permissions Check: Requesting 'Always' Location Permission...");
      // Android 11+ sends the user to Settings -> "Allow all the time"
      await Permission.locationAlways.request();
      perm = await Geolocator.checkPermission();
      FileLogger().i("Permissions Check: After 'Always' Request = $perm");
    }
    
    if (perm != LocationPermission.always) {
      FileLogger().w("Permissions Check: 'Always' permission not granted. Current = $perm");
      return false;
    }

    // A blocked foreground notification can get the service stopped.
    final notifStatus = await Permission.notification.status;
    if (!notifStatus.isGranted) {
      FileLogger().i("Permissions Check: Requesting Notification Permission...");
      await Permission.notification.request();
    }

    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    if (!batteryStatus.isGranted) {
      FileLogger().i("Permissions Check: Requesting Ignore Battery Optimizations...");
      await Permission.ignoreBatteryOptimizations.request();
    }
    
    FileLogger().i("Permissions Check: All required permissions granted.");
    return true;
  }

  /// The trip must already be saved via TokenService.saveActiveTrip() before
  /// calling this: the background isolate reads the trip from storage itself.
  Future<void> start(int tripId) async {
    if (!await ensureTrackingPermissions()) {
      FileLogger().w("startTracking failed: Permissions not granted");
      throw Exception('Allow location "all the time" to start your shift');
    }

    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      FileLogger().i("Starting FlutterBackgroundService");
      await service.startService();
    }

    // No payload and no fixed delay. The isolate also begins on its own at
    // startup, and begin() is idempotent, so this is just a nudge.
    FileLogger().i("Invoking startTracking on background service for Trip $tripId");
    service.invoke('startTracking');
    _isTracking = true;
  }

  Future<void> stop() async {
    FileLogger().i("Stopping LocationTrackingService");
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      FileLogger().w("Service was already stopped");
      _isTracking = false;
      return;
    }

    // Subscribe BEFORE invoking so the reply can't be missed.
    final stopped = service
        .on('stopped')
        .first
        .timeout(const Duration(seconds: 15), onTimeout: () {
          FileLogger().w("Timeout waiting for 'stopped' event from background service");
          return null;
        });
    service.invoke('stopTracking');
    await stopped; // final flush has finished
    _isTracking = false;
    FileLogger().i("LocationTrackingService stopped successfully");
  }

  void dispose() {
    _serviceUpdateSub?.cancel();
    _positionController.close();
  }
}

@pragma('vm:entry-point')
void _onServiceStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await FileLogger().init();
  FileLogger().i("Background Isolate: _onServiceStart triggered");

  // ── API services for the background isolate ──
  final tokenService = TokenService();
  final tripService =
  TripService(BaseApiService(Dio(), UiFeedbackService(), tokenService));
  final queue = await PingQueue.open(); // disk-backed, survives process death

  int? tripId;
  StreamSubscription<Position>? posSub;
  StreamSubscription<ServiceStatus>? statusSub;
  Timer? syncTimer;
  Timer? watchdog;
  DateTime lastFix = DateTime.now();
  bool syncing = false;

  void setNotification(String content) {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Vanguarde — Tracking Active',
        content: content,
      );
    }
  }

  Future<void> record(Position pos) async {
    lastFix = DateTime.now();
    await queue.add(
      tripId!,
      Ping(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        capturedAt: pos.timestamp,
      ),
    );
    service.invoke('positionUpdate', {
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'timestamp': pos.timestamp.millisecondsSinceEpoch,
      'accuracy': pos.accuracy,
      'altitude': pos.altitude,
      'altitudeAccuracy': pos.altitudeAccuracy,
      'heading': pos.heading,
      'headingAccuracy': pos.headingAccuracy,
      'speed': pos.speed,
      'speedAccuracy': pos.speedAccuracy,
    });
  }

  void subscribe() {
    posSub?.cancel();
    posSub = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        intervalDuration: const Duration(seconds: 30),
      ),
    ).listen(
      record,
      onError: (e) {
        FileLogger().e('🔴 [BACKGROUND] Position stream error. Resubscribing...', e);
        Future.delayed(const Duration(seconds: 5), subscribe);
      },
      cancelOnError: false,
    );
  }

  Future<void> sync() async {
    if (syncing) return; // never run two syncs at once
    syncing = true;
    try {
      // ── SMART RETRY SYSTEM ──
      // Fetch EVERY trip ID that has unsynced pings in the local database.
      // This guarantees that if a trip ended while offline, its leftover pings
      // are retried automatically on the next cycle, completely separated by trip ID.
      final pendingTripIds = await queue.getPendingTripIds();
      
      for (final tId in pendingTripIds) {
        while (true) {
          final batch = await queue.peek(tId, limit: 100);
          if (batch.isEmpty) break;
          FileLogger().i('🔵 [BACKGROUND] Syncing ${batch.length} pings for Trip $tId...');
          await tripService.sendBatchPings(
              tId, batch.map((r) => r.ping).toList());
          // Delete ONLY after the server accepted the batch.
          await queue.delete(batch.map((r) => r.rowId).toList());
          FileLogger().i('✅ [BACKGROUND] Batch sync successful for Trip $tId!');
        }
      }
    } catch (e) {
      FileLogger().e('🔴 [BACKGROUND] Batch sync failed, will retry on next cycle.', e);
    } finally {
      syncing = false;
    }
  }

  Future<void> begin() async {
    final trip = await tokenService.getActiveTrip();
    if (trip == null) {
      FileLogger().w("Background Isolate: No active trip found in TokenService. Stopping service.");
      service.stopSelf(); // no active trip, no service
      return;
    }
    final id = trip['id'] as int;
    if (tripId == id && posSub != null) return; // idempotent
    tripId = id;
    setNotification('Trip $id | Tracking location');

    subscribe();

    statusSub?.cancel();
    statusSub = Geolocator.getServiceStatusStream().listen((status) {
      if (status == ServiceStatus.disabled) {
        FileLogger().w("Background Isolate: GPS Sensor is turned OFF.");
        setNotification('⚠ Location is OFF. Turn it on to continue');
      } else {
        FileLogger().i("Background Isolate: GPS Sensor is turned ON.");
        setNotification('Trip $id | Tracking location');
        subscribe();
      }
    });

    syncTimer?.cancel();
    syncTimer = Timer.periodic(const Duration(seconds: 45), (_) => sync());

    watchdog?.cancel();
    watchdog = Timer.periodic(const Duration(minutes: 2), (_) async {
      // Zombie guard: trip ended but the service survived.
      if (await tokenService.getActiveTrip() == null) {
        FileLogger().w("Background Watchdog: active trip is null. Syncing and killing self.");
        await sync();
        service.stopSelf();
        return;
      }
      // Heartbeat / stall recovery for stationary or silently-dead streams.
      if (DateTime.now().difference(lastFix) > const Duration(minutes: 3)) {
        FileLogger().w("Background Watchdog: No fix for >3 minutes. Forcing a GPS check.");
        try {
          final p = await Geolocator.getCurrentPosition(
            locationSettings: AndroidSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 20),
            ),
          );
          await record(p);
        } catch (_) {}
        subscribe();
      }
    });
  }

  service.on('startTracking').listen((_) => begin());

  service.on('stopTracking').listen((_) async {
    await posSub?.cancel();
    await statusSub?.cancel();
    syncTimer?.cancel();
    watchdog?.cancel();
    await sync();
    service.invoke('stopped');
    service.stopSelf();
  });

  await begin();
}
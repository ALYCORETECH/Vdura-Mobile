// lib/features/sales/screens/attendance_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:permission_handler/permission_handler.dart';

// Import Core Services & Auth
import 'package:sales_management/core/theme/theme.dart';
import 'package:sales_management/core/services/base_api_service.dart';
import 'package:sales_management/core/services/auth/token_service.dart';
import 'package:sales_management/core/utils/ui_feedback_service.dart';
import 'package:sales_management/core/services/location/location_tracking_service.dart';
import 'package:sales_management/core/services/location/single_location_reader.dart';
import 'package:sales_management/core/utils/file_logger.dart';
import 'package:sales_management/features/attendance/models/transport.model.dart';

// Import Feature Models & Services
import 'package:sales_management/features/attendance/models/trip_model.dart';
import 'package:sales_management/features/attendance/services/transport.service.ts.dart';
import 'package:sales_management/features/attendance/services/trip_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late final TripService _tripService;
  late final TransportService _transportService;
  late final UiFeedbackService _uiFeedbackService;
  late final TokenService _tokenService;

  bool _isLoading = false;
  bool _isFetchingHistory = true;
  Trip? _activeTrip;
  Timer? _timer;
  Duration _workedDuration = Duration.zero;

  List<Trip> _pastTrips = [];

  @override
  void initState() {
    super.initState();

    // Initialize Services
    final dio = Dio();
    _uiFeedbackService = UiFeedbackService();
    _tokenService = TokenService();
    final baseApiService = BaseApiService(dio, _uiFeedbackService, _tokenService);
    _tripService = TripService(baseApiService);
    _transportService = TransportService(baseApiService);
    _loadAttendanceData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadAttendanceData() async {
    setState(() => _isFetchingHistory = true);
    try {
      final localTrip = await _tokenService.getActiveTrip();

      if (localTrip != null) {
        final tripId = localTrip['id'] as int;
        final startedAt = localTrip['startedAt'] as DateTime;

        setState(() {
          _activeTrip = Trip(id: tripId, salesPersonId: 0, status: 'ACTIVE', startedAt: startedAt);
          _workedDuration = DateTime.now().difference(startedAt);
        });

        _startTimer();

        // Resume background GPS. Awaited and isolated so a permission problem
        // is reported clearly instead of becoming an unhandled error or being
        // mistaken for a history-loading failure.
        try {
          await LocationTrackingService.instance.start(tripId);
        } catch (e) {
          _uiFeedbackService.showError(
            e.toString().replaceAll('Exception: ', ''),
          );
        }
      }

      final salesIdString = await _tokenService.getSalesId() ?? '1';
      final salesPersonId = int.tryParse(salesIdString) ?? 1;
      final allTrips = await _tripService.getTripsForSalesPerson(salesPersonId);

      if (mounted) {
        setState(() {
          _pastTrips = allTrips.where((t) {
            final status = t.status.toUpperCase();
            return status == 'COMPLETED' || status == 'ENDED';
          }).toList();
        });
      }
    } catch (e, stackTrace) {
      FileLogger().e("UI: Failed to load attendance history.", e, stackTrace);
      _uiFeedbackService.showError("Failed to load attendance history.");
    } finally {
      if (mounted) {
        setState(() => _isFetchingHistory = false);
      }
    }
  }

  Future<void> _toggleShift() async {
    if (_isLoading) return;

    try {
      final salesIdString = await _tokenService.getSalesId() ?? '1';
      final salesPersonId = int.tryParse(salesIdString) ?? 1;

      if (_activeTrip != null) {
        try {
          FileLogger().i("UI: Stopping trip...");
          setState(() => _isLoading = true);
          // stop() now waits for the background isolate to flush its last pings,
          // so they reach the server while the trip is still open.
          await LocationTrackingService.instance.stop();
          await _tripService.endTrip(_activeTrip!.id);

          await _tokenService.clearActiveTrip();

          _timer?.cancel();
          setState(() {
            _activeTrip = null;
            _workedDuration = Duration.zero;
          });
          FileLogger().i("UI: Trip ended successfully.");
          _uiFeedbackService.showSuccess("Shift ended successfully.");
          await _loadAttendanceData();
        } catch (e, stackTrace) {
          FileLogger().e("UI: Failed to end trip", e, stackTrace);
          _uiFeedbackService.showError("Failed to end shift.");
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        // ── PUNCH IN ──

        // 🚨 1. INTERCEPT: Check Location Services FIRST
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (!mounted) return;
          // Show a clear, undeniable popup instead of a toast
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.location_disabled, size: 40),
              title: const Text('Location Required', style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text('You must enable Location Services to start your shift.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
                FilledButton(
                  onPressed: () {
                    Geolocator.openLocationSettings(); // Opens Android Settings
                    Navigator.pop(context);
                  },
                  child: const Text('Enable Location'),
                ),
              ],
            ),
          );
          return; // Stop the shift start process right here!
        }

        // 🚨 2. INTERCEPT: Require "Allow all the time" + notifications + battery
        // exemption BEFORE any trip is created on the server. With only
        // "While using the app", Android can restart the tracking service in
        // the background with no location access, and tracking silently stops.
        final permsOk = await LocationTrackingService.ensureTrackingPermissions();
        if (!permsOk) {
          if (!mounted) return;
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.location_on_outlined, size: 40),
              title: const Text(
                'Allow Location All the Time',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: const Text(
                'To keep tracking your visits while the app is in the background, '
                    'open Settings → Permissions → Location and choose '
                    '"Allow all the time". Also set Battery to "Unrestricted" for this app.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
                FilledButton(
                  onPressed: () {
                    openAppSettings();
                    Navigator.pop(context);
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
          return; // No trip is created without full tracking permissions
        }

        // 3. Show Transport Selection Dialog
        if (!mounted) return;
        final selectedTransportId = await showDialog<int>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _TransportSelectionDialog(
            transportService: _transportService,
          ),
        );

        if (selectedTransportId == null) return;

        setState(() => _isLoading = true);

        // 4. Fetch real device/emulator GPS location
        final startPos = await SingleLocationReader.getCurrentLocation();
        FileLogger().i("UI: Starting trip with location: ${startPos.latitude}, ${startPos.longitude}");
        final newTrip = await _tripService.startTrip(
          salesPersonId,
          selectedTransportId,
          Waypoint(
            latitude: startPos.latitude,
            longitude: startPos.longitude,
            label: "Shift Start",
          ),
        );

        final startTime = DateTime.now();
        FileLogger().i("UI: Trip started. ID: ${newTrip.id}");

        // Must be saved BEFORE start(): the background isolate reads the active
        // trip from storage itself.
        await _tokenService.saveActiveTrip(newTrip.id, startTime);
        await LocationTrackingService.instance.start(newTrip.id);

        setState(() {
          _activeTrip = Trip(
            id: newTrip.id,
            salesPersonId: newTrip.salesPersonId,
            status: newTrip.status,
            startedAt: startTime,
          );
          _workedDuration = Duration.zero;
        });
        _startTimer();
        _uiFeedbackService.showSuccess("Shift started successfully.");
      }
    } on Exception catch (e, stackTrace) {
      FileLogger().e("UI: Toggle Shift Failed", e, stackTrace);
      _uiFeedbackService.showError("Action failed: ${e.toString().replaceAll('Exception: ', '')}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeTrip?.startedAt != null) {
        setState(() {
          _workedDuration = DateTime.now().difference(_activeTrip!.startedAt!);
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<VanguardeColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final isPunchedIn = _activeTrip != null;

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        // ── 1. The Live Hero Shift Card ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isPunchedIn
                ? scheme.primaryContainer.withOpacity(0.3)
                : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPunchedIn ? scheme.primary : colors.fieldBorder,
              width: isPunchedIn ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Shift',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (isPunchedIn)
                    Row(
                      children: [
                        const _PulsingLiveDot(),
                        const SizedBox(width: 6),
                        Text(
                          'GPS TRACKING ACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDuration(_workedDuration),
                    style: TextStyle(
                      fontSize: 32,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                      letterSpacing: -1.5,
                    ),
                  ),
                  Bounceable(
                    onTap: _toggleShift,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: isPunchedIn ? scheme.error : scheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          if (!isPunchedIn)
                            BoxShadow(
                              color: scheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Row(
                        children: [
                          Icon(
                            isPunchedIn ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isPunchedIn ? 'End Shift' : 'Start Shift',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (isPunchedIn) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                StreamBuilder<Position>(
                  stream: LocationTrackingService.instance.positionStream,
                  builder: (context, snapshot) {
                    final hasLocation = snapshot.hasData;
                    return Row(
                      children: [
                        Icon(
                          hasLocation ? Icons.location_on : Icons.location_searching,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hasLocation
                              ? 'Background sync healthy'
                              : 'Acquiring initial satellite lock...',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 32),
        Text(
          'Attendance History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),

        // ── 2. Historical List View / Loading State ──
        _isFetchingHistory
            ? const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        )
            : _pastTrips.isEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'No past shift logs found.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        )
            : ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _pastTrips.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final trip = _pastTrips[index];
            return _AttendanceHistoryCard(trip: trip);
          },
        ),
      ],
    );
  }
}

// ── Reusable Component for Historical Records ──
class _AttendanceHistoryCard extends StatelessWidget {
  final Trip trip;

  const _AttendanceHistoryCard({required this.trip});

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = (trip.endedAt != null && trip.startedAt != null)
        ? trip.endedAt!.difference(trip.startedAt!)
        : Duration.zero;

    final hoursText = "${duration.inHours}h ${(duration.inMinutes % 60)}m";
    final distanceText = trip.actualDistanceKm?.toStringAsFixed(1) ?? "0.0";
    final visits = trip.waypoints.isEmpty ? 0 : (trip.waypoints.length - 1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trip.startedAt != null ? _formatDate(trip.startedAt!) : 'Unknown Date',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  trip.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricItem(icon: Icons.schedule_rounded, label: 'Worked', value: hoursText),
              _MetricItem(icon: Icons.directions_car_rounded, label: 'Travelled', value: '$distanceText km'),
              _MetricItem(icon: Icons.storefront_rounded, label: 'Visited', value: '$visits'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: scheme.onSurface)),
          ],
        ),
      ],
    );
  }
}

class _PulsingLiveDot extends StatefulWidget {
  const _PulsingLiveDot();

  @override
  State<_PulsingLiveDot> createState() => _PulsingLiveDotState();
}

class _PulsingLiveDotState extends State<_PulsingLiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8, height: 8,
        decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
      ),
    );
  }
}

// ── Transport Selection Dialog Component ──
class _TransportSelectionDialog extends StatefulWidget {
  final TransportService transportService;

  const _TransportSelectionDialog({required this.transportService});

  @override
  State<_TransportSelectionDialog> createState() => _TransportSelectionDialogState();
}

class _TransportSelectionDialogState extends State<_TransportSelectionDialog> {
  late Future<List<TransportDetails>> _transportsFuture;
  int? _selectedTransportId;

  @override
  void initState() {
    super.initState();
    // Fetch active transport modes when dialog opens
    _transportsFuture = widget.transportService.getAllTransports().then(
          (list) => list.where((t) => !t.isDeleted).toList(), // Filter out deleted ones
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Start Shift', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select your mode of transport for this shift:',
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<TransportDetails>>(
            future: _transportsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('Failed to load transport modes.', style: TextStyle(color: Colors.red));
              }

              final transports = snapshot.data!;
              return DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Transport Mode',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                value: _selectedTransportId,
                items: transports.map((t) {
                  return DropdownMenuItem<int>(
                    value: t.transportId,
                    child: Text('${t.transportBy} (₹${t.ratePerKm}/km)'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedTransportId = val);
                },
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null), // Returns null to cancel
          child: Text('Cancel', style: TextStyle(color: scheme.onSurfaceVariant)),
        ),
        FilledButton(
          onPressed: _selectedTransportId == null
              ? null // Disable button if nothing selected
              : () => Navigator.of(context).pop(_selectedTransportId), // Return ID
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
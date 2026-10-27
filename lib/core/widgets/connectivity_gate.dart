// lib/core/widgets/connectivity_gate.dart
import 'dart:async';
import 'package:app_settings/app_settings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sales_management/core/services/auth/token_service.dart'; // ⬅️ NEW IMPORT

class ConnectivityGate extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const ConnectivityGate({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends State<ConnectivityGate>
    with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  StreamSubscription<ServiceStatus>? _locSub;

  bool _hasInternet = true;
  bool _locationEnabled = true;
  bool _isTripActive = false; // ⬅️ Added active trip state
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final connResult = await Connectivity().checkConnectivity();
    _hasInternet = _isConnected(connResult);
    _locationEnabled = await Geolocator.isLocationServiceEnabled();

    _connSub = Connectivity().onConnectivityChanged.listen((result) {
      _hasInternet = _isConnected(result);
      _evaluate();
    });

    _locSub = Geolocator.getServiceStatusStream().listen((status) {
      _locationEnabled = status == ServiceStatus.enabled;
      _evaluate();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluate());
  }

  bool _isConnected(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _recheckOnResume();
  }

  Future<void> _recheckOnResume() async {
    final connResult = await Connectivity().checkConnectivity();
    _hasInternet = _isConnected(connResult);
    _locationEnabled = await Geolocator.isLocationServiceEnabled();
    _evaluate();
  }

  // ── ASYNC EVALUATE: Now checks for an active trip before blocking ──
  Future<void> _evaluate() async {
    if (!mounted) return;

    // 1. Check local storage to see if they are on the clock
    final localTrip = await TokenService().getActiveTrip();

    if (!mounted) return;

    setState(() {
      _isTripActive = localTrip != null;
    });

    // 2. Determine if there is a blocking problem
    final internetProblem = !_hasInternet;
    final locationProblem = !_locationEnabled && _isTripActive; // ⬅️ ONLY a problem if on shift!

    final problem = internetProblem || locationProblem;

    if (problem && !_dialogShowing) {
      _showBlockingDialog();
    } else if (!problem && _dialogShowing) {
      _dismissDialog();
    } else if (problem && _dialogShowing) {
      setState(() {});
    }
  }

  void _showBlockingDialog() {
    final ctx = widget.navigatorKey.currentContext;
    if (ctx == null) return;
    _dialogShowing = true;

    final locationProblem = !_locationEnabled && _isTripActive;

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          icon: Icon(
            !_hasInternet ? Icons.wifi_off : Icons.location_disabled,
            size: 40,
          ),
          title: Text(_titleText()),
          content: Text(_bodyText()),
          actions: [
            if (locationProblem)
              TextButton(
                onPressed: () => Geolocator.openLocationSettings(),
                child: const Text('Enable Location'),
              ),
            if (!_hasInternet)
              TextButton(
                onPressed: () =>
                    AppSettings.openAppSettings(type: AppSettingsType.wifi),
                child: const Text('Network Settings'),
              ),
          ],
        ),
      ),
    ).then((_) {
      _dialogShowing = false;
      final stillLocationProblem = !_locationEnabled && _isTripActive;
      if (!_hasInternet || stillLocationProblem) {
        Future.microtask(_showBlockingDialog);
      }
    });
  }

  String _titleText() {
    final locationProblem = !_locationEnabled && _isTripActive;
    if (!_hasInternet && locationProblem) return 'No Internet & Location Off';
    if (!_hasInternet) return 'No Internet Connection';
    return 'Location Required for Shift';
  }

  String _bodyText() {
    final locationProblem = !_locationEnabled && _isTripActive;
    if (!_hasInternet && locationProblem) {
      return 'Please turn on Wi-Fi/mobile data and enable Location Services to continue your active shift.';
    }
    if (!_hasInternet) return 'Please check your internet connection to continue.';
    return 'You are currently on an active shift. Please enable Location Services so your background tracking can continue.';
  }

  void _dismissDialog() {
    final nav = widget.navigatorKey.currentState;
    if (nav != null && _dialogShowing) {
      nav.pop();
    }
    _dialogShowing = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connSub?.cancel();
    _locSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
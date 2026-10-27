// lib/features/leads/screens/leads_form.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

// Import Core Services
import 'package:sales_management/core/services/auth/token_service.dart';
import 'package:sales_management/core/services/base_api_service.dart';
import 'package:sales_management/core/utils/ui_feedback_service.dart';
import 'package:sales_management/core/services/location/single_location_reader.dart';
import 'package:sales_management/core/widgets/vanguard_text_field.dart';
import 'package:sales_management/core/widgets/vanguarde_button.dart';
import 'package:sales_management/core/widgets/vanguarde_image_picker.dart';

// Import Feature Models & Services
import 'package:sales_management/features/leads/models/leads.model.dart';
import 'package:sales_management/features/leads/services/lead_service.dart';
import 'package:sales_management/features/attendance/models/ping_model.dart';
import 'package:sales_management/features/attendance/services/trip_service.dart';

class AddLeadForm extends StatefulWidget {
  final LeadService leadService;
  final Function()? onSuccess;

  const AddLeadForm({
    super.key,
    required this.leadService,
    this.onSuccess,
  });

  @override
  State<AddLeadForm> createState() => _AddLeadFormState();
}

class _AddLeadFormState extends State<AddLeadForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  String? _photoBase64;
  bool _isSaving = false;

  Future<void> _submitForm() async {
    final uiFeedback = UiFeedbackService();

    if (_photoBase64 == null || _photoBase64!.isEmpty) {
      uiFeedback.showError('A lead photo is mandatory.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    uiFeedback.showLoader();

    final tokenService = TokenService();
    
    // ── NEW: MANDATORY ACTIVE TRIP & LOCATION CHECK BEFORE SAVING ──
    final localTrip = await tokenService.getActiveTrip();
    if (localTrip == null) {
      uiFeedback.hideLoader();
      uiFeedback.showError('You must have an active shift to save a lead.');
      setState(() => _isSaving = false);
      return;
    }
    
    final activeTripId = localTrip['id'] as int;
    late final pos;
    try {
      pos = await SingleLocationReader.getCurrentLocation();
    } catch (e) {
      uiFeedback.hideLoader();
      uiFeedback.showError('Location is required to save a lead. Please enable GPS.');
      setState(() => _isSaving = false);
      return;
    }
    // ───────────────────────────────────────────────────────────────

    final salesIdString = await tokenService.getSalesId();
    final realSalesId = int.tryParse(salesIdString ?? '0') ?? 0;

    final newLead = Lead(
      name: _nameCtrl.text.trim(),
      mobileNumber: _mobileCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      photoBase64: _photoBase64,
      salesId: realSalesId,
    );

    try {
      final createdLead = await widget.leadService.createLead(newLead, showLoader: false);

      // ── GEOTAG THE NEW LEAD DIRECTLY ──
      try {
        final baseApi = BaseApiService(Dio(), uiFeedback, tokenService);
        final tripService = TripService(baseApi);

        final ping = Ping(
          latitude: pos.latitude,
          longitude: pos.longitude,
          capturedAt: DateTime.now(),
        );

        await tripService.sendPing(activeTripId, ping, leadId: createdLead.leadId);
        debugPrint('✅ Lead geotagged successfully to Trip $activeTripId');
      } catch (e) {
        debugPrint('⚠️ Geotagging failed after creation: $e');
        // We don't fail the whole process if the geotag fails (e.g. network issue), 
        // since the Lead was already successfully created in the backend.
      }
      // ──────────────────────────────────

      uiFeedback.hideLoader();
      uiFeedback.showSuccess('Lead added successfully!');

      if (mounted) {
        widget.onSuccess?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      uiFeedback.hideLoader();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add New Lead', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              VanguardeImagePicker(
                label: 'Lead Photo (Required)',
                hintText: 'Tap to take photo',
                onPhotoChanged: (base64String) {
                  setState(() {
                    _photoBase64 = base64String;
                  });
                },
              ),
              const SizedBox(height: 16),

              VanguardeTextField(
                label: 'Name',
                hintText: 'Enter lead name',
                controller: _nameCtrl,
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              VanguardeTextField(
                label: 'Mobile Number',
                hintText: 'Enter 10-digit mobile number',
                controller: _mobileCtrl,
                maxLength: 10,
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Required';
                  if (val.trim().length != 10) return 'Must be exactly 10 digits';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              VanguardeTextField(
                label: 'Location',
                hintText: 'Enter location',
                controller: _locationCtrl,
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              VanguardeButton(
                text: _isSaving ? 'Saving...' : 'Save Lead',
                onPressed: _isSaving ? () {} : () => _submitForm(),
                isFullWidth: true,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
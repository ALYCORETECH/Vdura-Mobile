// lib/features/leads/screens/dealer_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // REQUIRED for TextInputFormatters
import 'package:sales_management/core/services/auth/token_service.dart';
import 'package:sales_management/core/widgets/vanguard_text_field.dart';
import 'package:sales_management/core/widgets/vanguarde_button.dart';
import 'package:sales_management/features/leads/models/dealer_model.dart';
import 'package:sales_management/features/leads/services/dealer_service.dart';

class AddDealerForm extends StatefulWidget {
  final DealerService dealerService;
  final VoidCallback onSuccess;

  const AddDealerForm({
    super.key,
    required this.dealerService,
    required this.onSuccess,
  });

  @override
  State<AddDealerForm> createState() => _AddDealerFormState();
}

class _AddDealerFormState extends State<AddDealerForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _adharCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _address1Ctrl = TextEditingController();
  final _address2Ctrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pinCodeCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Fetch the actual salesId (e.g., 4)
    final tokenService = TokenService();
    final salesIdString = await tokenService.getSalesId();
    final realSalesId = int.tryParse(salesIdString ?? '0') ?? 0;

    final newDealer = Dealer(
      dealerName: _nameCtrl.text.trim(),
      mobileNo: _mobileCtrl.text.trim(),
      emailId: _emailCtrl.text.trim(),
      adharCard: _adharCtrl.text.trim(),
      panCard: _panCtrl.text.trim().toUpperCase(), // Automatically uppercase for DB
      gst: _gstCtrl.text.trim().toUpperCase(),     // Automatically uppercase for DB
      addressLine1: _address1Ctrl.text.trim(),
      addressLine2: _address2Ctrl.text.trim(),
      landmark: _landmarkCtrl.text.trim(),
      area: _areaCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      pinCode: _pinCodeCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
      salesPersonId: realSalesId,
    );

    try {
      await widget.dealerService.createDealer(newDealer);
      if (mounted) {
        widget.onSuccess();
        Navigator.pop(context);
      }
    } catch (e) {
      // API Service handles the error toast
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _mobileCtrl.dispose(); _emailCtrl.dispose();
    _adharCtrl.dispose(); _panCtrl.dispose(); _gstCtrl.dispose();
    _address1Ctrl.dispose(); _address2Ctrl.dispose(); _landmarkCtrl.dispose();
    _areaCtrl.dispose(); _cityCtrl.dispose(); _stateCtrl.dispose();
    _pinCodeCtrl.dispose(); _countryCtrl.dispose(); _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ─── UPGRADED HELPER METHOD ───
  Widget _buildField(
      String label,
      TextEditingController controller, {
        bool isRequired = false,
        TextInputType? keyboardType,
        bool obscureText = false,
        int? maxLength,
        List<TextInputFormatter>? inputFormatters,
        String? Function(String?)? customValidator,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: VanguardeTextField(
        label: label,
        hintText: 'Enter $label',
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        validator: customValidator ?? (val) {
          // Standard Required Check
          if (isRequired && (val == null || val.trim().isEmpty)) {
            return 'Required';
          }
          // Standard Length Check (If data is entered and a maxLength is set)
          if (val != null && val.trim().isNotEmpty && maxLength != null && val.trim().length < maxLength) {
            return 'Must be exactly $maxLength characters';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add New Dealer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Basic Information', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      _buildField('Dealer Name', _nameCtrl, isRequired: true),

                      // 10 Digits strictly
                      _buildField(
                        'Mobile Number',
                        _mobileCtrl,
                        isRequired: true,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),

                      // Email Regex Validation
                      _buildField(
                          'Email ID',
                          _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          customValidator: (val) {
                            if (val != null && val.trim().isNotEmpty) {
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                                return 'Enter a valid email address';
                              }
                            }
                            return null;
                          }
                      ),

                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Legal Documents', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      // 12 Digits strictly
                      _buildField(
                        'Aadhar Card',
                        _adharCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 12,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),

                      // 10 Alphanumeric Characters strictly
                      _buildField(
                        'PAN Card',
                        _panCtrl,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))],
                      ),

                      // 15 Alphanumeric Characters strictly
                      _buildField(
                        'GST Number',
                        _gstCtrl,
                        maxLength: 15,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))],
                      ),

                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Address', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      _buildField('Address Line 1', _address1Ctrl),
                      _buildField('Address Line 2', _address2Ctrl),
                      _buildField('Landmark', _landmarkCtrl),
                      _buildField('Area', _areaCtrl),
                      _buildField('City', _cityCtrl),
                      _buildField('State', _stateCtrl),

                      // 6 Digits strictly
                      _buildField(
                        'PIN Code',
                        _pinCodeCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      _buildField('Country', _countryCtrl),

                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('System Login', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      _buildField('Username', _usernameCtrl),
                      _buildField('Password', _passwordCtrl, obscureText: true),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              VanguardeButton(
                text: 'Save Dealer',
                onPressed: _submitForm,
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
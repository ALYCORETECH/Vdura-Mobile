// lib/features/leads/screens/dealer_details_screen.dart
import 'package:flutter/material.dart';
import 'package:sales_management/core/theme/theme.dart';
import 'package:sales_management/features/leads/models/dealer_model.dart';

class DealerDetailsScreen extends StatelessWidget {
  final Dealer dealer;

  const DealerDetailsScreen({super.key, required this.dealer});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<VanguardeColors>() ?? VanguardeColors.light;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Dealer Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      // ── THE FIX: SafeArea prevents content from hiding behind system nav ──
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Header Profile ──
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(Icons.storefront_rounded, size: 32, color: scheme.onPrimaryContainer),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      dealer.dealerName,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: scheme.onSurface),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── 2. Contact Information ──
              _SectionCard(
                title: 'Contact Information',
                icon: Icons.contact_phone_outlined,
                children: [
                  _DetailRow(label: 'Mobile No.', value: dealer.mobileNo),
                  _DetailRow(label: 'Email ID', value: dealer.emailId.isNotEmpty ? dealer.emailId : 'N/A', isLast: true),
                ],
              ),
              const SizedBox(height: 14),

              // ── 3. Legal Documents ──
              _SectionCard(
                title: 'Legal Documents',
                icon: Icons.description_outlined,
                children: [
                  _DetailRow(label: 'Aadhar Card', value: dealer.adharCard.isNotEmpty ? dealer.adharCard : 'N/A'),
                  _DetailRow(label: 'PAN Card', value: dealer.panCard.isNotEmpty ? dealer.panCard : 'N/A'),
                  _DetailRow(label: 'GST Number', value: dealer.gst.isNotEmpty ? dealer.gst : 'N/A', isLast: true),
                ],
              ),
              const SizedBox(height: 14),

              // ── 4. Full Address ──
              _SectionCard(
                title: 'Address Details',
                icon: Icons.location_on_outlined,
                children: [
                  _DetailRow(label: 'Address Line 1', value: dealer.addressLine1.isNotEmpty ? dealer.addressLine1 : 'N/A'),
                  _DetailRow(label: 'Address Line 2', value: dealer.addressLine2.isNotEmpty ? dealer.addressLine2 : 'N/A'),
                  _DetailRow(label: 'Landmark', value: dealer.landmark.isNotEmpty ? dealer.landmark : 'N/A'),
                  _DetailRow(label: 'Area & City', value: '${dealer.area}${dealer.area.isNotEmpty ? ', ' : ''}${dealer.city}'),
                  _DetailRow(label: 'State & PIN', value: '${dealer.state} - ${dealer.pinCode}'),
                  _DetailRow(label: 'Country', value: dealer.country.isNotEmpty ? dealer.country : 'N/A', isLast: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable Component for Sections ──
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: scheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

// ── Reusable Component for Key-Value Rows ──
// Uses a hairline seam only where two rows meet, instead of a full Divider,
// so it reads as a soft separation rather than a hard rule.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: isLast
          ? null
          : BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withOpacity(0.25),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
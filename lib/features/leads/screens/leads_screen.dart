import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sales_management/core/services/location/single_location_reader.dart';
import 'package:sales_management/core/theme/theme.dart';
import 'package:sales_management/core/utils/ui_feedback_service.dart';
import 'package:sales_management/core/services/auth/token_service.dart';
import 'package:sales_management/core/services/base_api_service.dart';
import 'package:sales_management/features/attendance/models/ping_model.dart';
import 'package:sales_management/features/attendance/services/trip_service.dart';
import 'package:sales_management/features/leads/models/dealer_model.dart';
import 'package:sales_management/features/leads/models/leads.model.dart';
import 'package:sales_management/features/leads/screens/dealer_form.dart';
import 'package:sales_management/features/leads/screens/details/dealer_details_screen.dart';
import 'package:sales_management/features/leads/screens/leads_form.dart';
import 'package:sales_management/features/leads/services/dealer_service.dart';
import 'package:sales_management/features/leads/services/lead_service.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late final LeadService _leadService;
  late final DealerService _dealerService;
  late final TokenService _tokenService;

  List<Lead> leads = [];
  List<Dealer> dealers = [];

  // Search state for Leads
  List<Lead> filteredLeads = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    final dio = Dio();
    final uiFeedbackService = UiFeedbackService();
    _tokenService = TokenService();

    final baseApiService = BaseApiService(dio, uiFeedbackService, _tokenService);

    _leadService = LeadService(baseApiService);
    _dealerService = DealerService(baseApiService);

    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final salesIdString = await _tokenService.getSalesId();
      final salesId = int.tryParse(salesIdString ?? '0') ?? 0;

      final fetchedLeads = await _leadService.getLeads(salesId);
      final fetchedDealers = await _dealerService.getDealers(salesId);

      setState(() {
        leads = fetchedLeads;
        dealers = fetchedDealers;
        _filterLeads(_searchController.text); // Apply existing search on refresh
      });
    } catch (e) {
      // BaseApiService handles error toasts, we just catch to prevent crashes
    }
  }

  // ── SEARCH LOGIC ──
  void _filterLeads(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredLeads = leads;
      });
    } else {
      setState(() {
        filteredLeads = leads
            .where((lead) => lead.name.toLowerCase().contains(query.toLowerCase()) ||
            lead.location.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  // ── LOG VISIT TO EXISTING LEAD ──
  Future<void> _logVisitToExistingLead(Lead lead) async {
    final uiFeedback = UiFeedbackService();
    uiFeedback.showLoader(); // Show loader during GPS lock

    try {
      final pos = await SingleLocationReader.getCurrentLocation();

      // ── 0. FAKE GPS CHECK ──
      if (pos.isMocked) {
        uiFeedback.hideLoader();
        uiFeedback.showError('Fake Location detected. Please disable mock locations to check in.');
        return;
      }

      // ── 1. THE DYNAMIC PERIMETER CHECK (LEADS ONLY) ──
      if (lead.latitude != 0.0 && lead.longitude != 0.0) {
        final distanceInMeters = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          lead.latitude,
          lead.longitude,
        );

        // Define a base radius of 250 meters
        double allowedRadius = 250.0;

        // Temporarily expand the radius if the phone's GPS is struggling indoors
        if (pos.accuracy > allowedRadius) {
          allowedRadius = pos.accuracy;
        }

        if (distanceInMeters > allowedRadius) {
          uiFeedback.hideLoader();
          uiFeedback.showError(
            'You are ${distanceInMeters.toStringAsFixed(0)}m away. Move closer to the shop to check in.',
          );
          return;
        }
      }

      uiFeedback.hideLoader();

      // ── 2. SHOW CONFIRMATION IF WITHIN RANGE ──
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Log Visit', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Do you want to geotag a visit to ${lead.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Log Visit'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // ── 3. PROCESS THE API CALL ──
      uiFeedback.showLoader();

      final localTrip = await _tokenService.getActiveTrip();
      if (localTrip == null) {
        uiFeedback.hideLoader();
        uiFeedback.showError('You must start a shift before logging a visit.');
        return;
      }

      final activeTripId = localTrip['id'] as int;
      final baseApi = BaseApiService(Dio(), uiFeedback, _tokenService);
      final tripService = TripService(baseApi);

      final ping = Ping(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        capturedAt: DateTime.now(),
      );

      await tripService.sendPing(activeTripId, ping, leadId: lead.leadId);

      uiFeedback.hideLoader();
      uiFeedback.showSuccess('Visit to ${lead.name} logged successfully!');

    } catch (e) {
      uiFeedback.hideLoader();
      uiFeedback.showError('Failed to log visit. Make sure your GPS is enabled.');
    }
  }

  // ── LOG VISIT TO EXISTING DEALER ──
  Future<void> _logVisitToExistingDealer(Dealer dealer) async {
    final uiFeedback = UiFeedbackService();
    uiFeedback.showLoader();

    try {
      final pos = await SingleLocationReader.getCurrentLocation();

      // ── 0. FAKE GPS CHECK ──
      if (pos.isMocked) {
        uiFeedback.hideLoader();
        uiFeedback.showError('Fake Location detected. Please disable mock locations to check in.');
        return;
      }

      // No perimeter check here since dealers do not have latitude/longitude stored
      uiFeedback.hideLoader();

      // ── 1. SHOW CONFIRMATION ──
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Log Visit', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Do you want to geotag a visit to ${dealer.dealerName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Log Visit'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // ── 2. PROCESS THE API CALL ──
      uiFeedback.showLoader();
      final localTrip = await _tokenService.getActiveTrip();
      if (localTrip == null) {
        uiFeedback.hideLoader();
        uiFeedback.showError('You must start a shift before logging a visit.');
        return;
      }

      final activeTripId = localTrip['id'] as int;
      final baseApi = BaseApiService(Dio(), uiFeedback, _tokenService);
      final tripService = TripService(baseApi);

      final ping = Ping(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        capturedAt: DateTime.now(),
      );

      await tripService.sendPing(activeTripId, ping, dealerId: dealer.dealerId);

      uiFeedback.hideLoader();
      uiFeedback.showSuccess('Visit to ${dealer.dealerName} logged successfully!');

    } catch (e) {
      uiFeedback.hideLoader();
      uiFeedback.showError('Failed to log visit. Make sure your GPS is enabled.');
    }
  }

  void _showAddLeadForm() async {
    final localTrip = await _tokenService.getActiveTrip();
    if (localTrip == null) {
      UiFeedbackService().showError('You must start a shift before adding a lead.');
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddLeadForm(
        leadService: _leadService,
        onSuccess: _fetchData,
      ),
    );
  }

  void _showAddDealerForm() async {
    final localTrip = await _tokenService.getActiveTrip();
    if (localTrip == null) {
      UiFeedbackService().showError('You must start a shift before adding a dealer.');
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddDealerForm(
        dealerService: _dealerService,
        onSuccess: _fetchData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant.withOpacity(0.4), width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: scheme.primary,
                unselectedLabelColor: scheme.onSurfaceVariant,
                indicatorColor: scheme.primary,
                tabs: const [
                  Tab(text: 'Leads'),
                  Tab(text: 'Dealers'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // --- LEADS TAB ---
                  Column(
                    children: [
                      // ── SEARCH BAR ──
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterLeads,
                          decoration: InputDecoration(
                            hintText: 'Search leads...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: scheme.surfaceContainerLow,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _fetchData,
                          child: filteredLeads.isEmpty
                              ? _EmptyState(icon: Icons.people_outline_rounded, message: 'No leads found.')
                              : ListView.builder(
                            padding: const EdgeInsets.only(top: 4, bottom: 88),
                            itemCount: filteredLeads.length,
                            itemBuilder: (context, index) {
                              final lead = filteredLeads[index];
                              return _EntryCard(
                                icon: Icons.person_rounded,
                                title: lead.name,
                                subtitleLines: [
                                  _SubtitleLine(icon: Icons.phone_rounded, text: lead.mobileNumber),
                                  _SubtitleLine(
                                    icon: Icons.location_on_rounded,
                                    text: lead.location.isNotEmpty ? lead.location : 'No location provided',
                                  ),
                                ],
                                onTap: () => _logVisitToExistingLead(lead),
                                onTrailingTap: () => _logVisitToExistingLead(lead),
                                trailingIcon: Icons.add_location_alt_rounded,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  // --- DEALERS TAB ---
                  RefreshIndicator(
                    onRefresh: _fetchData,
                    child: dealers.isEmpty
                        ? _EmptyState(icon: Icons.storefront_outlined, message: 'No dealers found.')
                        : ListView.builder(
                      padding: const EdgeInsets.only(top: 12, bottom: 88),
                      itemCount: dealers.length,
                      itemBuilder: (context, index) {
                        final dealer = dealers[index];
                        return _EntryCard(
                          icon: Icons.storefront_rounded,
                          title: dealer.dealerName,
                          subtitleLines: [
                            _SubtitleLine(icon: Icons.phone_rounded, text: dealer.mobileNo),
                            _SubtitleLine(
                              icon: Icons.location_on_rounded,
                              text: dealer.city.isNotEmpty ? dealer.city : 'No city provided',
                            ),
                          ],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DealerDetailsScreen(dealer: dealer),
                              ),
                            );
                          },
                          onTrailingTap: () => _logVisitToExistingDealer(dealer),
                          trailingIcon: Icons.add_location_alt_rounded,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _tabController.index == 0 ? _showAddLeadForm : _showAddDealerForm,
          icon: const Icon(Icons.add),
          label: Text(_tabController.index == 0 ? 'Add Lead' : 'Add Dealer'),
        )
    );
  }
}

// ── Small data holder for a subtitle row (icon + text) ──
class _SubtitleLine {
  final IconData icon;
  final String text;
  const _SubtitleLine({required this.icon, required this.text});
}

// ── Shared card used by both the Leads and Dealers lists ──
class _EntryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_SubtitleLine> subtitleLines;
  final VoidCallback? onTap;
  final VoidCallback? onTrailingTap;
  final IconData? trailingIcon;

  const _EntryCard({
    required this.icon,
    required this.title,
    required this.subtitleLines,
    this.onTap,
    this.onTrailingTap,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap, // Opens Details Screen (or logs visit for Leads)
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: scheme.onPrimaryContainer, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      for (final line in subtitleLines) ...[
                        Row(
                          children: [
                            Icon(line.icon, size: 12, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                line.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                        if (line != subtitleLines.last) const SizedBox(height: 2),
                      ],
                    ],
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  if (onTrailingTap != null)
                    IconButton(
                      icon: Icon(trailingIcon, size: 24, color: scheme.primary),
                      onPressed: onTrailingTap,
                    )
                  else
                    Icon(trailingIcon, size: 24, color: scheme.primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty state shown when a tab has no data ──
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: scheme.onSurfaceVariant.withOpacity(0.5)),
                const SizedBox(height: 12),
                Text(message, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
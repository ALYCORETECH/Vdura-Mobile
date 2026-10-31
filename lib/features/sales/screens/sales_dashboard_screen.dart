// lib/features/sales/screens/sales_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:sales_management/core/theme/theme.dart';
import 'package:sales_management/features/attendance/screen/attendance_screen.dart';
import 'package:sales_management/features/leads/screens/leads_screen.dart';
import 'package:sales_management/features/profile/screens/profile_screen.dart';

class SalesDashboardScreen extends StatefulWidget {
  const SalesDashboardScreen({super.key});

  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  int _currentIndex = 0;

  // ── 1. Helper getter to determine the AppBar title ──
  String get _appBarTitle {
    switch (_currentIndex) {
      case 0:
        return 'Trips';
      case 1:
        return 'Leads';
      case 2:
        return 'Profile'; // ⬅️ NEW TITLE
      default:
        return 'Trips';
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<VanguardeColors>()!;
    final scheme = Theme.of(context).colorScheme;

    // ── 2. Add ProfileScreen to the indexed stack ──
    final List<Widget> screens = [
      const AttendanceScreen(),
      const LeadsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          _appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: colors.fieldBorder, height: 1),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(color: colors.fieldBorder, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: scheme.surface,
          elevation: 0,
          selectedItemColor: scheme.primary,
          unselectedItemColor: colors.subtitle,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.route_outlined),
              ),
              label: 'Trips',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.people_alt_outlined),
              ),
              label: 'Leads',
            ),
            // ── 3. Add the Profile icon to the navigation bar ──
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_outline_rounded),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
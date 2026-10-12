import 'package:flutter/material.dart';

import 'screens/dashboard_page.dart';
import 'screens/testing_page.dart';
import 'screens/protection_page.dart';
import 'screens/recovery_page.dart';
import 'screens/devices_page.dart';
import 'screens/jobs_page.dart';
import 'screens/vulnerabilities_page.dart';
import 'screens/logs_page.dart';
import 'screens/settings_page.dart';
import 'screens/advanced_scan_page.dart';

const Color bg = Color(0xFF0B1017);
const Color panel = Color(0xFF151E29);
const Color accent = Color(0xFF21D6A1);
const Color muted = Color(0xFF8D9AAA);
const Color blue = Color(0xFF58A6FF);
const Color orange = Color(0xFFFFBD69);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NathrApp());
}

class NathrApp extends StatelessWidget {
  const NathrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نَذْر | NATHR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: blue,
          surface: panel,
          error: Color(0xFFFF7777),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: panel,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: panel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF283747),
            ),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const NathrHome(),
    );
  }
}

class NathrHome extends StatefulWidget {
  const NathrHome({super.key});

  @override
  State<NathrHome> createState() => _NathrHomeState();
}

class _NathrHomeState extends State<NathrHome> {
  int _selected = 0;

  static const List<_NavItem> _items = [
    _NavItem('الرئيسية', Icons.dashboard_rounded),
    _NavItem('الاختبار الأمني', Icons.radar_rounded),
    _NavItem('الحماية والتحليل', Icons.shield_rounded),
    _NavItem('التدخل والاستعادة', Icons.health_and_safety_rounded),
    _NavItem('الأجهزة', Icons.devices_rounded),
    _NavItem('المهام', Icons.assignment_rounded),
    _NavItem('الثغرات الأمنية', Icons.bug_report_rounded),
    _NavItem('السجلات والتقارير', Icons.receipt_long_rounded),
    _NavItem('الإعدادات', Icons.settings_rounded),
    _NavItem('الباحث الأمني', Icons.biotech_rounded),
  ];

  void _openPage(int index) {
    if (index < 0 || index >= _items.length) return;
    setState(() => _selected = index);
  }

  List<Widget> _buildPages() {
    return [
      DashboardPage(onOpen: _openPage),
      const TestingPage(),
      const ProtectionPage(),
      const RecoveryPage(),
      const DevicesPage(),
      const JobsPage(),
      const VulnerabilitiesPage(),
      const LogsPage(),
      const SettingsPage(),
      const AdvancedScanPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();
    final showBottomNavigation = _selected <= 3;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accent.withOpacity(0.3),
                ),
              ),
              child: const Icon(
                Icons.security_rounded,
                color: accent,
                size: 23,
              ),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'نَذْر | NATHR',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'مركز الأمن والتحليل',
                    style: TextStyle(
                      color: muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'السجلات والتقارير',
            onPressed: () => _openPage(7),
            icon: const Icon(Icons.receipt_long_rounded),
          ),
          IconButton(
            tooltip: 'الباحث الأمني',
            onPressed: () => _openPage(9),
            icon: const Icon(Icons.biotech_rounded),
          ),
          IconButton(
            tooltip: 'الإعدادات',
            onPressed: () => _openPage(8),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(
        backgroundColor: panel,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                decoration: const BoxDecoration(
                  color: bg,
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFF263746),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: accent.withOpacity(0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        color: accent,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'نَذْر | NATHR',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'منصة الاختبار والحماية والاستعادة',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.phone_android_rounded,
                            color: accent,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'واجهة محلية',
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final active = _selected == index;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: ListTile(
                        selected: active,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        selectedTileColor: accent.withOpacity(0.1),
                        leading: Icon(
                          item.icon,
                          color: active ? accent : muted,
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            color: active ? accent : Colors.white,
                            fontWeight: active
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        trailing: active
                            ? const Icon(
                                Icons.circle,
                                color: accent,
                                size: 7,
                              )
                            : null,
                        onTap: () {
                          _openPage(index);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
              const Divider(color: Color(0xFF263746)),
              const Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'NATHR  •  الإصدار 1.0.0',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selected,
          children: pages,
        ),
      ),
      bottomNavigationBar: showBottomNavigation
          ? NavigationBar(
              height: 68,
              backgroundColor: panel,
              indicatorColor: accent.withOpacity(0.15),
              selectedIndex: _selected,
              onDestinationSelected: _openPage,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(
                    Icons.dashboard_rounded,
                    color: accent,
                  ),
                  label: 'الرئيسية',
                ),
                NavigationDestination(
                  icon: Icon(Icons.radar_rounded),
                  selectedIcon: Icon(
                    Icons.radar_rounded,
                    color: accent,
                  ),
                  label: 'الاختبار',
                ),
                NavigationDestination(
                  icon: Icon(Icons.shield_outlined),
                  selectedIcon: Icon(
                    Icons.shield_rounded,
                    color: accent,
                  ),
                  label: 'الحماية',
                ),
                NavigationDestination(
                  icon: Icon(Icons.health_and_safety_outlined),
                  selectedIcon: Icon(
                    Icons.health_and_safety_rounded,
                    color: accent,
                  ),
                  label: 'الاستعادة',
                ),
              ],
            )
          : null,
    );
  }
}

class _NavItem {
  final String title;
  final IconData icon;

  const _NavItem(this.title, this.icon);
}
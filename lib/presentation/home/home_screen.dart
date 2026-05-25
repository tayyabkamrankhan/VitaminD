import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/uv_data_provider.dart';
import '../../providers/usb_provider.dart';
import 'widgets/home_widgets.dart';
import '../monitor/monitor_screen.dart';
import '../analytics/analytics_screen.dart';
import '../health_hub/health_hub_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  final _screens = const [
    _HomeTab(), MonitorScreen(), AnalyticsScreen(), HealthHubScreen(), SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final uv   = context.read<UVDataProvider>();
      uv.setProfile(auth.profile);
      if (auth.profile != null) uv.loadTodayData(auth.profile!.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedTab, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border, width: 0.5))),
        child: BottomNavigationBar(
          currentIndex: _selectedTab,
          onTap: (i) => setState(() => _selectedTab = i),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined),    activeIcon: Icon(Icons.home_rounded),  label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.sensors_outlined),  activeIcon: Icon(Icons.sensors),       label: 'Monitor'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined),activeIcon: Icon(Icons.bar_chart),     label: 'Analytics'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite_outline),  activeIcon: Icon(Icons.favorite),      label: 'Health'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings),      label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uv   = context.watch<UVDataProvider>();
    final name = auth.profile?.name.split(' ').first ?? 'there';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          if (auth.profile != null) await uv.loadTodayData(auth.profile!.uid);
        },
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Good ${_greeting()},',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  Text(name, style: Theme.of(context).textTheme.headlineMedium),
                ]),
                const _USBIndicator(),
              ]),
              const SizedBox(height: 28),
              VitDRingWidget(
                totalIU:       uv.totalIU,
                synthesizedIU: uv.synthesizedIU,
                supplementIU:  uv.supplementIU,
                status:        uv.status,
                progressRatio: uv.progressRatio,
                age:           auth.profile?.age ?? 25,
              ),
              const SizedBox(height: 24),
              DailySummaryCard(
                uvIndex:        uv.currentUVIndex,
                sessionMinutes: uv.sessionMinutes,
                synthesizedIU:  uv.synthesizedIU,
                supplementIU:   uv.supplementIU,
              ),
              const SizedBox(height: 16),
              const WeatherCardWidget(),
              const SizedBox(height: 16),
              WeeklyBarChart(
                sessions: uv.weeklySessions,
                age:      auth.profile?.age ?? 25,
              ),
              const SizedBox(height: 16),
              AiTipCard(
                uvIndex: uv.currentUVIndex,
                totalIU: uv.totalIU,
                status:  uv.status,
                city:    auth.profile?.city ?? 'Rawalpindi',
                age:     auth.profile?.age ?? 25,
              ),
              const SizedBox(height: 24),
            ]),
          )),
        ]),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

// ── USB indicator chip ────────────────────────────────────────────────────────

class _USBIndicator extends StatelessWidget {
  const _USBIndicator();

  @override
  Widget build(BuildContext context) {
    final usb = context.watch<USBProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: usb.connected ? AppColors.statusNormalBg : AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: usb.connected ? AppColors.statusNormal : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.usb_rounded,
            size: 14,
            color: usb.connected ? AppColors.statusNormal : AppColors.textMuted),
        const SizedBox(width: 5),
        Text(
          usb.connected ? 'Connected' : 'No device',
          style: TextStyle(
              fontSize: 11,
              color: usb.connected ? AppColors.statusNormal : AppColors.textMuted),
        ),
      ]),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/uv_data_provider.dart';
import '../compiler/compiler_screen.dart';
import 'widgets/symptom_checker.dart';
import 'widgets/supplement_tracker.dart';
import 'widgets/doctor_report_widget.dart';

class HealthHubScreen extends StatelessWidget {
  const HealthHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Health Hub'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Symptoms'),
              Tab(text: 'Supplements'),
              Tab(text: 'Report'),
              Tab(text: 'Command Mode'),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
          ),
        ),
        body: const TabBarView(children: [
          SymptomChecker(),
          SupplementTracker(),
          DoctorReportWidget(),
          CompilerScreen(),
        ]),
      ),
    );
  }
}

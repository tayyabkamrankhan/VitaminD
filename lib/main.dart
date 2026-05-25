import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'data/datasources/local/hive_datasource.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAnalytics.instance.logAppOpen().catchError((_) {});

  // This replaces Hive.initFlutter() and opens the required boxes
  await HiveDatasource.init(); 

  runApp(const VitaminDApp());
}

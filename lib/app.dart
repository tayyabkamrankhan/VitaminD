import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/uv_data_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/user_provider.dart';
import 'providers/usb_provider.dart';
import 'providers/social_provider.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/health_repository.dart';
import 'data/repositories/weather_repository.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/onboarding/onboarding_screen.dart';
import 'presentation/home/home_screen.dart';

class VitaminDApp extends StatelessWidget {
  const VitaminDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthRepository()),
        Provider(create: (_) => HealthRepository()),
        Provider(create: (_) => WeatherRepository()),
        ChangeNotifierProxyProvider<AuthRepository, AuthProvider>(
          create: (c) => AuthProvider(c.read<AuthRepository>()),
          update: (_, repo, prev) => prev ?? AuthProvider(repo),
        ),
        ChangeNotifierProxyProvider<HealthRepository, UVDataProvider>(
          create: (c) => UVDataProvider(c.read<HealthRepository>()),
          update: (_, repo, prev) => prev ?? UVDataProvider(repo),
        ),
        ChangeNotifierProxyProvider<WeatherRepository, WeatherProvider>(
          create: (c) => WeatherProvider(c.read<WeatherRepository>()),
          update: (_, repo, prev) => prev ?? WeatherProvider(repo),
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => USBProvider()),
        ChangeNotifierProvider(create: (_) => SocialProvider()),
      ],
      child: MaterialApp(
        title: 'Vitamin D Sensor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _AuthGate(),
        routes: {
          '/login':      (_) => const LoginScreen(),
          '/onboarding': (_) => const OnboardingScreen(),
          '/home':       (_) => const HomeScreen(),
        },
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) return const LoginScreen();

    final p = auth.profile;
    if (p == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If profile is incomplete (default values from signup) -> onboarding
    final needsOnboarding = p.city == 'Lahore' && p.age == 25 &&
        p.createdAt.isAfter(DateTime.now().subtract(const Duration(minutes: 2)));

    return needsOnboarding ? const OnboardingScreen() : const HomeScreen();
  }
}

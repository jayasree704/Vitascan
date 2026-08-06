import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitad_ai/domain/models/scan_result.dart';
import '../../features/auth/screens/get_started_screen.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/auth/screens/sign_up_screen.dart';
import '../../features/auth/screens/profile_completion_screen.dart';
import '../../features/home/screens/home_dashboard_screen.dart';
import '../../features/scan/screens/scan_screen.dart';
import '../../features/results/screens/analysis_results_screen.dart';
import '../../features/history/screens/scan_history_screen.dart';
import '../../features/profile/screens/user_profile_screen.dart';
import '../../features/patient/screens/patient_details_screen.dart';

class AppRoutes {
  static const getStarted = '/';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const profileCompletion = '/complete-profile';
  static const home = '/home';
  static const scan = '/scan';
  static const analysisResults = '/results';
  static const history = '/history';
  static const profile = '/profile';
  static const patientDetails = '/patient-details';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.getStarted,
        name: 'getStarted',
        builder: (context, state) => const GetStartedScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        name: 'signIn',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        name: 'signUp',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileCompletion,
        name: 'profileCompletion',
        builder: (context, state) => const ProfileCompletionScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomeDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.scan,
            name: 'scan',
            builder: (context, state) => const ScanScreen(),
          ),
          GoRoute(
            path: AppRoutes.analysisResults,
            name: 'analysisResults',
            builder: (context, state) {
              final result = state.extra as ScanResult?;
              return AnalysisResultsScreen(result: result);
            },
          ),
          GoRoute(
            path: AppRoutes.history,
            name: 'history',
            builder: (context, state) => const ScanHistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const UserProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.patientDetails,
            name: 'patientDetails',
            builder: (context, state) {
              final imageFile = state.extra as File?;
              return PatientDetailsScreen(imageFile: imageFile);
            },
          ),
        ],
      ),
    ],
  );
});

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<String> _routes = [
    AppRoutes.home,
    AppRoutes.scan,
    AppRoutes.history,
    AppRoutes.profile,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          context.go(_routes[index]);
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.document_scanner_outlined),
              selectedIcon: Icon(Icons.document_scanner),
              label: 'Scan'),
          NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'History'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

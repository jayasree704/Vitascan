import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: VitaScanApp()));
}

class VitaScanApp extends ConsumerStatefulWidget {
  const VitaScanApp({super.key});

  @override
  ConsumerState<VitaScanApp> createState() => _VitaScanAppState();
}

class _VitaScanAppState extends ConsumerState<VitaScanApp> {
  @override
  void initState() {
    super.initState();
    // Listen for Supabase OAuth deep-link sign-in events
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        final user = session.user;
        final router = ref.read(appRouterProvider);

        // Verify if user email is allowed
        if (!AppConfig.isEmailAllowed(user.email)) {
          await Supabase.instance.client.auth.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid credentials'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        // Check if user signed in via Google (OAuth provider)
        final isGoogleUser = user.appMetadata['provider'] == 'google';

        if (isGoogleUser) {
          // Check if profile is complete (has gender & DOB)
          final supabaseService = ref.read(supabaseServiceProvider);
          final incomplete = await supabaseService.isProfileIncomplete(user.id);
          if (incomplete) {
            router.go(AppRoutes.profileCompletion);
            return;
          }
        }
        router.go(AppRoutes.home);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'VitaScan',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}


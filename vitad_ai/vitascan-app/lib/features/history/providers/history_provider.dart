import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/scan_result.dart';
import '../../auth/providers/auth_provider.dart';

/// Provides the user's real scan history from Supabase.
/// Falls back to an empty list if the user is not logged in or on error.
final scanHistoryProvider = FutureProvider<List<ScanResult>>((ref) async {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return [];
  }

  try {
    final supabaseService = ref.watch(supabaseServiceProvider);
    final remoteScans = await supabaseService.fetchUserScans(user.id);
    // Sort newest-first
    remoteScans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return remoteScans;
  } catch (_) {
    return [];
  }
});

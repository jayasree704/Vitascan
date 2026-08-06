import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/user_profile.dart';
import '../../auth/providers/auth_provider.dart';

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final supabaseService = ref.watch(supabaseServiceProvider);
  return await supabaseService.fetchProfile(user.id);
});

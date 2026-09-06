import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe_model.dart';
import '../../core/services/supabase_service.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) => SupabaseService());

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final uid = SupabaseService.currentUserId;
  if (uid == null) return null;
  return ref.read(supabaseServiceProvider).getProfile(uid);
});

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<UserModel?>>((ref) {
  return ProfileNotifier(ref.read(supabaseServiceProvider));
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final SupabaseService _service;

  ProfileNotifier(this._service) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) {
      state = const AsyncValue.data(null);
      return;
    }
    try {
      final profile = await _service.getProfile(uid);
      state = AsyncValue.data(profile);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> update(Map<String, dynamic> data) async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    await _service.updateProfile(uid, data);
    await _load();
  }

  void refresh() => _load();
}

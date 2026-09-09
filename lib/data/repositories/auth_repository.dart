import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/auth_datasource.dart';
import '../datasources/profile_datasource.dart';
import '../datasources/dashboard_datasource.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/standup.dart';

class AuthRepository {
  final AuthDatasource _authDatasource;
  final ProfileDatasource _profileDatasource;
  final DashboardDatasource _dashboardDatasource;

  AuthRepository(SupabaseClient client)
      : _authDatasource = AuthDatasource(client),
        _profileDatasource = ProfileDatasource(client),
        _dashboardDatasource = DashboardDatasource(client);

  User? get currentUser => _authDatasource.currentUser;
  Stream<AuthState> get authStateChanges => _authDatasource.authStateChanges;
  // Note: AuthState here is gotrue's AuthState

  Future<Profile?> getCurrentProfile() async {
    return await _profileDatasource.getCurrentProfile();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    await _authDatasource.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );
  }

  Future<Profile?> signIn({
    required String email,
    required String password,
  }) async {
    await _authDatasource.signIn(email: email, password: password);
    return await getCurrentProfile();
  }

  Future<void> signOut() async {
    await _authDatasource.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _authDatasource.resetPassword(email);
  }

  Future<void> createCompany({
    required String name,
    required String slug,
    String? industry,
  }) async {
    await _profileDatasource.createCompany(
      name: name,
      slug: slug,
      industry: industry,
    );
  }

  /// Attach the freshly-signed-up user to the company that invited them.
  Future<Map<String, dynamic>> acceptInvite(String email) async {
    return await _profileDatasource.acceptInvite(email);
  }

  Future<Standup?> getTodayStandup() async {
    final profile = await getCurrentProfile();
    if (profile == null) return null;
    return await _dashboardDatasource.getTodayStandup(profile.id);
  }
}

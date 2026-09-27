import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ResearcherAuth {
  bool get signedIn;
  Stream<bool> get changes;
  Future<void> signIn(String email, String password);
  Future<void> signOut();
}

final class SupabaseResearcherAuth implements ResearcherAuth {
  final SupabaseClient client;
  SupabaseResearcherAuth(this.client);
  @override
  bool get signedIn => client.auth.currentUser != null;
  @override
  Stream<bool> get changes =>
      client.auth.onAuthStateChange.map((event) => event.session != null);
  @override
  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signOut() => client.auth.signOut();
}

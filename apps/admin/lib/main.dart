import 'package:flutter/material.dart';
import 'package:dataset_schema/dataset_schema.dart';
import 'package:experiment_models/client_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_gate.dart';
import 'auth/researcher_auth.dart';
import 'studies.dart';
import 'study_home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SupabaseClient? client;
  try {
    final config = ClientConfig.fromEnvironment(const {
      'APP_ENV': String.fromEnvironment('APP_ENV', defaultValue: 'production'),
      'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL'),
      'SUPABASE_ANON_KEY': String.fromEnvironment('SUPABASE_ANON_KEY'),
      'SUPABASE_EDGE_FUNCTIONS_URL': String.fromEnvironment(
        'SUPABASE_EDGE_FUNCTIONS_URL',
      ),
      'ENABLE_DEBUG_TOOLS': String.fromEnvironment(
        'ENABLE_DEBUG_TOOLS',
        defaultValue: 'false',
      ),
    });
    await Supabase.initialize(
      url: config.supabaseUrl.toString(),
      publishableKey: config.anonKey!,
      debug: false,
    );
    client = Supabase.instance.client;
  } catch (_) {
    /* Configuration failure leaves sign-in disabled. No fake account. */
  }
  runApp(CollectorApp(client: client));
}

class CollectorApp extends StatelessWidget {
  final SupabaseClient? client;
  final ResearcherAuth? auth;
  final StudyRepository? studies;
  const CollectorApp({super.key, this.client, this.auth, this.studies});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Research Console',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: const Color(0xff176b60),
      useMaterial3: true,
    ),
    home: ResearcherAuthGate(
      auth: auth ?? (client == null ? null : SupabaseResearcherAuth(client!)),
      home: (_) => StudyHome(
        repository: studies ?? SupabaseStudyRepository(client!),
        client: client,
      ),
    ),
  );
}

const supportedSchemaVersion = packageSchemaVersion;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app/lumen_app.dart';
import 'src/app/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseConfig = loadSupabaseClientConfig();
  if (supabaseConfig.enabled) {
    await Supabase.initialize(
      url: supabaseConfig.url,
      anonKey: supabaseConfig.publishableKey,
    );
  }
  runApp(const ProviderScope(child: LumenApp()));
}

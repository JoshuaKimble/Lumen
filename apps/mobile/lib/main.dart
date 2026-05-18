import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app/lumen_app.dart';
import 'src/app/supabase_config.dart';

void main() {
  loadSupabaseClientConfig();
  runApp(const ProviderScope(child: LumenApp()));
}

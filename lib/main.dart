import 'package:flutter/material.dart';
import 'package:itouru/login_option.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dlzlnebdpxrmqnelrbfm.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRsemxuZWJkcHhybXFuZWxyYmZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwMTExNDksImV4cCI6MjA3MzU4NzE0OX0.GUUpkHK5pGBxPgUNdU3OlzKXmpIoskxEofFG7jUYSuw',
  );
  runApp(const MaterialApp(home: LoginOptionPage()));
}

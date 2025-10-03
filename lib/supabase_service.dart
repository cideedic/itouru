import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> fetchUser(String email) async {
    final response = await supabase
        .from('users')
        .select()
        .eq('email', email)
        .maybeSingle(); // Get one user

    if (response == null) return null;
    return response;
  }
}

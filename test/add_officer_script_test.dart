import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('Add Officer to Supabase', () async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );

    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.auth.signUp(
        email: 'officer@gmail.com',
        password: 'officer123',
        data: {
          'full_name': 'Agriculture Officer',
          'district': 'Colombo',
        },
      );
      print('User added successfully: ${response.user?.id}');
    } catch (e) {
      print('Failed to add user: $e');
    }
  }, skip: 'Manual script: creates a real account on the shared Supabase project. Run it on purpose only.');
}

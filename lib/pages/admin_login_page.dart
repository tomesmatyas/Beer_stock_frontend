import 'package:flutter/material.dart';
// Uprav si import podle tvé cesty v projektu
import '../services/api_service.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final ApiService apiService = ApiService();
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  void _login() async {
    try {
      final response = await apiService.login(userCtrl.text, passCtrl.text);
      if (response != null && response['role'] == 'ADMIN') {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/admin-editor');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Přístup odepřen. Nemáte roli ADMIN.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Chyba spojení: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.admin_panel_settings,
              size: 60,
              color: Colors.blueGrey,
            ),
            const SizedBox(height: 20),
            const Text(
              'Přihlášení správce',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(
                labelText: 'Jméno',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Heslo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: _login,
              child: const Text('PŘIHLÁSIT SE'),
            ),
          ],
        ),
      ),
    );
  }
}

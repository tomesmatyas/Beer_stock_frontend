import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/auth_cubit.dart';
import '../services/api_service.dart'; // Nesmíme zapomenout na import API

import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final ApiService apiService = ApiService();
  bool isLoading = false; // Přidáme načítací kolečko

  @override
  void initState() {
    super.initState();
    // Povolí všechny orientace pro přihlašovací obrazovku
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _attemptLogin() async {
    // Kontrola, jestli nejsou pole prázdná
    if (userController.text.isEmpty || passController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vyplňte jméno i heslo!')));
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Zkusíme se přihlásit přes Django API
      final userData = await apiService.login(
        userController.text,
        passController.text,
      );

      // 2. Pokud to projde (nespadne to do catch), pustíme uživatele do aplikace
      if (mounted) {
        context.read<AuthCubit>().login(
          userData['id'],
          userData['username'],
          userData['role'], // Django nám pošle 'ADMIN' nebo 'STAFF'
        );
      }
    } catch (e) {
      // 3. Pokud je heslo špatně, ukážeme červenou chybovou hlášku
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Card(
          elevation: 8,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🍺 PIVNÍ SKLAD',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: userController,
                  decoration: const InputDecoration(
                    labelText: 'Uživatelské jméno',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passController,
                  obscureText: true, // Skryje heslo
                  decoration: const InputDecoration(
                    labelText: 'Heslo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 32),

                // Zobrazíme buď načítací kolečko, nebo tlačítko
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _attemptLogin,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 55),
                          backgroundColor: Colors.amber, // Pivní barva!
                          foregroundColor: Colors.black,
                        ),
                        child: const Text(
                          'PŘIHLÁSIT SE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

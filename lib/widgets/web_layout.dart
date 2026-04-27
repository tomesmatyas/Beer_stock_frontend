import 'package:flutter/material.dart';

class WebLayout extends StatelessWidget {
  final Widget child;
  const WebLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        toolbarHeight: 80,
        title: InkWell(
          onTap: () => Navigator.pushReplacementNamed(context, '/'),
          child: const Row(
            children: [
              Text('🍺 ', style: TextStyle(fontSize: 30)),
              Text(
                'PIVNÍ SKLAD',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            child: const Text(
              'DOMŮ & NOVINKY',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/kontakt'),
            child: const Text(
              'KONTAKT',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(width: 20),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 20.0,
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                elevation: 5,
                padding: const EdgeInsets.symmetric(horizontal: 30),
              ),
              onPressed: () => Navigator.pushNamed(context, '/rezervace'),
              child: const Text(
                'REZERVOVAT SUDY',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.grey),
            tooltip: 'Pro správce',
            onPressed: () => Navigator.pushNamed(context, '/login'),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: child,
    );
  }
}

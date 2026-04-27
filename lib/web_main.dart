import 'package:flutter/material.dart';

import 'widgets/web_layout.dart';
import 'pages/home_page.dart';
import 'pages/contact_page.dart';
import 'pages/reservation_page.dart';
import 'pages/admin_login_page.dart';
import 'pages/admin_editor_page.dart';

void main() {
  runApp(const ZazemiWebApp());
}

class ZazemiWebApp extends StatelessWidget {
  const ZazemiWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pivní Sklad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WebLayout(child: HomePage()),
        '/kontakt': (context) => const WebLayout(child: ContactPage()),
        '/rezervace': (context) => const WebLayout(child: ReservationPage()),
        '/login': (context) => const WebLayout(child: AdminLoginPage()),
        '/admin-editor': (context) => const WebLayout(child: AdminEditorPage()),
      },
    );
  }
}

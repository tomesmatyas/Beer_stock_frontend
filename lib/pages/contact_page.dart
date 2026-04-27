import 'package:flutter/material.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Kontakt a Otevírací doba',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text('📍 Adresa: Lično 123', style: TextStyle(fontSize: 20)),
          Text('📞 Telefon: +420 123 456 789', style: TextStyle(fontSize: 20)),
          SizedBox(height: 40),
          Text(
            'Otevřeno pátky a soboty dle domluvy.',
            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

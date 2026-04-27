import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class AdminEditorPage extends StatefulWidget {
  const AdminEditorPage({super.key});

  @override
  State<AdminEditorPage> createState() => _AdminEditorPageState();
}

class _AdminEditorPageState extends State<AdminEditorPage> {
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController contentCtrl = TextEditingController();

  void _savePost() {
    if (titleCtrl.text.isEmpty || contentCtrl.text.isEmpty) return;

    setState(() {
      newsPosts.add({
        "title": titleCtrl.text,
        "date": "Dnes",
        "content": contentCtrl.text,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Příspěvek zveřejněn!'),
        backgroundColor: Colors.green,
      ),
    );
    titleCtrl.clear();
    contentCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(32),
        child: Card(
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Napsat nový příspěvek na web',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      label: Text('ADMIN REŽIM'),
                      backgroundColor: Colors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Nadpis příspěvku',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: contentCtrl,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText:
                        'Text příspěvku (aktuality, slevy, otevírací doba...)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/'),
                      child: const Text('Zpět na web'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 20,
                        ),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.publish),
                      label: const Text(
                        'ZVEŘEJNIT NA WEBU',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _savePost,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

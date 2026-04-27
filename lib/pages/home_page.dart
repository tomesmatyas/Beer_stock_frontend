import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../widgets/image_carousel.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(
            height: 400,
            width: double.infinity,
            child: ImageCarousel(),
          ),
          const SizedBox(height: 40),
          const Text(
            'AKTUALITY A NOVINKY',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: newsPosts.length,
              itemBuilder: (context, index) {
                final post = newsPosts[newsPosts.length - 1 - index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['title']!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          post['date']!,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const Divider(height: 30, thickness: 1),
                        Text(
                          post['content']!,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

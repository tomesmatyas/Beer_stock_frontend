import 'package:flutter/material.dart';
import 'dart:async';

class ImageCarousel extends StatefulWidget {
  const ImageCarousel({super.key});

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<String> images = [
    'https://images.unsplash.com/photo-1600788886242-5c96aabe3757?q=80&w=1200&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1575037614876-c385806ac5b0?q=80&w=1200&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1505075936528-912a76f2df79?q=80&w=1200&auto=format&fit=crop',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < images.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemBuilder: (context, index) {
            return Image.network(
              images[index],
              fit: BoxFit.cover,
              width: double.infinity,
            );
          },
        ),
        Container(color: Colors.black.withOpacity(0.4)),
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'NEJLEPŠÍ PIVNÍ SKLAD V OKOLÍ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Sudy připravené k okamžité rezervaci.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

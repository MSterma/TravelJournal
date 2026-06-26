import 'dart:io';
import 'package:flutter/material.dart';

import 'image_placeholder.dart';

enum PhotoSource { file, network }

class PhotoViewer extends StatefulWidget {
  const PhotoViewer({
    super.key,
    required this.photos,
    this.initialIndex = 0,
    required this.source,
  });

  final List<String> photos;
  final int initialIndex;
  final PhotoSource source;

  static void show(
    BuildContext context, {
    required List<String> photos,
    int initialIndex = 0,
    required PhotoSource source,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewer(
          photos: photos,
          initialIndex: initialIndex,
          source: source,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.photos.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final path = widget.photos[index];
          final isPlaceholder = path == '__PLACEHOLDER__';
          final exists =
              widget.source == PhotoSource.network ||
              (!isPlaceholder && File(path).existsSync());

          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: exists
                  ? (widget.source == PhotoSource.file
                        ? Image.file(File(path), fit: BoxFit.contain)
                        : Image.network(
                            path,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.error,
                                  color: Colors.white,
                                  size: 50,
                                ),
                          ))
                  : const ImagePlaceholder(width: 300, height: 300),
            ),
          );
        },
      ),
    );
  }
}

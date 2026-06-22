import 'package:flutter/material.dart';

class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({
    super.key,
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[800],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            color: Colors.grey[500],
            size: width * 0.4,
          ),
          const SizedBox(height: 4),
          Text(
            'Brak zdjęcia',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

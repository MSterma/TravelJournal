import 'package:flutter/material.dart';

class TravelsControls extends StatelessWidget {
  const TravelsControls({
    super.key,
    required this.onAddNote,
    required this.onAddWantToGo,
    required this.onTestNotification,
  });

  final VoidCallback onAddNote;
  final VoidCallback onAddWantToGo;
  final VoidCallback onTestNotification;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 60,
      left: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue[700],
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: onAddNote,
            ),
            const VerticalDivider(width: 1, color: Colors.white24),
            IconButton(
              icon: const Icon(Icons.explore, color: Colors.white),
              onPressed: onAddWantToGo,
            ),
            const VerticalDivider(width: 1, color: Colors.white24),
            IconButton(
              icon: const Icon(Icons.notifications_active, color: Colors.white),
              onPressed: onTestNotification,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.progress,
    required this.target,
    this.showProgressBar = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int progress;
  final int target;
  final bool showProgressBar;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = progress >= target;
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (showProgressBar && !isUnlocked)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progress / target,
                    minHeight: 4,
                  ),
                  const SizedBox(height: 2),
                  Text('$progress/$target',
                      style: const TextStyle(fontSize: 8)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

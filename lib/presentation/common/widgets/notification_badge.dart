import 'package:flutter/material.dart';

/// Notification Badge Widget - displays a badge with count
class NotificationBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final bool showZero;

  const NotificationBadge({
    super.key,
    required this.child,
    required this.count,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!showZero && count <= 0) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -8,
          top: -8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}


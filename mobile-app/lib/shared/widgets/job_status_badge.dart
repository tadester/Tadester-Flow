import 'package:flutter/material.dart';

class JobStatusBadge extends StatelessWidget {
  const JobStatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final _BadgeStyle style = _styleForStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: style.foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  _BadgeStyle _styleForStatus(String value) {
    switch (value) {
      case 'completed':
        return const _BadgeStyle(
          backgroundColor: Color(0xFFDFF5E8),
          foregroundColor: Color(0xFF0F7A43),
        );
      case 'in_progress':
        return const _BadgeStyle(
          backgroundColor: Color(0xFFFFE6D8),
          foregroundColor: Color(0xFFB94A00),
        );
      case 'cancelled':
        return const _BadgeStyle(
          backgroundColor: Color(0xFFFBE0E0),
          foregroundColor: Color(0xFFB3261E),
        );
      default:
        return const _BadgeStyle(
          backgroundColor: Color(0xFFF1E4DD),
          foregroundColor: Color(0xFF7B3D2A),
        );
    }
  }
}

class _BadgeStyle {
  const _BadgeStyle({
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;
}

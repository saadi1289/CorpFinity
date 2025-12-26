import 'package:flutter/material.dart';

class GoalOption {
  final String id;
  final String label;
  final String icon; // Lucide icon name
  final Color color;
  final String description;
  
  const GoalOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
  });
}

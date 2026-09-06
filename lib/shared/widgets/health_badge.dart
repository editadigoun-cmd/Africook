import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class HealthBadge extends StatelessWidget {
  final String tag;

  const HealthBadge({super.key, required this.tag});

  static const Map<String, Map<String, dynamic>> _tagConfig = {
    'diabète': {'emoji': '🩺', 'color': 0xFF3B82F6},
    'végétarien': {'emoji': '🥗', 'color': 0xFF22C55E},
    'sans gluten': {'emoji': '🌾', 'color': 0xFFF59E0B},
    'sport': {'emoji': '🏃', 'color': 0xFFF97316},
    'minceur': {'emoji': '💪', 'color': 0xFF8B5CF6},
    'sans lactose': {'emoji': '🥛', 'color': 0xFF06B6D4},
    'enfant': {'emoji': '🧒', 'color': 0xFFEC4899},
  };

  @override
  Widget build(BuildContext context) {
    final config = _tagConfig[tag.toLowerCase()] ??
        {'emoji': '✅', 'color': AppColors.green.value};
    final color = Color(config['color'] as int);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(config['emoji'] as String,
              style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            tag,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

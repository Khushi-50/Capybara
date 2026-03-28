import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PathNode extends StatelessWidget {
  const PathNode({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.offset = 0,
    this.locked = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final double offset;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(offset, 0),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: locked ? Colors.white10 : AppColors.purple.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: locked ? Colors.grey.shade700 : AppColors.purple,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 34),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

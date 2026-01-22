// Shared gradient background with subtle shapes for a distinctive visual tone.
// This exists to avoid flat screens and keep the UI feeling intentional.
// It fits in the app by wrapping primary scaffolds across tabs and auth.
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface,
                  colorScheme.surfaceVariant.withOpacity(0.4),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -60,
          right: -40,
          child: _Blob(
            size: 180,
            color: colorScheme.primary.withOpacity(0.12),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -50,
          child: _Blob(
            size: 220,
            color: colorScheme.tertiary.withOpacity(0.12),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}

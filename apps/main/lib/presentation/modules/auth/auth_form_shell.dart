import 'dart:math';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AuthFormShell extends StatelessWidget {
  const AuthFormShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.12),
            colors.secondary.withValues(alpha: 0.50),
            colors.scaffoldBackgroundColor,
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          final horizontalPadding = isWide ? 32.0 : 20.0;
          final formWidth = max(
            0.0,
            min(constraints.maxWidth - horizontalPadding * 2, 460.0),
          );
          return Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isWide ? 40 : 24,
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 12 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.cardBackground,
                    borderRadius: BorderRadius.circular(isWide ? 34 : 28),
                    border: Border.all(
                      color: colors.onSurface.withValues(alpha: 0.07),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadowColor.withValues(alpha: 0.18),
                        blurRadius: 42,
                        offset: const Offset(0, 22),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 36 : 22,
                      vertical: isWide ? 38 : 28,
                    ),
                    child: SizedBox(width: formWidth, child: child),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColor;
    final textTheme = context.textTheme;
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.primary, colors.primaryVariant],
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.26),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Icon(
              Iconsax.message_text,
              color: colors.onPrimary,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

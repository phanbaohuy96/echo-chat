import 'dart:math';

import 'package:core/core.dart';
import 'package:flutter/material.dart';

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
            colors.primary.withValues(alpha: 0.16),
            colors.secondary.withValues(alpha: 0.54),
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
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: colors.onSurface.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.10),
                      blurRadius: 36,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 34 : 24,
                    vertical: isWide ? 36 : 30,
                  ),
                  child: SizedBox(width: formWidth, child: child),
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
              colors: [colors.primary, colors.primary.withValues(alpha: 0.72)],
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Icon(
              Icons.chat_bubble_outline,
              color: colors.onPrimary,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

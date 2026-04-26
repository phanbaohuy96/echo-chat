import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/localization_ext.dart';
import '../auth/authentication_coordinator.dart';

class NotFoundPage extends StatefulWidget {
  const NotFoundPage({super.key});

  @override
  State<NotFoundPage> createState() => _NotFoundPageState();
}

class _NotFoundPageState extends State<NotFoundPage> {
  @override
  Widget build(BuildContext context) {
    final colors = context.themeColor;
    final textTheme = context.textTheme;
    final shouldReturnHome = myNavigatorObserver.history.length <= 2;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primary.withValues(alpha: 0.12),
              colors.secondary.withValues(alpha: 0.48),
              colors.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 34,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.primary.withValues(alpha: 0.12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Icon(
                                Icons.travel_explore_rounded,
                                color: colors.primary,
                                size: 38,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          l10n.pageNotFound,
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 22),
                        ThemeButton.primary(
                          title: shouldReturnHome
                              ? l10n.backToHomepage
                              : l10n.back,
                          onPressed: shouldReturnHome
                              ? _backToWelcomePage
                              : _back,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _backToWelcomePage() {
    context.openSignIn(
      pushBehavior: PushNamedAndRemoveUntilBehavior.removeAll(),
    );
  }

  void _back() {
    Navigator.pop(context);
  }
}

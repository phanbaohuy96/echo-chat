import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../../../generated/assets.dart';
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
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: EmptyData(
              message: l10n.pageNotFound,
              icon: Assets.image.emptySearchState,
              iconWidth: 220,
              iconHeight: 220,
            ),
          ),
          myNavigatorObserver.history.length <= 2
              ? ThemeButton.text(
                  title: l10n.backToHomepage,
                  onPressed: _backToWelcomePage,
                )
              : ThemeButton.text(title: l10n.back, onPressed: _back),
        ],
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

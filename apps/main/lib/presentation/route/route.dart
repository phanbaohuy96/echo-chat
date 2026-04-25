import 'package:collection/collection.dart';
import 'package:core/core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../modules/auth/authentication_route.dart';
import '../modules/chat/chat_route.dart';

@injectable
class RouteGenerator {
  RouteGenerator();

  late final List<CustomRouter> routers = [
    ...CoreRoute().routers(),
    ...AuthenticationRoute().routers(),
    ...ChatRoute().routers(),
  ];

  late final List<CustomRouter> _sortedRouters = [...routers]
    ..sortByCompare(
      (element) => element.path,
      (a, b) => b.length.compareTo(a.length),
    );

  Route<dynamic>? generateRoute(
    BuildContext context,
    RouteSettings settings, {
    bool supportUnknownRoute = true,
  }) {
    final _settings = preResolveRouteSettings(context, settings);

    final _builder = findRouteBuilder(_settings);
    if (_builder == null && supportUnknownRoute != true) {
      return null;
    }

    if ([].any((e) => e == _settings.name)) {
      return buildFaderPageRoute(
        _builder ?? (context) => const UnsupportedPage(),
        settings: _settings,
      );
    }

    return buildRoute(
      _builder ?? (context) => const UnsupportedPage(),
      settings: _settings,
    );
  }

  WidgetBuilder? findRouteBuilder(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? '');
    if (uri == null) {
      return null;
    }

    for (final route in _sortedRouters) {
      if (route.canLaunch(uri, settings.arguments)) {
        return (context) => route.build(context, uri, settings.arguments);
      }
    }
    return null;
  }

  RouteSettings preResolveRouteSettings(
    BuildContext context,
    RouteSettings settings,
  ) {
    final uri = Uri.tryParse(settings.name ?? '');

    if (uri == null) {
      return settings;
    }

    final queryParameters = uri.queryParameters;

    final internalQueryParametes = [];

    if (queryParameters.isEmpty) {
      return settings;
    }

    // handle language
    final languageCode =
        uri.queryParameters['hl'] ?? uri.queryParameters['lang'];
    final locale = AppLocale.supportedLocales.firstWhereOrNull((l) {
      return l.languageCode == languageCode?.toLowerCase();
    });

    if (locale != null) {
      internalQueryParametes.addAll(['lang', 'hl']);
      context.read<AppGlobalBloc>().changeLocale(locale);
    }

    // finalize uri
    final finalUri = uri.replace(
      queryParameters: Map.fromEntries(
        queryParameters.entries.where(
          (entry) => !internalQueryParametes.contains(entry.key),
        ),
      ),
    );

    return RouteSettings(
      name: finalUri.toString(),
      arguments: settings.arguments,
    );
  }
}

Route buildFaderPageRoute<T>(WidgetBuilder builder, {RouteSettings? settings}) {
  return FaderPageRoute<T>(
    builder: (context) => TextScaleFixed(child: builder(context)),
    settings: settings,
  );
}

Route buildRoute<T>(WidgetBuilder builder, {RouteSettings? settings}) {
  if (kIsWeb) {
    return MaterialPageRoute<T>(
      builder: (context) => TextScaleFixed(child: builder(context)),
      settings: settings,
    );
  }
  return CupertinoPageRoute<T>(
    builder: (context) => TextScaleFixed(child: builder(context)),
    settings: settings,
  );
}

class FaderPageRoute<T> extends PageRoute<T> {
  FaderPageRoute({required this.builder, RouteSettings? settings})
    : super(settings: settings);

  @override
  Color get barrierColor => Colors.transparent;

  @override
  String get barrierLabel => '';

  final WidgetBuilder builder;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return FadeTransition(opacity: animation, child: builder(context));
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);
}

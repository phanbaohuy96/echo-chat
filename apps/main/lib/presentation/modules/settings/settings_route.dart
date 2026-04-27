import 'package:core/core.dart';

import '../../../di/di.dart';
import 'settings_home/bloc/settings_bloc.dart';
import 'settings_home/views/settings_screen.dart';
import 'storage_management/bloc/storage_management_bloc.dart';
import 'storage_management/views/storage_management_screen.dart';

/// Routes for the settings home and storage management screens.
class SettingsRoute extends IRoute {
  @override
  List<CustomRouter> routers() {
    return [
      CustomRouter(
        path: SettingsScreen.routeName,
        builder: (context, uri, extra) {
          return BlocProvider<SettingsBloc>(
            create: (context) => injector.get(),
            child: const SettingsScreen(),
          );
        },
      ),
      CustomRouter(
        path: StorageManagementScreen.routeName,
        builder: (context, uri, extra) {
          return BlocProvider<StorageManagementBloc>(
            create: (context) => injector.get(),
            child: const StorageManagementScreen(),
          );
        },
      ),
    ];
  }
}

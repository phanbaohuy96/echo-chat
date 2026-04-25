import 'package:core/core.dart';

import '../../../di/di.dart';
import 'conversation/bloc/chat_bloc.dart';
import 'conversation/views/chat_screen.dart';

class ChatRoute extends IRoute {
  @override
  List<CustomRouter> routers() {
    return [
      CustomRouter(
        path: ChatScreen.routeName,
        builder: (context, uri, extra) {
          return BlocProvider<ChatBloc>(
            create: (context) => injector.get(),
            child: const ChatScreen(),
          );
        },
      ),
    ];
  }
}

import 'package:core/core.dart';
import 'package:data_source/data_source.dart';
import 'package:flutter/material.dart';

import '../../../../../domain/entities/chat/local_chat_message.dart';
import '../../../../../l10n/localization_ext.dart';
import '../../../../base/base.dart';
import '../bloc/chat_bloc.dart';

part 'chat.action.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  static String routeName = '/chat';

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends StateBase<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  var _lastMessageCount = 0;

  @override
  ChatBloc get bloc => BlocProvider.of(context);

  late ThemeData _themeData;

  TextTheme get textTheme => _themeData.textTheme;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => bloc.add(ChatStartedEvent()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeData = context.theme;

    return BlocConsumer<ChatBloc, ChatState>(
      listenWhen: (previous, current) {
        return previous.messages.length != current.messages.length;
      },
      listener: _blocListener,
      builder: (context, state) {
        final selectedPeer = state.selectedPeer;
        return ScreenForm(
          title: selectedPeer == null
              ? l10n.appName
              : _peerDisplayName(selectedPeer),
          showBackButton: false,
          actions: [
            IconButton(
              tooltip: l10n.refresh,
              onPressed: selectedPeer == null || state.isLoadingMessages
                  ? null
                  : _refreshConversation,
              icon: state.isLoadingMessages || state.isSyncing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                _buildPeerSelector(state),
                Expanded(child: _buildMessages(state)),
                _buildComposer(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeerSelector(ChatState state) {
    if (state.isLoadingPeers) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      );
    }
    if (state.peers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.createAnotherAccountToStartConversation),
      );
    }
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: state.peers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final peer = state.peers[index];
          final selected = peer.id == state.selectedPeer?.id;
          return ChoiceChip(
            label: Text(_peerDisplayName(peer)),
            selected: selected,
            onSelected: selected || state.isLoadingMessages
                ? null
                : (_) => _selectPeer(peer),
          );
        },
      ),
    );
  }

  Widget _buildMessages(ChatState state) {
    if (state.isLoadingMessages && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.selectedPeer == null) {
      return Center(child: Text(l10n.selectUserToStartChatting));
    }
    if (state.messages.isEmpty) {
      return Center(
        child: Text(
          '${l10n.startConversationWith} '
          '${_peerDisplayName(state.selectedPeer!)}.',
        ),
      );
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _MessageBubble(message: state.messages[index]);
      },
    );
  }

  Widget _buildComposer(ChatState state) {
    final canSend = state.selectedPeer != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: state.selectedPeer != null,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(hintText: l10n.message),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            onPressed: canSend ? _send : null,
            tooltip: l10n.send,
            icon: state.isSending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  String _peerDisplayName(UserModel peer) {
    final name = peer.name?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    final username = peer.username?.trim();
    if (username != null && username.isNotEmpty) {
      return username;
    }
    return l10n.user;
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColor;
    final textTheme = context.textTheme;
    final foreground = message.isMine ? colors.onPrimary : colors.onSurface;
    final bubble = DecoratedBox(
      decoration: BoxDecoration(
        color: message.isMine ? colors.primary : colors.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: textTheme.bodyMedium?.copyWith(color: foreground),
            ),
            if (message.isMine && message.status != ChatMessageStatus.sent) ...[
              const SizedBox(height: 4),
              Text(
                message.status == ChatMessageStatus.pending
                    ? context.l10n.sending
                    : context.l10n.failedTapToRetry,
                style: textTheme.labelSmall?.copyWith(
                  color: message.status == ChatMessageStatus.failed
                      ? colors.error
                      : foreground.withValues(alpha: 0.72),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    final constrained = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.78,
      ),
      child: message.status == ChatMessageStatus.failed && message.isMine
          ? InkWell(
              onTap: () => context.read<ChatBloc>().add(
                ChatRetryRequestedEvent(message.clientMessageId),
              ),
              borderRadius: BorderRadius.circular(18),
              child: bubble,
            )
          : bubble,
    );
    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: constrained,
    );
  }
}

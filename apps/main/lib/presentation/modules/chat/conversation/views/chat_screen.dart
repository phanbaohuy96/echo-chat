import 'dart:math';

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
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => bloc.add(ChatStartedEvent()),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
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
              onPressed:
                  state.isLoadingPeers ||
                      state.isLoadingMessages ||
                      state.isSyncing
                  ? null
                  : _refreshConversation,
              icon:
                  state.isLoadingPeers ||
                      state.isLoadingMessages ||
                      state.isSyncing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
          child: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth = min(constraints.maxWidth, 960.0);
                final isWide = constraints.maxWidth >= 900;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        context.themeColor.primary.withValues(alpha: 0.08),
                        context.themeColor.scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isWide ? 24 : 0,
                        isWide ? 20 : 0,
                        isWide ? 24 : 0,
                        isWide ? 20 : 0,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.themeColor.cardBackground,
                          borderRadius: BorderRadius.circular(isWide ? 28 : 0),
                          border: isWide
                              ? Border.all(
                                  color: context.themeColor.onSurface
                                      .withValues(alpha: 0.06),
                                )
                              : null,
                          boxShadow: isWide
                              ? [
                                  BoxShadow(
                                    color: context.themeColor.primary
                                        .withValues(alpha: 0.10),
                                    blurRadius: 32,
                                    offset: const Offset(0, 18),
                                  ),
                                ]
                              : const [],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(isWide ? 28 : 0),
                          child: SizedBox(
                            width: contentWidth,
                            child: Column(
                              children: [
                                _buildPeerSelector(state),
                                Expanded(child: _buildMessages(state)),
                                _buildComposer(state),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.themeColor.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: context.themeColor.onSurface.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: SizedBox(
        height: 72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          itemCount: state.peers.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final peer = state.peers[index];
            final selected = peer.id == state.selectedPeer?.id;
            return ChoiceChip(
              avatar: CircleAvatar(
                backgroundColor: selected
                    ? context.themeColor.onPrimary.withValues(alpha: 0.20)
                    : context.themeColor.primary.withValues(alpha: 0.10),
                child: Text(_peerInitial(peer)),
              ),
              label: Text(_peerDisplayName(peer)),
              selected: selected,
              onSelected: selected || state.isLoadingMessages
                  ? null
                  : (_) => _selectPeer(peer),
            );
          },
        ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final bubbleMaxWidth = min(constraints.maxWidth * 0.78, 640.0);
        return ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          itemCount: state.messages.length + (state.isLoadingOlder ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (state.isLoadingOlder && index == 0) {
              return const Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            final messageIndex = index - (state.isLoadingOlder ? 1 : 0);
            return _MessageBubble(
              message: state.messages[messageIndex],
              maxWidth: bubbleMaxWidth,
            );
          },
        );
      },
    );
  }

  Widget _buildComposer(ChatState state) {
    final canSend = state.selectedPeer != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.themeColor.cardBackground,
        border: Border(
          top: BorderSide(
            color: context.themeColor.onSurface.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: state.selectedPeer != null,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: l10n.message,
                  prefixIcon: const Icon(Icons.chat_bubble_outline),
                ),
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
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }

  String _peerInitial(UserModel peer) {
    final displayName = _peerDisplayName(peer).trim();
    return displayName.isEmpty ? '?' : displayName[0].toUpperCase();
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
  const _MessageBubble({required this.message, required this.maxWidth});

  final ChatMessage message;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColor;
    final textTheme = context.textTheme;
    final foreground = message.isMine ? colors.onPrimary : colors.onSurface;
    final bubble = DecoratedBox(
      decoration: BoxDecoration(
        color: message.isMine ? colors.primary : colors.scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(message.isMine ? 20 : 6),
          bottomRight: Radius.circular(message.isMine ? 6 : 20),
        ),
        border: message.isMine
            ? null
            : Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
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
      constraints: BoxConstraints(maxWidth: maxWidth),
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

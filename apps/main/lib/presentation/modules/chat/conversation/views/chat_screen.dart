import 'package:core/core.dart';
import 'package:data_source/data_source.dart';
import 'package:flutter/material.dart';

import '../bloc/chat_bloc.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  static String routeName = '/chat';

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  var _lastMessageCount = 0;

  ChatBloc get bloc => BlocProvider.of(context);

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
    return BlocConsumer<ChatBloc, ChatState>(
      listenWhen: (previous, current) {
        return previous.errorMessage != current.errorMessage ||
            previous.messages.length != current.messages.length;
      },
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
        if (state.messages.length != _lastMessageCount) {
          _lastMessageCount = state.messages.length;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(),
          );
        }
      },
      builder: (context, state) {
        final selectedPeer = state.selectedPeer;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              selectedPeer == null
                  ? 'EchoChat'
                  : _peerDisplayName(selectedPeer),
            ),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                onPressed: selectedPeer == null || state.isLoadingMessages
                    ? null
                    : () => bloc.add(ChatRefreshRequestedEvent()),
                icon: state.isLoadingMessages
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
          body: SafeArea(
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
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Create another account to start a conversation.'),
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
                : (_) => bloc.add(ChatPeerSelectedEvent(peer)),
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
      return const Center(child: Text('Select a user to start chatting.'));
    }
    if (state.messages.isEmpty) {
      return Center(
        child: Text(
          'Start your conversation with '
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
    final canSend = state.selectedPeer != null && !state.isSending;
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
              decoration: const InputDecoration(hintText: 'Message'),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            onPressed: canSend ? _send : null,
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

  void _send() {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      return;
    }
    _controller.clear();
    bloc.add(ChatMessageSubmittedEvent(message));
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
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
    return 'User';
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: message.isMine
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: message.isMine
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

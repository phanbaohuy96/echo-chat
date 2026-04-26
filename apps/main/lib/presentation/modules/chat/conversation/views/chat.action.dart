part of 'chat_screen.dart';

extension ChatAction on _ChatScreenState {
  void _blocListener(BuildContext context, ChatState state) {
    if (state.messages.length == _lastMessageCount) {
      return;
    }
    _lastMessageCount = state.messages.length;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _refreshConversation() {
    bloc.add(ChatRefreshRequestedEvent());
  }

  void _selectPeer(UserModel peer) {
    bloc.add(ChatPeerSelectedEvent(peer));
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
}

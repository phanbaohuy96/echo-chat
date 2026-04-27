part of 'chat_screen.dart';

extension ChatAction on _ChatScreenState {
  void _onScroll() {
    if (!_scrollController.hasClients ||
        bloc.state.isLoadingOlder ||
        !bloc.state.hasMoreOlder) {
      return;
    }
    if (_scrollController.offset <= 80) {
      _olderLoadMaxScrollExtent = _scrollController.position.maxScrollExtent;
      bloc.add(ChatOlderMessagesRequestedEvent());
    }
  }

  void _onDraftChanged() {
    final hasDraft = _controller.text.trim().isNotEmpty;
    if (hasDraft != _hasDraft) {
      _setHasDraft(hasDraft);
    }
  }

  void _onComposerFocusChanged() {
    _rebuildForComposerFocus();
  }

  void _blocListener(BuildContext context, ChatState state) {
    if (state.messages.length == _lastMessageCount) {
      return;
    }
    final addedMessages = state.messages.length > _lastMessageCount;
    _lastMessageCount = state.messages.length;
    if (addedMessages && _olderLoadMaxScrollExtent != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _restoreOlderScrollOffset(),
      );
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _refreshConversation() {
    bloc.add(ChatRefreshRequestedEvent());
  }

  Future<void> _openSettings() async {
    final storageCleared = await context.openSettings();
    if (storageCleared == true) {
      bloc.add(ChatStartedEvent());
    }
  }

  void _selectPeer(UserModel peer) {
    bloc.add(ChatPeerSelectedEvent(peer));
    _setShowMobileConversation(true);
  }

  void _showMobilePeerList() {
    _composerFocusNode.unfocus();
    _setShowMobileConversation(false);
  }

  void _send() {
    final message = _controller.text.trim();
    if (message.isEmpty ||
        bloc.state.selectedPeer == null ||
        bloc.state.isSending) {
      return;
    }
    _controller.clear();
    bloc.add(ChatMessageSubmittedEvent(message));
    _composerFocusNode.requestFocus();
  }

  void _restoreOlderScrollOffset() {
    if (!_scrollController.hasClients || _olderLoadMaxScrollExtent == null) {
      _olderLoadMaxScrollExtent = null;
      return;
    }
    final oldMaxScrollExtent = _olderLoadMaxScrollExtent!;
    _olderLoadMaxScrollExtent = null;
    final newMaxScrollExtent = _scrollController.position.maxScrollExtent;
    final delta = newMaxScrollExtent - oldMaxScrollExtent;
    if (delta <= 0) {
      return;
    }
    final targetOffset = min(
      _scrollController.offset + delta,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.jumpTo(targetOffset);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }
}

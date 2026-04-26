import 'dart:math';

import 'package:core/core.dart';
import 'package:data_source/data_source.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

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
  final _composerFocusNode = FocusNode();
  var _lastMessageCount = 0;
  var _hasDraft = false;
  var _showMobileConversation = false;
  bool? _wasDesktopLayout;
  double? _olderLoadMaxScrollExtent;

  @override
  ChatBloc get bloc => BlocProvider.of(context);

  late ThemeData _themeData;

  TextTheme get textTheme => _themeData.textTheme;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _controller.addListener(_onDraftChanged);
    _composerFocusNode.addListener(_onComposerFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => bloc.add(ChatStartedEvent()),
    );
  }

  void _setHasDraft(bool value) {
    setState(() => _hasDraft = value);
  }

  void _rebuildForComposerFocus() {
    setState(() {});
  }

  void _setShowMobileConversation(bool value) {
    setState(() => _showMobileConversation = value);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _controller.removeListener(_onDraftChanged);
    _composerFocusNode.removeListener(_onComposerFocusChanged);
    _controller.dispose();
    _scrollController.dispose();
    _composerFocusNode.dispose();
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
        return ScreenForm(
          showBackButton: false,
          bgColor: context.themeColor.scaffoldBackgroundColor,
          child: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _buildResponsiveShell(state, constraints);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveShell(ChatState state, BoxConstraints constraints) {
    final isDesktop = constraints.maxWidth >= 980;
    if (_wasDesktopLayout != null && _wasDesktopLayout != isDesktop) {
      if (isDesktop) {
        _showMobileConversation = false;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
    _wasDesktopLayout = isDesktop;
    final isTablet = constraints.maxWidth >= 640;
    final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 20.0 : 0.0);
    final verticalPadding = isDesktop ? 24.0 : (isTablet ? 16.0 : 0.0);
    final contentWidth = max(
      0.0,
      min(constraints.maxWidth - horizontalPadding * 2, 1180.0),
    );
    final contentHeight = max(0.0, constraints.maxHeight - verticalPadding * 2);
    final borderRadius = isDesktop ? 34.0 : (isTablet ? 28.0 : 0.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.themeColor.primary.withValues(alpha: 0.10),
            context.themeColor.secondary.withValues(alpha: 0.72),
            context.themeColor.scaffoldBackgroundColor,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -120,
            top: -120,
            child: _DecorativeOrb(
              color: context.themeColor.primary.withValues(alpha: 0.10),
              size: 280,
            ),
          ),
          Positioned(
            right: -90,
            bottom: -80,
            child: _DecorativeOrb(
              color: context.themeColor.secondary.withValues(alpha: 0.86),
              size: 240,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Center(
              child: SizedBox(
                width: contentWidth,
                height: contentHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.themeColor.cardBackground,
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: context.themeColor.onSurface.withValues(
                        alpha: 0.07,
                      ),
                    ),
                    boxShadow: [
                      if (isTablet)
                        BoxShadow(
                          color: context.themeColor.shadowColor.withValues(
                            alpha: 0.20,
                          ),
                          blurRadius: 44,
                          offset: const Offset(0, 24),
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(borderRadius),
                    child: isDesktop
                        ? Row(
                            children: [
                              SizedBox(
                                width: 326,
                                child: _buildDesktopSidebar(state),
                              ),
                              VerticalDivider(
                                width: 1,
                                color: context.themeColor.dividerColor,
                              ),
                              Expanded(child: _buildConversationPane(state)),
                            ],
                          )
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeOutCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.04, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child:
                                _showMobileConversation &&
                                    state.selectedPeer != null
                                ? _buildConversationPane(
                                    state,
                                    key: const ValueKey('mobile-conversation'),
                                    showMobileBack: true,
                                  )
                                : _buildMobilePeerList(
                                    state,
                                    key: const ValueKey('mobile-peers'),
                                  ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(ChatState state) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.themeColor.secondary.withValues(alpha: 0.36),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _IconBadge(icon: Iconsax.messages_2, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appName,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        l10n.selectUserToStartChatting,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (state.isLoadingPeers)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildPeerList(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildPeerList(ChatState state, {bool allowSelectedTap = false}) {
    if (state.peers.isEmpty && state.isLoadingPeers) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.peers.isEmpty) {
      return _EmptyPanel(
        icon: Iconsax.profile_2user,
        title: l10n.createAnotherAccountToStartConversation,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 12),
      itemCount: state.peers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final peer = state.peers[index];
        final selected = peer.id == state.selectedPeer?.id;
        return _PeerTile(
          title: _peerDisplayName(peer),
          subtitle: peer.username?.trim(),
          initial: _peerInitial(peer),
          selected: selected,
          enabled: (allowSelectedTap || !selected) && !state.isLoadingMessages,
          onTap: () => _selectPeer(peer),
        );
      },
    );
  }

  Widget _buildMobilePeerList(ChatState state, {Key? key}) {
    return DecoratedBox(
      key: key,
      decoration: BoxDecoration(color: context.themeColor.cardBackground),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _IconBadge(icon: Iconsax.messages_2, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appName,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.selectUserToStartChatting,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: l10n.refresh,
                  onPressed: state.isLoadingPeers ? null : _refreshConversation,
                  icon: state.isLoadingPeers
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Iconsax.refresh),
                ),
              ],
            ),
            const SizedBox(height: 18),
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.themeColor.secondary.withValues(alpha: 0.36),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: context.themeColor.borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.search_normal,
                      size: 18,
                      color: context.themeColor.labelText,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.selectUserToStartChatting,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: context.themeColor.labelText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.isLoadingPeers) ...[
              const SizedBox(height: 14),
              const LinearProgressIndicator(minHeight: 2),
            ],
            const SizedBox(height: 12),
            Expanded(child: _buildPeerList(state, allowSelectedTap: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationPane(
    ChatState state, {
    Key? key,
    bool showMobileBack = false,
  }) {
    return Column(
      key: key,
      children: [
        _buildConversationHeader(state, showMobileBack: showMobileBack),
        Expanded(child: _buildMessages(state)),
        _buildComposer(state),
      ],
    );
  }

  Widget _buildConversationHeader(
    ChatState state, {
    bool showMobileBack = false,
  }) {
    final selectedPeer = state.selectedPeer;
    final title = selectedPeer == null
        ? l10n.appName
        : _peerDisplayName(selectedPeer);
    final subtitle = selectedPeer?.username?.trim().isNotEmpty == true
        ? selectedPeer!.username!.trim()
        : l10n.selectUserToStartChatting;
    final refreshing =
        state.isLoadingPeers || state.isLoadingMessages || state.isSyncing;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.themeColor.cardBackground,
        border: Border(
          bottom: BorderSide(color: context.themeColor.dividerColor),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            if (showMobileBack) ...[
              IconButton(
                tooltip: l10n.back,
                onPressed: _showMobilePeerList,
                icon: const Icon(Iconsax.arrow_left),
              ),
              const SizedBox(width: 4),
            ],
            selectedPeer == null
                ? const _IconBadge(icon: Iconsax.message_question, size: 46)
                : _PeerAvatar(
                    initial: _peerInitial(selectedPeer),
                    selected: true,
                    size: 46,
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: context.themeColor.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              tooltip: l10n.refresh,
              onPressed: refreshing ? null : _refreshConversation,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: refreshing
                    ? const SizedBox.square(
                        key: ValueKey('refreshing'),
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Iconsax.refresh, key: ValueKey('refresh')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(ChatState state) {
    if (state.isLoadingMessages && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.selectedPeer == null) {
      return _EmptyPanel(
        icon: Iconsax.message_question,
        title: l10n.selectUserToStartChatting,
      );
    }
    if (state.messages.isEmpty) {
      return _EmptyPanel(
        icon: Iconsax.message_add,
        title:
            '${l10n.startConversationWith} '
            '${_peerDisplayName(state.selectedPeer!)}.',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final bubbleMaxWidth = min(constraints.maxWidth * 0.74, 620.0);
        final topLoaderCount = state.isLoadingOlder ? 1 : 0;
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          itemCount: state.messages.length + topLoaderCount,
          itemBuilder: (context, index) {
            if (state.isLoadingOlder && index == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Center(
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final messageIndex = index - topLoaderCount;
            final message = state.messages[messageIndex];
            final previous = messageIndex > 0
                ? state.messages[messageIndex - 1]
                : null;
            final groupedWithPrevious =
                previous != null &&
                previous.isMine == message.isMine &&
                message.createdAt
                        .difference(previous.createdAt)
                        .inMinutes
                        .abs() <
                    5;
            return Padding(
              padding: EdgeInsets.only(top: groupedWithPrevious ? 5 : 14),
              child: _MessageBubble(
                key: ValueKey(message.clientMessageId),
                message: message,
                maxWidth: bubbleMaxWidth,
                groupedWithPrevious: groupedWithPrevious,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildComposer(ChatState state) {
    final hasPeer = state.selectedPeer != null;
    final canSend = hasPeer && _hasDraft && !state.isSending;
    final focused = _composerFocusNode.hasFocus;
    final colors = context.themeColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        border: Border(top: BorderSide(color: colors.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: hasPeer
                  ? colors.secondary.withValues(alpha: 0.34)
                  : colors.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: focused
                    ? colors.primary.withValues(alpha: 0.70)
                    : colors.borderColor,
                width: focused ? 1.4 : 1,
              ),
              boxShadow: [
                if (focused)
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: TextField(
                      controller: _controller,
                      focusNode: _composerFocusNode,
                      enabled: hasPeer,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      style: textTheme.bodyMedium?.copyWith(height: 1.28),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: hasPeer
                            ? l10n.message
                            : l10n.selectUserToStartChatting,
                        hintStyle: textTheme.bodyMedium?.copyWith(
                          color: colors.labelText,
                          height: 1.28,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedScale(
                  duration: const Duration(milliseconds: 130),
                  scale: canSend || state.isSending ? 1 : 0.92,
                  child: SizedBox.square(
                    dimension: 42,
                    child: IconButton.filled(
                      onPressed: canSend ? _send : null,
                      tooltip: l10n.send,
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        disabledBackgroundColor: colors.onSurface.withValues(
                          alpha: 0.07,
                        ),
                        disabledForegroundColor: colors.labelText,
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                      ),
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 140),
                        child: state.isSending
                            ? SizedBox.square(
                                key: const ValueKey('sending'),
                                dimension: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.onPrimary,
                                ),
                              )
                            : const Icon(
                                Iconsax.send_1,
                                key: ValueKey('send'),
                                size: 19,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

class _DecorativeOrb extends StatelessWidget {
  const _DecorativeOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.themeColor.primary,
            context.themeColor.primaryVariant,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: context.themeColor.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, color: context.themeColor.onPrimary, size: size * 0.46),
    );
  }
}

class _PeerAvatar extends StatelessWidget {
  const _PeerAvatar({
    required this.initial,
    required this.selected,
    required this.size,
  });

  final String initial;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? context.themeColor.primary
            : context.themeColor.primary.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: context.textTheme.titleMedium?.copyWith(
          color: selected
              ? context.themeColor.onPrimary
              : context.themeColor.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PeerTile extends StatelessWidget {
  const _PeerTile({
    required this.title,
    required this.subtitle,
    required this.initial,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final String initial;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected
            ? colors.primary.withValues(alpha: 0.10)
            : colors.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected
              ? colors.primary.withValues(alpha: 0.36)
              : colors.borderColor,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _PeerAvatar(initial: initial, selected: selected, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.labelMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected ? Iconsax.message_tick : Iconsax.message,
                  size: 18,
                  color: selected ? colors.primary : colors.labelText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconBadge(icon: icon, size: 58),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.textTheme.titleSmall?.copyWith(height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.maxWidth,
    required this.groupedWithPrevious,
  });

  final ChatMessage message;
  final double maxWidth;
  final bool groupedWithPrevious;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColor;
    final textTheme = context.textTheme;
    final failed = message.status == ChatMessageStatus.failed;
    final pending = message.status == ChatMessageStatus.pending;
    final mineBackground = failed
        ? colors.error.withValues(alpha: 0.10)
        : colors.primary;
    final background = message.isMine
        ? mineBackground
        : colors.secondary.withValues(alpha: 0.50);
    final foreground = message.isMine && !failed
        ? colors.onPrimary
        : colors.onSurface;
    final hasTail = !groupedWithPrevious;
    final tailAlignment = message.isMine
        ? Alignment.bottomRight
        : Alignment.bottomLeft;

    final content = _PaintedChatBubble(
      color: background,
      hasTail: hasTail,
      tailAlignment: tailAlignment,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.text,
            style: textTheme.bodyMedium?.copyWith(color: foreground),
          ),
          const SizedBox(height: 7),
          _MessageMeta(message: message, color: foreground),
        ],
      ),
    );

    final bubble = AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: pending ? 0.78 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: content,
      ),
    );

    final constrained = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: failed && message.isMine
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.read<ChatBloc>().add(
                  ChatRetryRequestedEvent(message.clientMessageId),
                ),
                customBorder: const StadiumBorder(),
                child: bubble,
              ),
            )
          : bubble,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Align(
        alignment: message.isMine
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: constrained,
      ),
    );
  }
}

class _PaintedChatBubble extends StatelessWidget {
  const _PaintedChatBubble({
    required this.child,
    required this.tailAlignment,
    required this.color,
    required this.hasTail,
  });

  final Widget child;
  final Alignment tailAlignment;
  final Color color;
  final bool hasTail;

  @override
  Widget build(BuildContext context) {
    final padding = switch (tailAlignment) {
      Alignment.bottomLeft => const EdgeInsets.fromLTRB(18, 12, 13, 13),
      Alignment.bottomRight => const EdgeInsets.fromLTRB(13, 12, 18, 13),
      _ => const EdgeInsets.fromLTRB(14, 12, 14, 13),
    };

    return CustomPaint(
      painter: _ChatBubblePainter(
        color: color,
        hasTail: hasTail,
        alignment: tailAlignment,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _ChatBubblePainter extends CustomPainter {
  _ChatBubblePainter({
    required this.color,
    required this.hasTail,
    required this.alignment,
  }) : paintFill = Paint()
         ..color = color
         ..style = PaintingStyle.fill;

  final Color color;
  final Alignment alignment;
  final bool hasTail;
  final Paint paintFill;

  static const cornerSize = 16.0;
  static const buffer = 6.0;
  static const innerTailWidth = 7.0;
  static const innerTailHeight = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, cornerSize)
      ..lineTo(0, size.height - cornerSize)
      ..arcToPoint(
        Offset(cornerSize, size.height),
        radius: const Radius.circular(cornerSize),
        clockwise: false,
      );

    if (hasTail) {
      path
        ..lineTo(size.width - cornerSize - innerTailWidth, size.height)
        ..arcToPoint(
          Offset(
            size.width - buffer - innerTailWidth,
            size.height - innerTailHeight,
          ),
          radius: const Radius.circular(cornerSize),
          clockwise: false,
        )
        ..arcToPoint(
          Offset(size.width, size.height),
          radius: const Radius.circular(buffer * 2),
          clockwise: false,
        )
        ..arcToPoint(
          Offset(size.width - buffer, size.height - buffer - innerTailHeight),
          radius: const Radius.circular(buffer + innerTailHeight),
          clockwise: true,
        );
    } else {
      path
        ..lineTo(size.width - cornerSize, size.height)
        ..arcToPoint(
          Offset(size.width - buffer, size.height - cornerSize),
          radius: const Radius.circular(cornerSize),
          clockwise: false,
        );
    }

    path
      ..lineTo(size.width - buffer, cornerSize)
      ..arcToPoint(
        Offset(size.width - cornerSize - buffer, 0),
        radius: const Radius.circular(cornerSize),
        clockwise: false,
      )
      ..lineTo(cornerSize, 0)
      ..arcToPoint(
        const Offset(0, cornerSize),
        radius: const Radius.circular(cornerSize),
        clockwise: false,
      );

    switch (alignment) {
      case Alignment.bottomLeft:
        canvas
          ..save()
          ..flipHorz(size)
          ..drawPath(path, paintFill)
          ..restore();
      case Alignment.topRight:
        canvas
          ..save()
          ..flipVert(size)
          ..drawPath(path, paintFill)
          ..restore();
      case Alignment.topLeft:
        canvas
          ..save()
          ..flipHorz(size)
          ..flipVert(size)
          ..drawPath(path, paintFill)
          ..restore();
      default:
        canvas.drawPath(path, paintFill);
    }
  }

  @override
  bool shouldRepaint(_ChatBubblePainter oldDelegate) {
    return color != oldDelegate.color ||
        alignment != oldDelegate.alignment ||
        hasTail != oldDelegate.hasTail;
  }
}

extension _ChatBubbleCanvasExt on Canvas {
  Canvas flipHorz(Size size) {
    return this
      ..translate(size.width, 0)
      ..scale(-1, 1);
  }

  Canvas flipVert(Size size) {
    return this
      ..translate(0, size.height)
      ..scale(1, -1);
  }
}

class _MessageMeta extends StatelessWidget {
  const _MessageMeta({required this.message, required this.color});

  final ChatMessage message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final muted = color.withValues(alpha: 0.72);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          TimeOfDay.fromDateTime(message.createdAt).format(context),
          style: context.textTheme.labelSmall?.copyWith(color: muted),
        ),
        if (message.isMine) ...[
          const SizedBox(width: 7),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 140),
            child: Icon(
              _statusIcon,
              key: ValueKey(message.status),
              size: 13,
              color: message.status == ChatMessageStatus.failed
                  ? context.themeColor.error
                  : muted,
            ),
          ),
          if (message.status != ChatMessageStatus.sent) ...[
            const SizedBox(width: 4),
            Text(
              message.status == ChatMessageStatus.pending
                  ? context.l10n.sending
                  : context.l10n.failedTapToRetry,
              style: context.textTheme.labelSmall?.copyWith(
                color: message.status == ChatMessageStatus.failed
                    ? context.themeColor.error
                    : muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ],
    );
  }

  IconData get _statusIcon {
    switch (message.status) {
      case ChatMessageStatus.pending:
        return Iconsax.timer;
      case ChatMessageStatus.failed:
        return Iconsax.warning_2;
      case ChatMessageStatus.sent:
        return Iconsax.tick_circle;
    }
  }
}

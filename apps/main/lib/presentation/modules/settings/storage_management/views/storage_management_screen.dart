import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../../../../../domain/entities/chat/chat_local_storage_summary.dart';
import '../../../../../l10n/localization_ext.dart';
import '../../../../base/base.dart';
import '../bloc/storage_management_bloc.dart';

part 'storage_management.action.dart';

class StorageManagementScreen extends StatefulWidget {
  const StorageManagementScreen({super.key});

  static String routeName = '/settings/storage-management';

  @override
  State<StorageManagementScreen> createState() =>
      _StorageManagementScreenState();
}

class _StorageManagementScreenState extends StateBase<StorageManagementScreen> {
  @override
  StorageManagementBloc get bloc => BlocProvider.of(context);

  late ThemeData _themeData;

  TextTheme get textTheme => _themeData.textTheme;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => bloc.add(StorageManagementStartedEvent()),
    );
  }

  @override
  Widget build(BuildContext context) {
    _themeData = context.theme;
    return BlocBuilder<StorageManagementBloc, StorageManagementState>(
      builder: (context, state) {
        return ScreenForm(
          title: l10n.storage,
          showBackButton: true,
          onBack: _close,
          bgColor: context.themeColor.scaffoldBackgroundColor,
          child: SafeArea(
            top: false,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.themeColor.primary.withValues(alpha: 0.08),
                    context.themeColor.secondary.withValues(alpha: 0.48),
                    context.themeColor.scaffoldBackgroundColor,
                  ],
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildStorageCard(state),
                      const SizedBox(height: 18),
                      _buildClearButton(state),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStorageCard(StorageManagementState state) {
    final summary = state.summary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.themeColor.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.themeColor.borderColor),
        boxShadow: [
          BoxShadow(
            color: context.themeColor.shadowColor.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: summary == null && state.isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            : Column(
                children: [
                  _StorageInfoRow(
                    label: l10n.cachedUsers,
                    value: (summary?.peerCount ?? 0).toString(),
                  ),
                  _StorageDivider(),
                  _StorageInfoRow(
                    label: l10n.cachedMessages,
                    value: (summary?.messageCount ?? 0).toString(),
                  ),
                  _StorageDivider(),
                  _StorageInfoRow(
                    label: l10n.pendingMessages,
                    value: (summary?.pendingMessageCount ?? 0).toString(),
                  ),
                  _StorageDivider(),
                  _StorageInfoRow(
                    label: l10n.failedMessages,
                    value: (summary?.failedMessageCount ?? 0).toString(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildClearButton(StorageManagementState state) {
    final summary = state.summary;
    return SizedBox(
      width: double.infinity,
      child: ThemeButton.outline(
        title: l10n.clearLocalStorage,
        enable: summary != null && !summary.isEmpty && !state.isClearing,
        minimumSize: const Size.fromHeight(52),
        foregroundColor: context.themeColor.error,
        prefixIcon: state.isClearing
            ? SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.themeColor.error,
                ),
              )
            : null,
        onPressed: _confirmClearLocalStorage,
      ),
    );
  }
}

class _StorageInfoRow extends StatelessWidget {
  const _StorageInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.themeColor.labelText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.end,
            style: context.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: context.themeColor.dividerColor);
  }
}

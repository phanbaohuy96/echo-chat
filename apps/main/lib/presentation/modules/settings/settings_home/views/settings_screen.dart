import 'dart:async';

import 'package:core/core.dart';
import 'package:data_source/data_source.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../l10n/localization_ext.dart';
import '../../../../base/base.dart';
import '../../../auth/authentication_coordinator.dart';
import '../../storage_management/storage_management_coordinator.dart';
import '../bloc/settings_bloc.dart';

part 'settings.action.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static String routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends StateBase<SettingsScreen> {
  @override
  SettingsBloc get bloc => BlocProvider.of(context);

  late ThemeData _themeData;

  TextTheme get textTheme => _themeData.textTheme;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => bloc.add(SettingsStartedEvent()),
    );
  }

  @override
  Widget build(BuildContext context) {
    _themeData = context.theme;
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return ScreenForm(
          title: l10n.settings,
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
                      _buildUserHeader(state),
                      const SizedBox(height: 18),
                      _buildMenuCard(state),
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

  Widget _buildUserHeader(SettingsState state) {
    final user = state.user;
    final displayName = _userDisplayName(user);
    final username = user?.username?.trim();
    final email = user?.email?.trim();
    final phoneNumber = user?.phoneNumber?.trim();

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
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SettingsAvatar(initial: _userInitial(user)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (username?.isNotEmpty == true) ...[
                    const SizedBox(height: 5),
                    Text(
                      '@$username',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: context.themeColor.labelText,
                      ),
                    ),
                  ],
                  if (email?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    _buildHeaderLine(Iconsax.sms, email!),
                  ],
                  if (phoneNumber?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    _buildHeaderLine(Iconsax.call, phoneNumber!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.themeColor.labelText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: context.themeColor.labelText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(SettingsState state) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.themeColor.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.themeColor.borderColor),
      ),
      child: Column(
        children: [
          _SettingsMenuRow(
            icon: Iconsax.language_square,
            title: l10n.language,
            trailing: _buildLanguageSwitcher(),
          ),
          _SettingsDivider(),
          _SettingsMenuRow(
            icon: Iconsax.folder_open,
            title: l10n.storage,
            trailing: state.storageSummary == null
                ? null
                : Text(
                    '${state.storageSummary!.messageCount} ${l10n.messages}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: textTheme.bodyMedium?.copyWith(
                      color: context.themeColor.labelText,
                    ),
                  ),
            onTap: _openStorageManagement,
          ),
          _SettingsDivider(),
          _SettingsMenuRow(
            icon: Iconsax.logout,
            title: l10n.logout,
            destructive: true,
            onTap: _confirmLogout,
          ),
          _SettingsDivider(),
          _SettingsMenuRow(
            icon: Iconsax.info_circle,
            title: l10n.version,
            trailing: Text(
              ClientInfo.appVersion,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: textTheme.bodyMedium?.copyWith(
                color: context.themeColor.labelText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _userDisplayName(UserModel? user) {
    final name = user?.name?.trim();
    if (name?.isNotEmpty == true) {
      return name!;
    }
    final username = user?.username?.trim();
    if (username?.isNotEmpty == true) {
      return username!;
    }
    return l10n.user;
  }

  String _userInitial(UserModel? user) {
    final source = _userDisplayName(user).trim();
    if (source.isEmpty) {
      return 'U';
    }
    return source.characters.first.toUpperCase();
  }

  Widget _buildLanguageSwitcher() {
    final locale = context.watch<AppGlobalBloc>().state.locale;
    return EnViSwitch(
      isVILanguage: locale.languageCode == AppLocale.vi.languageCode,
      onChanged: _changeLanguage,
    );
  }
}

class _SettingsAvatar extends StatelessWidget {
  const _SettingsAvatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            context.themeColor.primary,
            context.themeColor.primary.withValues(alpha: 0.68),
          ],
        ),
      ),
      child: SizedBox.square(
        dimension: 64,
        child: Center(
          child: Text(
            initial,
            style: context.textTheme.titleLarge?.copyWith(
              color: context.themeColor.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsMenuRow extends StatelessWidget {
  const _SettingsMenuRow({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? context.themeColor.error
        : context.themeColor.onSurface;
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: trailing!,
                ),
              ),
            ],
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Iconsax.arrow_right_3,
                size: 18,
                color: destructive ? color : context.themeColor.labelText,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 18,
      endIndent: 18,
      color: context.themeColor.dividerColor,
    );
  }
}

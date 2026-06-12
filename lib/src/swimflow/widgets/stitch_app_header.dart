import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/app_user_role.dart';
import '../providers/swimflow_providers.dart';
import '../providers/swimmer_notifications_providers.dart';
import '../theme/tokens.dart';
import 'profile_avatar.dart';
import 'stitch_widgets.dart';

const double _kHeaderAvatar = 36;

Widget _avatarPlaceholder() {
  return Container(
    width: _kHeaderAvatar,
    height: _kHeaderAvatar,
    decoration: const BoxDecoration(
      color: StitchColors.primaryFixed,
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: const Icon(Icons.person_rounded, color: StitchColors.primary, size: 20),
  );
}

class _HeaderAvatar extends ConsumerWidget {
  const _HeaderAvatar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(swimflowProfileProvider);
    return async.when(
      data: (p) {
        if (p == null) return _avatarPlaceholder();
        return SwimflowProfileAvatar(profile: p, size: _kHeaderAvatar);
      },
      loading: () => _avatarPlaceholder(),
      error: (_, __) => _avatarPlaceholder(),
    );
  }
}

class _NotificationsHeaderButton extends ConsumerWidget {
  const _NotificationsHeaderButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(swimflowProfileProvider).valueOrNull;
    if (profile == null || profile.role != AppUserRole.swimmer) {
      return const SizedBox(width: 48);
    }
    final unread = ref.watch(unreadNotificationsCountProvider);
    return SizedBox(
      width: 48,
      child: IconButton(
        onPressed: () => context.push('/notifications'),
        icon: Badge(
          isLabelVisible: unread > 0,
          label: Text(unread > 9 ? '9+' : '$unread'),
          child: const Icon(Icons.notifications_outlined, color: StitchColors.primary),
        ),
      ),
    );
  }
}

class StitchMainShellHeader extends ConsumerWidget {
  const StitchMainShellHeader({super.key, this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StitchBlurBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const _HeaderAvatar(),
            const Spacer(),
            const StitchGradientTitle('SwimFlow', fontSize: 20),
            if (trailing != null) trailing! else const _NotificationsHeaderButton(),
          ],
        ),
      ),
    );
  }
}

class StitchSubpageHeader extends StatelessWidget {
  const StitchSubpageHeader({super.key, this.trailing, this.onBack});

  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return StitchBlurBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack ?? () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: StitchColors.onBackground),
            ),
            const Spacer(),
            const StitchGradientTitle('SwimFlow', fontSize: 20),
            if (trailing != null) trailing! else const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

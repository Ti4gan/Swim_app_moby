import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/firestore_messages.dart';
import '../models/app_user_role.dart';
import '../providers/swimflow_providers.dart';
import '../theme/tokens.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/stitch_app_header.dart';
import '../widgets/stitch_widgets.dart';

void _keyboardDone(BuildContext context) {
  FocusManager.instance.primaryFocus?.unfocus();
}

class StitchSettingsScreen extends ConsumerStatefulWidget {
  const StitchSettingsScreen({super.key});

  @override
  ConsumerState<StitchSettingsScreen> createState() => _StitchSettingsScreenState();
}

class _StitchSettingsScreenState extends ConsumerState<StitchSettingsScreen> {
  final _name = TextEditingController();
  final _coachInvite = TextEditingController();
  final _nameFocus = FocusNode();
  bool _seeded = false;
  bool _saving = false;
  bool _avatarBusy = false;
  bool _changingCoach = false;
  bool _coachNameSynced = false;
  String? _error;
  String? _coachChangeErr;
  String? _coachChangeOk;

  @override
  void dispose() {
    _name.dispose();
    _coachInvite.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _changeCoach() async {
    final repo = ref.read(swimflowRepositoryProvider);
    final code = _coachInvite.text.trim();
    if (repo == null) return;
    if (code.isEmpty) {
      setState(() => _coachChangeErr = 'Введите код нового тренера');
      return;
    }
    setState(() {
      _changingCoach = true;
      _coachChangeErr = null;
      _coachChangeOk = null;
    });
    try {
      await repo.redeemInviteCode(code);
      if (mounted) {
        setState(() {
          _changingCoach = false;
          _coachChangeOk = 'Тренер обновлён';
          _coachInvite.clear();
        });
      }
    } on FormatException catch (e) {
      if (mounted) {
        setState(() {
          _changingCoach = false;
          _coachChangeErr = e.message == 'invite_not_found'
              ? 'Код не найден'
              : e.message == 'invite_used'
                  ? 'Код уже использован'
                  : 'Не удалось применить код';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _changingCoach = false;
          _coachChangeErr = swimFirestoreMessageRu(e, saving: true);
        });
      }
    }
  }

  Future<void> _applyAvatarPreset(String? presetId) async {
    final repo = ref.read(swimflowRepositoryProvider);
    final p = ref.read(swimflowProfileProvider).valueOrNull;
    if (repo == null || p == null) return;
    setState(() {
      _avatarBusy = true;
      _error = null;
    });
    try {
      await repo.updateProfileDetails(
        displayName: p.displayName,
        sportRank: p.sportRankId,
        city: p.city,
        avatarUrl: '',
        avatarPreset: presetId ?? '',
      );
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _saveAll() async {
    final repo = ref.read(swimflowRepositoryProvider);
    final p = ref.read(swimflowProfileProvider).valueOrNull;
    if (repo == null || p == null) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Укажите имя');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await repo.updateProfileDetails(
        displayName: name,
        sportRank: p.sportRankId,
        city: p.city,
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(swimflowProfileProvider).valueOrNull;
    if (p != null && !_seeded) {
      _seeded = true;
      _name.text = p.displayName;
    }
    if (!_coachNameSynced &&
        p?.role == AppUserRole.swimmer &&
        p?.coachId != null &&
        p!.coachId!.trim().isNotEmpty &&
        (p.linkedCoachDisplayName == null || p.linkedCoachDisplayName!.trim().isEmpty)) {
      _coachNameSynced = true;
      final repo = ref.read(swimflowRepositoryProvider);
      if (repo != null) {
        unawaited(repo.syncLinkedCoachDisplayName());
      }
    }
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: StitchPageScaffold(
        bottomInset: safeBottom + 16,
        child: Column(
          children: [
            const StitchSubpageHeader(),
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + safeBottom),
                children: [
                  Text('Настройки', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  StitchGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.badge_rounded, color: StitchColors.primary, size: 22),
                            const SizedBox(width: 8),
                            Text('Профиль', style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _name,
                          focusNode: _nameFocus,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _keyboardDone(context),
                          decoration: InputDecoration(
                            labelText: 'Имя и фамилия',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (p != null) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: SwimflowProfileAvatar(
                                    profile: p,
                                    size: 72,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Аватар',
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                            color: StitchColors.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        for (final id in ProfileAvatarPresets.ids)
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: _avatarBusy ? null : () => _applyAvatarPreset(id),
                                              customBorder: const CircleBorder(),
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 180),
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: p.avatarPreset == id
                                                        ? StitchColors.primary
                                                        : Colors.transparent,
                                                    width: 3,
                                                  ),
                                                ),
                                                child: ProfileAvatarPresets.tile(id, 44),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: _avatarBusy ? null : () => _applyAvatarPreset(null),
                                      child: const Text('Стандартный аватар'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (p?.role == AppUserRole.swimmer && p?.coachId != null) ...[
                    StitchGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.link_rounded, color: StitchColors.primary, size: 22),
                              const SizedBox(width: 8),
                              Text('Тренер', style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Текущий тренер',
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              letterSpacing: 0.6,
                              color: StitchColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ref.watch(swimmerCoachDisplayNameProvider).when(
                            loading: () => Text(
                              'Загрузка…',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            error: (_, __) => Text(
                              '—',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            data: (name) => Text(
                              name != null && name.isNotEmpty ? name : '—',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: StitchColors.onBackground,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _coachInvite,
                            textCapitalization: TextCapitalization.characters,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: 'Код нового тренера',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          if (_coachChangeErr != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _coachChangeErr!,
                              style: GoogleFonts.inter(color: Colors.red.shade700, fontSize: 13),
                            ),
                          ],
                          if (_coachChangeOk != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _coachChangeOk!,
                              style: GoogleFonts.inter(color: Colors.green.shade700, fontSize: 13),
                            ),
                          ],
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _changingCoach ? null : _changeCoach,
                            style: FilledButton.styleFrom(backgroundColor: StitchColors.primary),
                            child: _changingCoach
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Сменить тренера'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: GoogleFonts.inter(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _saveAll,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: StitchColors.primary,
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Сохранить', style: GoogleFonts.lexend(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/swimflow_providers.dart';
import '../../theme/coach_theme.dart';

class CoachInviteSheet extends ConsumerStatefulWidget {
  const CoachInviteSheet({super.key});

  @override
  ConsumerState<CoachInviteSheet> createState() => _CoachInviteSheetState();
}

class _CoachInviteSheetState extends ConsumerState<CoachInviteSheet> {
  String? _err;
  bool _loading = false;

  Future<void> _generate() async {
    setState(() {
      _err = null;
      _loading = true;
    });
    try {
      final repo = ref.read(coachRepositoryProvider);
      if (repo == null) return;
      await repo.createOrRegenerateInvite();
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _err = '$e';
        _loading = false;
      });
    }
  }

  void _shareCode(String code) {
    SharePlus.instance.share(
      ShareParams(
        text: 'Код приглашения SwimFlow: $code\nВведите его при регистрации в приложении.',
        subject: 'Приглашение в SwimFlow',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inviteCode = ref.watch(coachInviteCodeProvider).valueOrNull;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: CoachColors.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(
                    'Пригласить пловца',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  if (inviteCode == null) ...[
                    Text(
                      'Создайте код — пловцы смогут ввести его при регистрации и присоединиться к вашей группе.',
                      style: GoogleFonts.inter(fontSize: 14, color: CoachColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _generate,
                      style: FilledButton.styleFrom(
                        backgroundColor: CoachColors.primaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Создать код',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                    ),
                  ] else ...[
                    Text(
                      'Один код на аккаунт. Можно пересоздать — старый перестанет работать.',
                      style: GoogleFonts.inter(fontSize: 14, color: CoachColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      inviteCode,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: inviteCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Код скопирован')),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('Копировать'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _shareCode(inviteCode),
                            style: FilledButton.styleFrom(
                              backgroundColor: CoachColors.primaryContainer,
                            ),
                            icon: const Icon(Icons.share_rounded, color: Colors.white),
                            label: const Text('Отправить', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loading ? null : _generate,
                      style: FilledButton.styleFrom(
                        backgroundColor: CoachColors.primaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Пересоздать код',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                    ),
                  ],
                  if (_err != null) ...[
                    const SizedBox(height: 12),
                    Text(_err!, style: GoogleFonts.inter(color: Colors.red.shade700, fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

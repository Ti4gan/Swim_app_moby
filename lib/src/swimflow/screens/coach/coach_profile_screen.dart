import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/auth_providers.dart';
import '../../providers/swimflow_providers.dart';
import '../../theme/coach_theme.dart';
import '../../widgets/coach_widgets.dart';
import 'coach_athletes_screen.dart';

class CoachProfileScreen extends ConsumerWidget {
  const CoachProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(swimflowProfileProvider);

    return Scaffold(
      body: CoachPageBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CoachFlowHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  profile.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('$e'),
                    data: (p) {
                      if (p == null) return const SizedBox.shrink();
                      return CoachGlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.displayName.isEmpty ? 'Тренер' : p.displayName,
                              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.email,
                              style: GoogleFonts.inter(color: CoachColors.onSurfaceVariant),
                            ),
                            if (p.city.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(p.city, style: GoogleFonts.inter(color: CoachColors.onSurfaceVariant)),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  CoachGlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.vpn_key_rounded, color: CoachColors.primaryContainer),
                          title: Text('Код приглашения', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            'Создать код для нового пловца',
                            style: GoogleFonts.inter(fontSize: 13, color: CoachColors.onSurfaceVariant),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => CoachAthletesScreen.showInviteSheet(context),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.edit_note_rounded, color: CoachColors.primaryContainer),
                          title: Text('Запись тренировки', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            'Сеты, дистанция, время',
                            style: GoogleFonts.inter(fontSize: 13, color: CoachColors.onSurfaceVariant),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push('/coach/record'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.groups_rounded, color: CoachColors.primaryContainer),
                          title: Text('Мои пловцы', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.go('/coach/swimmers'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(firebaseAuthProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout_rounded, color: CoachColors.primary),
                    label: Text(
                      'Выйти',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: CoachColors.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: CoachColors.primaryContainer),
                    ),
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

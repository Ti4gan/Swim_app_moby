import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/swimflow_providers.dart';
import '../theme/tokens.dart';
import '../widgets/competition_swims_panel.dart';
import '../widgets/stitch_app_header.dart';
import '../widgets/stitch_widgets.dart';

class StitchCompetitionSwimsScreen extends ConsumerWidget {
  const StitchCompetitionSwimsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swims = ref.watch(swimflowCompetitionSwimsProvider);
    final bottomFab = MediaQuery.paddingOf(context).bottom + 44;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          StitchPageScaffold(
            bottomInset: 96,
            child: Column(
              children: [
                const StitchMainShellHeader(),
                Expanded(
                  child: swims.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (list) => CompetitionSwimsPanel(
                      swims: list,
                      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomFab + 56),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: bottomFab,
            child: FloatingActionButton.extended(
              onPressed: () => context.push('/competitions/new'),
              backgroundColor: StitchColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Заплыв', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

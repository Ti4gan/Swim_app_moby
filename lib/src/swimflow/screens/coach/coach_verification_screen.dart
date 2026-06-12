import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../auth/auth_providers.dart';
import '../../models/coach_verification_status.dart';
import '../../providers/swimflow_providers.dart';
import '../../services/coach_document_storage_service.dart';
import '../../theme/coach_theme.dart';
import '../../widgets/coach_widgets.dart';

final coachDocumentStorageServiceProvider = Provider<CoachDocumentStorageService>((ref) {
  return CoachDocumentStorageService();
});

class CoachVerificationScreen extends ConsumerStatefulWidget {
  const CoachVerificationScreen({super.key});

  @override
  ConsumerState<CoachVerificationScreen> createState() => _CoachVerificationScreenState();
}

class _CoachVerificationScreenState extends ConsumerState<CoachVerificationScreen> {
  bool _uploading = false;
  String? _error;

  Future<void> _pickAndUpload() async {
    final repo = ref.read(swimflowRepositoryProvider);
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (repo == null || uid == null) return;

    setState(() => _error = null);

    final pick = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: kIsWeb,
    );
    if (!mounted) return;
    if (pick == null || pick.files.isEmpty) return;

    setState(() => _uploading = true);
    try {
      await repo.ensureCoachRegistrationRequest();

      final storage = ref.read(coachDocumentStorageServiceProvider);
      final objectPaths = await storage.uploadPlatformFiles(uid: uid, files: pick.files);
      if (objectPaths.isEmpty) {
        throw StateError('Не удалось прочитать выбранные файлы');
      }
      await repo.appendCoachRegistrationCertificates(objectPaths);
    } catch (e) {
      final storage = ref.read(coachDocumentStorageServiceProvider);
      setState(() => _error = storage.uploadErrorRu(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _resubmit() async {
    final repo = ref.read(swimflowRepositoryProvider);
    if (repo == null) return;
    setState(() {
      _error = null;
      _uploading = true;
    });
    try {
      await repo.resubmitCoachVerificationAfterRejection();
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(firebaseAuthProvider).signOut();
    if (mounted) context.go('/login');
  }

  Future<void> _openDocument(String ref, CoachDocumentStorageService storage) async {
    try {
      final url = storage.openUrlForRef(ref) ?? await storage.resolveDownloadUrl(ref);
      if (url == null || url.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ссылка на файл недоступна')),
        );
        return;
      }
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть файл')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(storage.uploadErrorRu(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final profile = ref.watch(swimflowProfileProvider).valueOrNull;
    final db = ref.watch(firestoreProvider);
    final storage = ref.watch(coachDocumentStorageServiceProvider);

    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final rejected = profile?.coachVerificationStatus == CoachVerificationStatus.rejected;
    final pending = profile?.coachVerificationStatus == CoachVerificationStatus.pending;

    return Theme(
      data: CoachAppTheme.light,
      child: Scaffold(
        backgroundColor: CoachColors.background,
        body: CoachPageBackground(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CoachBlurAppBar(
                title: 'Проверка тренера',
                trailing: TextButton(onPressed: _signOut, child: const Text('Выйти')),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Text(
                      rejected
                          ? 'Заявка отклонена. Загрузите документы и отправьте снова.'
                          : pending
                              ? 'Загрузите подтверждающие документы (PDF, фото). После проверки администратором откроется доступ к CoachFlow.'
                              : 'Документы на проверке.',
                      style: GoogleFonts.inter(fontSize: 15, color: CoachColors.onBackground),
                    ),
                    const SizedBox(height: 20),
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: db.collection(FirestoreCollections.coachRegistrationRequests).doc(uid).snapshots(),
                      builder: (context, snap) {
                        final urls = snap.data?.data()?['certificateUrls'];
                        final list = urls is List
                            ? urls.map((e) => '$e').where(CoachDocumentStorageService.isRemoteRef).toList()
                            : <String>[];
                        if (list.isEmpty) {
                          return Text(
                            'Файлы ещё не прикреплены',
                            style: GoogleFonts.inter(color: CoachColors.onSurfaceVariant),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Прикреплённые файлы',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: CoachColors.onBackground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final ref in list)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: CoachColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                  child: ListTile(
                                    leading: const Icon(Icons.description_outlined),
                                    title: Text(CoachDocumentStorageService.displayNameForRef(ref)),
                                    trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                                    onTap: () => _openDocument(ref, storage),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    if (_error != null) ...[
                      Text(_error!, style: GoogleFonts.inter(color: Colors.red.shade700, fontSize: 13)),
                      const SizedBox(height: 12),
                    ],
                    FilledButton.icon(
                      onPressed: _uploading ? null : _pickAndUpload,
                      style: FilledButton.styleFrom(
                        backgroundColor: CoachColors.primaryContainer,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: _uploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.upload_file_outlined),
                      label: Text(_uploading ? 'Загрузка…' : 'Добавить документы'),
                    ),
                    if (rejected) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _uploading ? null : _resubmit,
                        child: const Text('Отправить на проверку снова'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

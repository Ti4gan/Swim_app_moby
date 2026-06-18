import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/auth_messages.dart';
import '../auth/auth_providers.dart';
import '../data/swimflow_repository.dart';
import '../models/app_user_role.dart';
import '../models/coach_verification_status.dart';
import '../models/swimflow_sport_rank.dart';
import '../providers/swimflow_providers.dart';
import '../theme/tokens.dart';
import '../widgets/stitch_widgets.dart';

class StitchRegisterScreen extends ConsumerStatefulWidget {
  const StitchRegisterScreen({super.key});

  @override
  ConsumerState<StitchRegisterScreen> createState() => _StitchRegisterScreenState();
}

class _StitchRegisterScreenState extends ConsumerState<StitchRegisterScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  String _rank = SwimflowSportRank.firstAdult;
  String _roleSeg = AppUserRole.swimmer;
  final _inviteCode = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _inviteCode.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Укажите имя');
      return;
    }
    if (_password.text.length < 6) {
      setState(() => _error = 'Пароль не короче 6 символов');
      return;
    }
    if (_roleSeg == AppUserRole.swimmer && _inviteCode.text.trim().isEmpty) {
      setState(() => _error = 'Введите код тренера');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    UserCredential? cred;
    SwimflowRepository? repo;

    Future<void> discardIncomplete() async {
      try {
        await repo?.deleteOwnUserProfile();
      } catch (_) {}
      try {
        await cred?.user?.delete();
      } catch (_) {}
    }

    final email = _email.text.trim().toLowerCase();
    final db = ref.read(firestoreProvider);
    try {
      final auth = ref.read(firebaseAuthProvider);
      cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: _password.text,
      );
      final uid = cred.user?.uid;
      if (uid == null) throw StateError('no_uid');
      repo = SwimflowRepository(db, uid);
      if (_roleSeg == AppUserRole.coach) {
        await repo.upsertCoachProfile(
          email: email,
          displayName: name,
          city: '',
        );
        await repo.ensureCoachRegistrationRequest();
      } else {
        final code = _inviteCode.text.trim();
        await repo.upsertSwimmerProfile(
          email: email,
          displayName: name,
          sportRank: _rank,
          city: '',
        );
        try {
          await repo.redeemInviteCode(code);
        } catch (_) {
          await discardIncomplete();
          if (mounted) setState(() {
            _error = 'Код недействителен';
            _loading = false;
          });
          return;
        }
      }
      if (!mounted) return;
      if (_roleSeg == AppUserRole.coach) {
        context.go(
          CoachVerificationConfig.enabled ? '/coach/verification' : '/coach/dashboard',
        );
      } else {
        context.go('/home');
      }
    } on FirebaseAuthException catch (e) {
      await discardIncomplete();
      if (mounted) setState(() => _error = authErrorMessageRu(e));
    } on FirebaseException catch (e) {
      await discardIncomplete();
      if (mounted) setState(() => _error = firestoreErrorMessageRu(e));
    } catch (e) {
      await discardIncomplete();
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StitchPageScaffold(
        bottomInset: 24,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IconButton(
                alignment: Alignment.centerLeft,
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const StitchGradientTitle('Новый аккаунт', fontSize: 28),
              const SizedBox(height: 8),
              Text(
                'Вход или регистрация',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: StitchColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: AppUserRole.swimmer,
                    label: Text('Пловец'),
                    icon: Icon(Icons.pool_outlined, size: 18),
                  ),
                  ButtonSegment<String>(
                    value: AppUserRole.coach,
                    label: Text('Тренер'),
                    icon: Icon(Icons.sports_martial_arts_outlined, size: 18),
                  ),
                ],
                selected: {_roleSeg},
                onSelectionChanged: (s) => setState(() => _roleSeg = s.first),
              ),
              const SizedBox(height: 28),
              StitchGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _name,
                      focusNode: _nameFocus,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _emailFocus.requestFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Имя и фамилия',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_roleSeg == AppUserRole.swimmer) ...[
                      DropdownButtonFormField<String>(
                        value: _rank,
                        decoration: const InputDecoration(
                          labelText: 'Текущий разряд',
                          border: OutlineInputBorder(),
                        ),
                        // Используем короткие названия для отображаемого значения, чтобы не было overflow на малых экранах
                        selectedItemBuilder: (context) => [
                          for (final id in SwimflowSportRank.orderedIds)
                            Text(
                              SwimflowSportRank.labelShortRu(id),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                        items: [
                          for (final id in SwimflowSportRank.orderedIds)
                            DropdownMenuItem(
                              value: id,
                              child: Text(
                                SwimflowSportRank.labelRu(id),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _rank = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _inviteCode,
                        textCapitalization: TextCapitalization.characters,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Код тренера',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: _email,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Электронная почта',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _password,
                      focusNode: _passwordFocus,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: GoogleFonts.inter(color: Colors.red.shade700, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: StitchColors.primary,
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Зарегистрироваться', style: GoogleFonts.lexend(fontWeight: FontWeight.w600)),
                    ),
                    if (_roleSeg == AppUserRole.coach && CoachVerificationConfig.enabled) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Для доступа тренера обязательна загрузка документов и проверка администратором.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
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

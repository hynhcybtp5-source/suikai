import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../data/supabase_repositories.dart';
import '../../services/suikai_service.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/mobile_localizations.dart';
import '../legal/legal_pages.dart';

class LoginPage extends StatefulWidget {
  final String pendingRoute;
  const LoginPage({super.key, required this.pendingRoute});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false;
  bool telegramBusy = false;
  bool _didNavigate = false;
  AuthChangeEvent? _lastAuthEvent;
  bool? _lastSessionWasNull;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSubscription = SupabaseBackend.client.auth.onAuthStateChange.listen(
      (data) {
        _lastAuthEvent = data.event;
        _lastSessionWasNull = data.session == null;
        if (kDebugMode) {
          debugPrint('AUTH EVENT=${data.event}');
          debugPrint('SESSION NULL=${data.session == null}');
          debugPrint(
            'CURRENT SESSION NULL=${Supabase.instance.client.auth.currentSession == null}',
          );
          debugPrint(
            'CURRENT USER NULL=${Supabase.instance.client.auth.currentUser == null}',
          );
        }
        if (data.event == AuthChangeEvent.signedIn &&
            data.session != null &&
            mounted) {
          unawaited(_completeLoginFromAuthCallback());
        }
      },
      onError: (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('Auth state error: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (kIsWeb && Uri.base.queryParameters['code'] != null) {
          await SuikaiService.auth.completeTelegramWebLogin();
        }

        if (SuikaiService.hasValidSession && mounted) {
          await _completeLoginFromAuthCallback();
        }
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('Telegram callback failed: $error');
          debugPrintStack(stackTrace: stackTrace);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).ui('telegramLoginFailed'),
              ),
            ),
          );
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !kDebugMode) return;
    debugPrint('CALLBACK APP RESUMED');
    debugPrint('AUTH EVENT=${_lastAuthEvent ?? 'none'}');
    debugPrint('SESSION NULL=${_lastSessionWasNull ?? true}');
    debugPrint(
      'CURRENT SESSION NULL=${Supabase.instance.client.auth.currentSession == null}',
    );
    debugPrint(
      'CURRENT USER NULL=${Supabase.instance.client.auth.currentUser == null}',
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() => busy = true);
    try {
      await SuikaiService.login(email.text, password.text);
      await _completeLoginFromAuthCallback();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).ui('invalidCredentials'),
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _loginWithTelegram() async {
    setState(() {
      busy = true;
      telegramBusy = true;
    });
    try {
      await SuikaiService.loginWithTelegram();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Telegram login failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (!mounted) return;
      final message = _isCancellationError(error)
          ? AppLocalizations.of(context).ui('telegramLoginCancelled')
          : AppLocalizations.of(context).ui('telegramLoginFailed');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          telegramBusy = false;
        });
      }
    }
  }

  Future<void> _completeLoginFromAuthCallback() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (_didNavigate || !mounted || session == null) return;
    setState(() {
      _didNavigate = true;
      busy = true;
      telegramBusy = true;
    });
    try {
      if (kDebugMode) {
        debugPrint(
          'Completing login callback: lastAuthEvent=${_lastAuthEvent ?? 'none'}',
        );
      }
      await SuikaiService.auth.syncCurrentProfile();
      await SuikaiService.currentProfile();
      if (mounted) {
        Navigator.pushReplacementNamed(context, widget.pendingRoute);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() {
          _didNavigate = false;
          busy = false;
          telegramBusy = false;
        });
      }
      if (kDebugMode) {
        debugPrint('Profile sync after Telegram login failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).ui('telegramProfileSyncFailed'),
            ),
          ),
        );
      }
    }
  }

  bool _isCancellationError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('cancel') ||
        message.contains('aborted') ||
        message.contains('closed by user');
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.ui('login')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.person_rounded, size: 72, color: AppTheme.orange),
          const SizedBox(height: 24),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l10n.ui('email')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            obscureText: true,
            decoration: InputDecoration(labelText: l10n.ui('password')),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: busy ? null : login,
            child: Text(
              busy && !telegramBusy ? l10n.ui('loggingIn') : l10n.ui('login'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : _loginWithTelegram,
            icon: telegramBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              telegramBusy
                  ? l10n.ui('openingTelegram')
                  : l10n.ui('loginWithTelegram'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RegisterPage(pendingRoute: widget.pendingRoute),
              ),
            ),
            child: Text(l10n.ui('register')),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                ),
                child: Text(l10n.ui('privacyPolicy')),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
                ),
                child: Text(l10n.ui('termsOfService')),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CommunityGuidelinesPage(),
                  ),
                ),
                child: Text(l10n.ui('communityGuidelines')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  final String pendingRoute;
  const RegisterPage({super.key, required this.pendingRoute});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController(),
      phone = TextEditingController(),
      city = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  bool busy = false;
  bool _acceptedUgcTerms = false;
  @override
  void dispose() {
    for (final c in [name, phone, city, email, password]) c.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!_acceptedUgcTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).ui('ugcConsentRequired')),
        ),
      );
      return;
    }
    if (city.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).source('กรุณากรอกชื่อเมือง'),
          ),
        ),
      );
      return;
    }
    if (name.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).ui('completeRegistration'),
          ),
        ),
      );
      return;
    }
    setState(() => busy = true);
    try {
      await SuikaiService.register(
        name: name.text,
        phone: phone.text,
        email: email.text,
        password: password.text,
        city: city.text.trim(),
        acceptedUgcTerms: _acceptedUgcTerms,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).ui('registrationSuccess'),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).ui('emailExists')),
          ),
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _loginWithTelegram() async {
    if (!_acceptedUgcTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).ui('ugcConsentRequired')),
        ),
      );
      return;
    }
    setState(() => busy = true);
    try {
      await SuikaiService.loginWithTelegram();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Telegram login failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (!mounted) return;
      final message = _isCancellationError(error)
          ? AppLocalizations.of(context).ui('telegramLoginCancelled')
          : AppLocalizations.of(context).ui('telegramLoginFailed');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  bool _isCancellationError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('cancel') ||
        message.contains('aborted') ||
        message.contains('closed by user');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ui('register'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: name,
            decoration: InputDecoration(labelText: l10n.ui('name')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: l10n.ui('phone')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: city,
            decoration: InputDecoration(
              labelText: l10n.source('เมือง'),
              hintText: l10n.source('กรอกชื่อเมือง'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l10n.ui('email')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            obscureText: true,
            decoration: InputDecoration(labelText: l10n.ui('password')),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _acceptedUgcTerms,
                onChanged: busy
                    ? null
                    : (value) =>
                          setState(() => _acceptedUgcTerms = value ?? false),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(l10n.ui('ugcConsentPrefix')),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TermsOfServicePage(),
                          ),
                        ),
                        child: Text(l10n.ui('termsOfService')),
                      ),
                      Text(l10n.ui('ugcConsentAnd')),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CommunityGuidelinesPage(),
                          ),
                        ),
                        child: Text(l10n.ui('communityGuidelines')),
                      ),
                      const Text('.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: busy ? null : register,
            child: Text(busy ? l10n.ui('registering') : l10n.ui('register')),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : _loginWithTelegram,
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              busy
                  ? l10n.ui('openingTelegram')
                  : l10n.ui('registerWithTelegram'),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});
  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final name = TextEditingController(),
      phone = TextEditingController(),
      email = TextEditingController(),
      viber = TextEditingController(),
      city = TextEditingController();
  UserProfile? profile;
  String avatar = '';
  bool _saving = false;
  String? _saveError;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final p = await SuikaiService.currentProfile();
    if (p != null && mounted) {
      setState(() {
        profile = p;
        name.text = p.name;
        phone.text = p.phone;
        email.text = p.email;
        viber.text = p.viber;
        city.text = p.city;
        avatar = p.avatar;
      });
    }
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    viber.dispose();
    city.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    if (!await ensureUgcLegalAcceptance(context)) return;
    final image = await SuikaiService.pickImage();
    if (image != null) {
      final path = await SuikaiService.storage.persistImage(
        image.file.path,
        image.extension,
      );
      if (mounted) setState(() => avatar = path);
    }
  }

  Future<void> save() async {
    final p = profile;
    if (p == null || _saving) return;
    if (!await ensureUgcLegalAcceptance(context)) return;
    final cityText = city.text.trim();
    CityRecord? matchedCity;
    if (cityText.isNotEmpty) {
      final normalized = cityText.toLowerCase();
      for (final candidate in SuikaiService.activeCities) {
        final names = [
          candidate.name,
          candidate.nameTh,
          candidate.nameShn,
          candidate.nameEn,
          candidate.nameMy,
        ];
        if (names.any((name) => name.trim().toLowerCase() == normalized)) {
          matchedCity = candidate;
          break;
        }
      }
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final saved = await SuikaiService.updateProfile(
        UserProfile(
          id: p.id,
          name: name.text.trim(),
          phone: phone.text.trim(),
          email: email.text.trim(),
          avatar: avatar,
          city: cityText,
          cityId:
              matchedCity?.id ?? (cityText == p.city.trim() ? p.cityId : null),
          viber: viber.text.trim(),
          createdAt: p.createdAt,
        ),
      );
      if (mounted) Navigator.pop(context, saved);
    } catch (error, stackTrace) {
      debugPrint('Profile save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) setState(() => _saveError = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ui('editProfile'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppTheme.orangeSoft,
                  child: Icon(
                    avatar.isEmpty ? Icons.person_rounded : Icons.photo_rounded,
                    color: AppTheme.orange,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: pick,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(
                        AppLocalizations.of(context).source('เปลี่ยนรูป'),
                      ),
                    ),
                    if (avatar.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => setState(() => avatar = ''),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(
                          AppLocalizations.of(context).source('ลบรูป'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: name,
            decoration: InputDecoration(labelText: l10n.ui('name')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phone,
            decoration: InputDecoration(labelText: l10n.ui('phone')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: viber,
            decoration: const InputDecoration(labelText: 'Viber'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: city,
            decoration: InputDecoration(labelText: l10n.source('เมืองที่อยู่')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: email,
            readOnly: true,
            decoration: InputDecoration(labelText: l10n.ui('email')),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.block_rounded),
            title: Text(l10n.ui('blockedUsers')),
            subtitle: Text(l10n.ui('blockedUsersDescription')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BlockedUsersPage()),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.ui('privacyPolicy')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.ui('termsOfService')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.people_outline_rounded),
            title: Text(l10n.ui('communityGuidelines')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CommunityGuidelinesPage(),
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.red,
            ),
            title: Text(
              l10n.ui('deleteAccount'),
              style: const TextStyle(color: Colors.red),
            ),
            subtitle: Text(l10n.ui('deleteAccountDescription')),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.red,
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeleteAccountPage()),
            ),
          ),
          const SizedBox(height: 20),
          if (_saveError != null) ...[
            Text(_saveError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
          ],
          ElevatedButton(
            onPressed: _saving ? null : save,
            child: Text(_saving ? l10n.source('กำลังบันทึก...') : l10n.save),
          ),
        ],
      ),
    );
  }
}

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  late Future<List<UserProfile>> _users = SuikaiService.getBlockedUsers();
  String? _busyId;

  Future<void> _unblock(UserProfile user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context).ui('unblockSellerQuestion')),
        content: Text(
          AppLocalizations.of(
            context,
          ).ui('unblockSellerConfirm').replaceFirst('{name}', user.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(context).source('ยกเลิก')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(AppLocalizations.of(context).ui('unblockSeller')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busyId = user.id);
    try {
      await SuikaiService.unblockUser(user.id);
      if (!mounted) return;
      setState(() => _users = SuikaiService.getBlockedUsers());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).ui('unblockSellerSuccess'),
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Unblock seller failed: id=${user.id} error=$error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).ui('unblockSellerFailed')}: $error',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ui('blockedUsers'))),
      body: FutureBuilder<List<UserProfile>>(
        future: _users,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('${l10n.ui('loadFailed')}: ${snapshot.error}'),
            );
          }
          final users = snapshot.data ?? const [];
          if (users.isEmpty) {
            return Center(child: Text(l10n.ui('blockedUsersEmpty')));
          }
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    user.name.isEmpty ? '?' : user.name.substring(0, 1),
                  ),
                ),
                title: Text(user.name.isEmpty ? l10n.ui('seller') : user.name),
                subtitle: Text(user.city),
                trailing: TextButton(
                  onPressed: _busyId == user.id ? null : () => _unblock(user),
                  child: Text(
                    _busyId == user.id
                        ? l10n.source('กำลังบันทึก...')
                        : l10n.ui('unblockSeller'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/suikai_service.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/mobile_localizations.dart';

class LoginPage extends StatefulWidget {
  final String pendingRoute;
  const LoginPage({super.key, required this.pendingRoute});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() => busy = true);
    try {
      await SuikaiService.login(email.text, password.text);
      if (mounted) Navigator.pushReplacementNamed(context, widget.pendingRoute);
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
            child: Text(busy ? l10n.ui('loggingIn') : l10n.ui('login')),
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
      email = TextEditingController(),
      password = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    for (final c in [name, phone, email, password]) c.dispose();
    super.dispose();
  }

  Future<void> register() async {
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
            onPressed: busy ? null : register,
            child: Text(busy ? l10n.ui('registering') : l10n.ui('register')),
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
      email = TextEditingController();
  UserProfile? profile;
  String avatar = '';
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final p = await SuikaiService.currentProfile();
    if (p != null && mounted)
      setState(() {
        profile = p;
        name.text = p.name;
        phone.text = p.phone;
        email.text = p.email;
        avatar = p.avatar;
      });
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> pick() async {
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
    if (p == null) return;
    await SuikaiService.updateProfile(
      UserProfile(
        id: p.id,
        name: name.text.trim(),
        phone: phone.text.trim(),
        email: email.text.trim(),
        avatar: avatar,
        createdAt: p.createdAt,
      ),
    );
    if (mounted) Navigator.pop(context);
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
            controller: email,
            readOnly: true,
            decoration: InputDecoration(labelText: l10n.ui('email')),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: save, child: Text(l10n.save)),
          OutlinedButton(
            onPressed: () async {
              await SuikaiService.logout();
              if (mounted)
                Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            },
            child: Text(l10n.ui('logout')),
          ),
        ],
      ),
    );
  }
}

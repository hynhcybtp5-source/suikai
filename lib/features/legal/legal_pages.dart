import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/legal_config.dart';
import '../../core/theme/app_theme.dart';
import '../../services/suikai_service.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) => const _LegalPage(
    title: 'Privacy Policy',
    sections: [
      _LegalSection('Information We Use', [
        'Account and profile information, such as your name, phone number, email address, profile photo, and city.',
        'GPS location when you allow it, to show distances and help identify product or shop locations.',
        'Photos, videos, product and shop information, and text that you publish.',
        'Random device identifiers used to prevent spam and count likes and views.',
        'Usage information, such as likes, views, reports, blocks, and notifications.',
      ]),
      _LegalSection('Purposes and Processors', [
        'We use this information to operate the marketplace, show relevant content, prevent fraud, and keep the community safe.',
        'Information is processed and stored through Supabase and its file-storage service so that accounts, the database, and files can operate.',
        'We do not sell your personal information.',
        'Supabase provides authentication, database, storage, and server functions for Suikai.',
        'Telegram processes the sign-in flow when you choose Telegram sign-in. YouTube, OpenStreetMap, Viber, phone, map, and exchange-rate services receive requests only when their respective features are used.',
      ]),
      _LegalSection('Retention and Deletion', [
        'Information is kept for as long as needed to provide the service, maintain security, and meet legal obligations.',
        'You can delete your account in Profile > Edit profile > Delete account. Your account information, content, and owned files are deleted through the in-app process.',
        'Non-account-linked view data and information needed for security may remain in de-identified form when necessary.',
        'Reports, audit/security information, and information required for legal, fraud-prevention, or security purposes may be retained only as necessary.',
      ]),
      _LegalSection('Permissions and Security', [
        'You control location, camera, and microphone permissions through your operating system.',
        'Data is transmitted over secure connections, and data access is restricted by account.',
        'You can request correction or deletion of information and contact us with questions.',
        'Listings and shops may make submitted content, city, and contact details public. Coordinates are shown only when the owner enables location visibility.',
      ]),
      _LegalSection('Children and Changes', [
        'Suikai is a general marketplace and is not directed to children.',
        'We may update this policy and will show the current version in the app.',
      ]),
    ],
  );
}

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) => const _LegalPage(
    title: 'Terms of Service',
    sections: [
      _LegalSection('Using Suikai', [
        'Suikai is a marketplace where users publish product listings and shops. Buyers and sellers are responsible for communication, pricing, delivery, and agreements between them.',
        'Users must provide accurate information and are responsible for their accounts and the content, photos, and videos they publish.',
        'Suikai does not process marketplace payments in the app. Buyers and sellers are responsible for prices, payment arrangements, delivery, inspection, and agreements.',
      ]),
      _LegalSection('Prohibited Conduct', [
        'Do not commit fraud, impersonate others, spam, deceive people, or use the service for illegal activity.',
        'Do not publish illegal or dangerous goods, content that infringes others’ rights, or inappropriate content.',
        'Do not publish private information without permission, deceptive links, malware, or false or misleading listings.',
      ]),
      _LegalSection('Service Moderation', [
        'Suikai may hide, remove, or restrict listings, and suspend accounts or shops, when it finds a violation, security risk, or another reasonable basis.',
        'Users can report content, users, and shops, and block sellers.',
        'Repeated or serious violations may result in account or shop suspension or termination.',
      ]),
      _LegalSection('Liability and Changes', [
        'Suikai is not a party to transactions between users. Please check goods and counterparties before transacting.',
        'We may update these terms when necessary and will show the current version in the app.',
        'External services such as Telegram, YouTube, maps, Viber, and phone links have their own terms and privacy practices when you choose to use them.',
      ]),
    ],
  );
}

class CommunityGuidelinesPage extends StatelessWidget {
  const CommunityGuidelinesPage({super.key});

  @override
  Widget build(BuildContext context) => const _LegalPage(
    title: 'Community Guidelines',
    sections: [
      _LegalSection('A Safe Community', [
        'Do not commit fraud, deceive or impersonate others, or request information or money through unsafe means.',
        'Do not harass, threaten, insult, or disturb others.',
        'Do not repeat messages or listings to spam people.',
      ]),
      _LegalSection('Content and Goods', [
        'Do not publish illegal or dangerous goods, or content that violates laws or others’ rights.',
        'Do not publish photos or videos that are illegal, inappropriate, or misleading.',
        'Use only photos, videos, and information that you have the right to publish.',
        'Never post sexual or exploitative content, child sexual abuse or exploitation material, hate or violent extremist content, stolen goods, prohibited weapons, drugs, malware, deceptive links, or private information without permission.',
      ]),
      _LegalSection('Report, Block, and Moderation', [
        'Use Report when you find a user, shop, or product that violates these guidelines, and use Block to stop seeing an unwanted seller.',
        'The team may review, hide, or remove content and suspend accounts or shops that violate these guidelines.',
      ]),
    ],
  );
}

/// Checks the server-backed legal-consent record before a publishing flow.
/// Browsing remains available without consent.
Future<bool> ensureUgcLegalAcceptance(BuildContext context) async {
  // Protected routes and the shared service enforce authentication. There is
  // no consent dialog to show until an authenticated user exists.
  if (!SuikaiService.isLoggedIn) return true;
  if (await SuikaiService.hasAcceptedCurrentUgcLegalTerms()) return true;
  if (!context.mounted) return false;

  return (await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _UgcLegalConsentDialog(parent: context),
      )) ??
      false;
}

class _UgcLegalConsentDialog extends StatefulWidget {
  const _UgcLegalConsentDialog({required this.parent});

  final BuildContext parent;

  @override
  State<_UgcLegalConsentDialog> createState() => _UgcLegalConsentDialogState();
}

class _UgcLegalConsentDialogState extends State<_UgcLegalConsentDialog> {
  bool _saving = false;
  String? _error;

  Future<void> _accept() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await SuikaiService.acceptCurrentUgcLegalTerms();
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'We could not save your agreement. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Before you continue'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'To publish content on Suikai, please review and accept our Terms of Service and Community Guidelines.',
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _saving
              ? null
              : () => Navigator.of(widget.parent).push(
                  MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
                ),
          child: const Text('View Terms'),
        ),
        TextButton(
          onPressed: _saving
              ? null
              : () => Navigator.of(widget.parent).push(
                  MaterialPageRoute(
                    builder: (_) => const CommunityGuidelinesPage(),
                  ),
                ),
          child: const Text('View Community Guidelines'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: _saving ? null : _accept,
        child: Text(_saving ? 'Saving...' : 'Agree and Continue'),
      ),
    ],
  );
}

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  bool _deleting = false;

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันการลบบัญชี'),
        content: const Text(
          'การดำเนินการนี้ย้อนกลับไม่ได้ บัญชี ประกาศ ร้านค้า และไฟล์ที่เป็นของคุณจะถูกลบ',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ลบบัญชี'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await SuikaiService.deleteOwnAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ลบบัญชีและออกจากระบบแล้ว')));
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } catch (error, stackTrace) {
      debugPrint('Account deletion failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลบบัญชีไม่สำเร็จ กรุณาลองใหม่หรือติดต่อทีมงาน'),
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ลบบัญชี')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 52),
        const SizedBox(height: 16),
        const Text(
          'สิ่งที่จะถูกลบ',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const _DeletionItem('ข้อมูลบัญชีและโปรไฟล์ของคุณ'),
        const _DeletionItem('ร้านค้า ประกาศ รูปภาพ และวิดีโอที่คุณเป็นเจ้าของ'),
        const _DeletionItem(
          'การกดถูกใจ การแจ้งเตือน และรายการ block ที่ผูกกับบัญชี',
        ),
        const SizedBox(height: 12),
        const Text(
          'รายงานและข้อมูลที่เชื่อมกับเนื้อหาของคุณจะถูกลบตามโครงสร้างข้อมูลปัจจุบัน ข้อมูลการดูแบบไม่ผูกบัญชีอาจคงอยู่เพื่อสถิติและความปลอดภัย',
          style: TextStyle(color: AppTheme.textMuted, height: 1.45),
        ),
        if (LegalConfig.externalAccountDeletionUri case final deletionUri?) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () =>
                launchUrl(deletionUri, mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('ขอลบบัญชีผ่านเว็บไซต์'),
          ),
        ],
        const SizedBox(height: 24),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _deleting ? null : _deleteAccount,
          icon: _deleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.delete_forever_rounded),
          label: Text(_deleting ? 'กำลังลบบัญชี...' : 'ลบบัญชีของฉัน'),
        ),
      ],
    ),
  );
}

class _DeletionItem extends StatelessWidget {
  final String text;
  const _DeletionItem(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.remove_circle_outline, color: Colors.red, size: 19),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _LegalPage extends StatelessWidget {
  final String title;
  final List<_LegalSection> sections;
  const _LegalPage({required this.title, required this.sections});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        for (final section in sections) ...[
          Text(
            section.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final item in section.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('• $item', style: const TextStyle(height: 1.45)),
            ),
          const SizedBox(height: 12),
        ],
        const Divider(),
        const SizedBox(height: 10),
        Text(
          LegalConfig.supportEmail.isEmpty
              ? 'ช่องทางติดต่อฝ่ายสนับสนุนจะระบุในรุ่นเผยแพร่ของ Suikai'
              : 'ติดต่อ: ${LegalConfig.supportEmail}',
          style: const TextStyle(color: AppTheme.textMuted),
        ),
        if (LegalConfig.externalAccountDeletionUri case final deletionUri?) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () =>
                launchUrl(deletionUri, mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('หน้าขอลบบัญชีภายนอก'),
          ),
        ],
      ],
    ),
  );
}

class _LegalSection {
  final String title;
  final List<String> items;
  const _LegalSection(this.title, this.items);
}

import 'package:flutter/material.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/svg_icon.dart';
import '../../data/menu_data.dart';
import '../theme/customer_theme.dart';
import '../widget/customer_widgets.dart';
import 'home_screen.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final gutter = width < 640 ? 20.0 : 28.0;
    final wide = width >= 900;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoCard(
          icon: AppIcons.locationOnOutlined,
          title: 'Visit Us',
          value: MenuData.address,
          onTap: () => copyToClipboard(context, MenuData.address, 'Address'),
        ),
        _InfoCard(
          icon: AppIcons.phoneRounded,
          title: 'Call Us',
          value: MenuData.phone,
          onTap: () => copyToClipboard(context, MenuData.phone, 'Phone number'),
        ),
        _InfoCard(
          icon: AppIcons.alternateEmailRounded,
          title: 'Email',
          value: MenuData.email,
          onTap: () => copyToClipboard(context, MenuData.email, 'Email'),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const IconBadge(AppIcons.accessTimeRounded, background: CColors.cream),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Opening Hours', style: CText.display(18))),
                ],
              ),
              const SizedBox(height: 14),
              const OpeningHours(),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _CateringCard(),
      ],
    );

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          color: CColors.ink,
          padding: EdgeInsets.fromLTRB(gutter, 40, gutter, 40),
          child: const Center(
            child: SectionHeader(
              eyebrow: 'Contact',
              title: 'Get In Touch',
              subtitle: 'Questions, catering or feedback — we\'d love to hear from you.',
              light: true,
              align: CrossAxisAlignment.center,
            ),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1260),
            child: Padding(
              padding: EdgeInsets.fromLTRB(gutter, 28, gutter, 40),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: info),
                        const SizedBox(width: 28),
                        const Expanded(child: _ContactForm()),
                      ],
                    )
                  : Column(children: [info, const SizedBox(height: 14), const _ContactForm()]),
            ),
          ),
        ),
        const CustomerFooter(),
      ],
    );
  }
}

final _cardDecoration = BoxDecoration(
  color: CColors.paper,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: CColors.line),
);

class _InfoCard extends StatelessWidget {
  final AppIcon icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _InfoCard({required this.icon, required this.title, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration,
            child: Row(
              children: [
                IconBadge(icon, size: 46, background: CColors.cream),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title.toUpperCase(), style: CText.eyebrow(color: CColors.muted)),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: CText.body(14.5, color: CColors.ink, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SvgIcon(AppIcons.fileCopyRounded, size: 18, color: CColors.mutedLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CateringCard extends StatelessWidget {
  const _CateringCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(gradient: CColors.goldGradient, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          const SvgIcon(AppIcons.emojiEventsRounded, size: 34, color: CColors.ink),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weddings & Parties', style: CText.display(19)),
                const SizedBox(height: 4),
                Text(
                  'We cater events of every size. Send us a message with your date and guest count.',
                  style: CText.body(13, color: CColors.inkSoft, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactForm extends StatefulWidget {
  const _ContactForm();

  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // TODO: send to Supabase / email once a backend endpoint exists.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks! We\'ll get back to you soon.')));
    _formKey.currentState!.reset();
    for (final c in [_name, _email, _phone, _message]) {
      c.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget label(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 14),
      child: Text(
        t,
        style: CText.body(13.5, color: CColors.ink, weight: FontWeight.w600),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration.copyWith(boxShadow: CShadows.soft),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Send us a message', style: CText.display(22)),
            label('Your name'),
            TextFormField(
              controller: _name,
              validator: _required,
              decoration: const InputDecoration(hintText: 'Full name'),
            ),
            label('Email'),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (_required(v) != null) return 'Required';
                return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!.trim()) ? null : 'Enter a valid email';
              },
              decoration: const InputDecoration(hintText: 'you@example.com'),
            ),
            label('Phone (optional)'),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '07…'),
            ),
            label('Message'),
            TextFormField(
              controller: _message,
              validator: _required,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(hintText: 'How can we help?'),
            ),
            const SizedBox(height: 22),
            PillButton(label: 'Send Message', icon: AppIcons.sendRounded, expand: true, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

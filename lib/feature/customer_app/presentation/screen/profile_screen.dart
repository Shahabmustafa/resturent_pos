import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widget/svg_icon.dart';
import '../../../app_mode/app_mode.dart';
import '../../data/model/dish_model.dart';
import '../provider/customer_providers.dart';
import '../provider/navigation_provider.dart';
import '../theme/customer_theme.dart';
import '../widget/auth_dialog.dart';
import '../widget/customer_avatar.dart';
import '../widget/customer_widgets.dart';

/// Phone app only: confirms, then opens the Rider app (signing out the customer).
Future<void> confirmSwitchToRider(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: CColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Switch to Rider app?', style: CText.display(22)),
      content: Text(
        'You will be logged out of your customer account and the Rider app will open.',
        style: CText.body(14, color: CColors.muted, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Cancel',
            style: CText.body(14, color: CColors.muted, weight: FontWeight.w600),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            'Switch',
            style: CText.body(14, color: CColors.rust, weight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  if (ok == true) await AppModeController.choose(AppMode.rider);
}

/// "My Profile": account details, order stats, edit details, change password.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(customerUserProvider).value;
    final gutter = MediaQuery.sizeOf(context).width < 640 ? 20.0 : 28.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 32),
          children: [
            Text('MY PROFILE', style: CText.eyebrow()),
            const SizedBox(height: 8),
            Text('Your account', style: CText.display(30)),
            const SizedBox(height: 22),
            if (user == null)
              const _SignedOut()
            else ...[
              _ProfileHeader(user: user),
              const SizedBox(height: 14),
              const _Stats(),
              const SizedBox(height: 14),
              _DetailsForm(key: ValueKey(user.id), user: user),
              const SizedBox(height: 14),
              _PasswordForm(key: ValueKey('pw-${user.id}')),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  PillButton(
                    label: 'View My Orders',
                    small: true,
                    icon: AppIcons.arrowForwardRounded,
                    onPressed: () => ref.read(customerTabProvider.notifier).state = CustomerTab.orders,
                  ),
                  PillButton(
                    label: 'Log Out',
                    small: true,
                    style: PillStyle.outlineDark,
                    onPressed: () => _confirmLogout(context, ref),
                  ),
                ],
              ),
            ],
            // Phone app only: open the Rider app.
            if (!kIsWeb) ...[
              const SizedBox(height: 28),
              Center(
                child: TextButton.icon(
                  onPressed: () => confirmSwitchToRider(context),
                  icon: const SvgIcon(AppIcons.deliveryDiningRounded, size: 18, color: CColors.muted),
                  label: Text(
                    'Delivery rider? Switch to the Rider app',
                    style: CText.body(13.5, color: CColors.muted, weight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log out?', style: CText.display(22)),
        content: Text(
          'You can log back in any time to order and track your orders.',
          style: CText.body(14, color: CColors.muted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: CText.body(14, color: CColors.muted, weight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Log Out',
              style: CText.body(14, color: CColors.rust, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await CustomerAuth.signOut();
    ref.read(customerTabProvider.notifier).state = CustomerTab.home;
  }
}

BoxDecoration get _card => BoxDecoration(
  color: CColors.paper,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: CColors.line),
);

class _ProfileHeader extends StatelessWidget {
  final User user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user.displayName;
    final since = DateTime.tryParse(user.createdAt)?.toLocal();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CColors.ink, CColors.inkElev],
        ),
        boxShadow: CShadows.soft,
      ),
      child: Row(
        children: [
          _AvatarEditor(user: user),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CText.display(22, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CText.body(13.5, color: CColors.goldPale),
                ),
                if (since != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Member since ${DateFormat('MMMM yyyy').format(since)}',
                    style: CText.body(12, color: CColors.mutedLight),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile photo with a camera button to upload a new one or remove it.
class _AvatarEditor extends StatefulWidget {
  final User user;

  const _AvatarEditor({required this.user});

  @override
  State<_AvatarEditor> createState() => _AvatarEditorState();
}

class _AvatarEditorState extends State<_AvatarEditor> {
  static const _maxBytes = 2 * 1024 * 1024;
  bool _busy = false;

  void _toast(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _upload() async {
    const images = XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png', 'webp']);
    final file = await openFile(acceptedTypeGroups: [images]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > _maxBytes) {
      _toast('Photo is too large — please use one under 2 MB.');
      return;
    }
    final lower = file.name.toLowerCase();
    final mime = lower.endsWith('.png')
        ? 'image/png'
        : lower.endsWith('.webp')
        ? 'image/webp'
        : 'image/jpeg';
    setState(() => _busy = true);
    try {
      await CustomerAuth.uploadAvatar(bytes, mime);
      _toast('Profile photo updated.');
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    try {
      await CustomerAuth.removeAvatar();
      _toast('Profile photo removed.');
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.user.avatarUrl.isNotEmpty;
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomerAvatar(user: widget.user, size: 76),
          if (_busy)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: .45), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                ),
              ),
            ),
          Positioned(
            right: -4,
            bottom: -4,
            child: PopupMenuButton<String>(
              enabled: !_busy,
              tooltip: 'Change photo',
              color: CColors.paper,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (v) => v == 'upload' ? _upload() : _remove(),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'upload',
                  child: Text(hasPhoto ? 'Change photo' : 'Upload photo', style: CText.body(14)),
                ),
                if (hasPhoto)
                  PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove photo', style: CText.body(14, color: CColors.rust)),
                  ),
              ],
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: CColors.rust,
                  shape: BoxShape.circle,
                  border: Border.all(color: CColors.ink, width: 2),
                ),
                child: const SvgIcon(AppIcons.editRounded, size: 15, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Orders placed, amount spent (cancelled orders excluded) and reviews given.
class _Stats extends ConsumerWidget {
  const _Stats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider).value ?? const [];
    final counted = orders.where((o) => o.status != 'cancelled');
    final spent = counted.fold<double>(0, (sum, o) => sum + o.total);
    final reviews = orders.where((o) => o.myRating != null).length;

    Widget tile(AppIcon icon, String value, String label) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: _card,
        child: Column(
          children: [
            SvgIcon(icon, size: 22, color: CColors.gold),
            const SizedBox(height: 8),
            FittedBox(child: Text(value, style: CText.display(22))),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: CText.body(12, color: CColors.muted),
            ),
          ],
        ),
      ),
    );

    return Row(
      children: [
        tile(AppIcons.receiptLongRounded, '${orders.length}', 'Orders'),
        const SizedBox(width: 10),
        tile(AppIcons.accountBalanceWalletRounded, formatPrice(spent), 'Total spent'),
        const SizedBox(width: 10),
        tile(AppIcons.starRounded, '$reviews', 'Reviews'),
      ],
    );
  }
}

class _DetailsForm extends StatefulWidget {
  final User user;

  const _DetailsForm({super.key, required this.user});

  @override
  State<_DetailsForm> createState() => _DetailsFormState();
}

class _DetailsFormState extends State<_DetailsForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.displayName);
  late final _phone = TextEditingController(text: widget.user.contactPhone);
  late final _address = TextEditingController(text: widget.user.savedAddress);
  bool _busy = false;
  String? _error;
  bool _saved = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _saved = false;
    });
    try {
      await CustomerAuth.updateProfile(name: _name.text, phone: _phone.text, address: _address.text);
      if (mounted) setState(() => _saved = true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _card,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Personal details', style: CText.display(19)),
            const SizedBox(height: 4),
            Text('Used to fill in checkout for you.', style: CText.body(13, color: CColors.muted)),
            const _Label('Full name'),
            TextFormField(
              controller: _name,
              enabled: !_busy,
              validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const _Label('Phone'),
            TextFormField(
              controller: _phone,
              enabled: !_busy,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '03xx xxxxxxx'),
              validator: (v) =>
                  (v ?? '').replaceAll(RegExp(r'\D'), '').length < 10 ? 'Enter a valid phone number' : null,
            ),
            const _Label('Default delivery address'),
            TextFormField(
              controller: _address,
              enabled: !_busy,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'House, street, area'),
            ),
            if (_error != null) _Notice(_error!, error: true),
            if (_saved) const _Notice('Your details have been saved.'),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: PillButton(
                label: _busy ? 'Saving…' : 'Save Changes',
                small: true,
                onPressed: _busy ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordForm extends StatefulWidget {
  const _PasswordForm({super.key});

  @override
  State<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<_PasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _show = false;
  String? _error;
  bool _saved = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _saved = false;
    });
    try {
      await CustomerAuth.changePassword(_password.text);
      _password.clear();
      _confirm.clear();
      if (mounted) setState(() => _saved = true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eye = IconButton(
      tooltip: _show ? 'Hide password' : 'Show password',
      onPressed: () => setState(() => _show = !_show),
      icon: SvgIcon(_show ? AppIcons.visibilityOffRounded : AppIcons.visibilityRounded, size: 20, color: CColors.muted),
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _card,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Change password', style: CText.display(19)),
            const _Label('New password'),
            TextFormField(
              controller: _password,
              enabled: !_busy,
              obscureText: !_show,
              decoration: InputDecoration(hintText: 'At least 6 characters', suffixIcon: eye),
              validator: (v) => (v ?? '').length < 6 ? 'Use at least 6 characters' : null,
            ),
            const _Label('Confirm new password'),
            TextFormField(
              controller: _confirm,
              enabled: !_busy,
              obscureText: !_show,
              validator: (v) => v != _password.text ? 'Passwords do not match' : null,
            ),
            if (_error != null) _Notice(_error!, error: true),
            if (_saved) const _Notice('Your password has been changed.'),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: PillButton(
                label: _busy ? 'Updating…' : 'Update Password',
                small: true,
                style: PillStyle.outlineDark,
                onPressed: _busy ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
    decoration: _card,
    child: Column(
      children: [
        const IconBadge(AppIcons.personRounded, size: 64, background: CColors.cream, color: CColors.gold),
        const SizedBox(height: 16),
        Text('Log in to see your profile', textAlign: TextAlign.center, style: CText.display(22)),
        const SizedBox(height: 6),
        Text(
          'Manage your details, saved address and password.',
          textAlign: TextAlign.center,
          style: CText.body(14, color: CColors.muted, height: 1.5),
        ),
        const SizedBox(height: 18),
        PillButton(label: 'Login', small: true, onPressed: () => showCustomerAuthDialog(context)),
      ],
    ),
  );
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 14),
    child: Text(
      text,
      style: CText.body(13.5, color: CColors.ink, weight: FontWeight.w600),
    ),
  );
}

class _Notice extends StatelessWidget {
  final String text;
  final bool error;

  const _Notice(this.text, {this.error = false});

  @override
  Widget build(BuildContext context) {
    final color = error ? CColors.rust : CColors.olive;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          SvgIcon(error ? AppIcons.warningRounded : AppIcons.checkCircleRounded, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: CText.body(13, color: color, height: 1.45)),
          ),
        ],
      ),
    );
  }
}

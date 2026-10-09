import 'package:resturent_application/core/widget/app_tab_bar.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../../../../../core/constants/app_colors.dart';
import '../../data/model/branches_model.dart';

// ─── All user roles supported ─────────────────────────────────────────────────
const List<Map<String, dynamic>> kBranchRoles = [
  {'value': 'admin',   'label': 'Admin',   'icon': AppIcons.adminPanelSettingsOutlined},
  {'value': 'manager', 'label': 'Manager', 'icon': AppIcons.manageAccountsOutlined},
  {'value': 'cashier', 'label': 'Cashier', 'icon': AppIcons.pointOfSaleOutlined},
  {'value': 'chef',    'label': 'Chef',    'icon': AppIcons.restaurantOutlined},
  {'value': 'rider',   'label': 'Rider',   'icon': AppIcons.deliveryDiningOutlined},
  {'value': 'waiter',  'label': 'Waiter',  'icon': AppIcons.roomServiceOutlined},
];

// ─── Form Result ──────────────────────────────────────────────────────────────
class BranchFormResult {
  final Branch branch;
  final String adminName;
  final String adminUsername;
  final String adminEmail;
  final String adminPhone;
  final String adminRole;
  final String? newPassword;

  BranchFormResult({
    required this.branch,
    required this.adminName,
    required this.adminUsername,
    required this.adminEmail,
    required this.adminPhone,
    required this.adminRole,
    this.newPassword,
  });
}

// ─── Dialog ───────────────────────────────────────────────────────────────────
class BranchFormDialog extends StatefulWidget {
  final Branch? editing;
  final List<Color> usedColors;
  final String companyId;
  final ValueChanged<BranchFormResult> onSave;

  const BranchFormDialog({
    super.key,
    this.editing,
    required this.usedColors,
    required this.companyId,
    required this.onSave,
  });

  @override
  State<BranchFormDialog> createState() => _BranchFormDialogState();
}

class _BranchFormDialogState extends State<BranchFormDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Color _color;
  bool _obscurePass = true;

  // Branch
  late final TextEditingController _name, _city, _address, _phone, _ntn, _tables;
  // Admin user
  late final TextEditingController _aName, _aUsername, _aEmail, _aPhone, _aPassword;
  String _aRole = 'admin';

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final b = widget.editing;
    final admin = b?.adminUser;

    _color = b?.color ??
        AppColors.branchColors.firstWhere(
              (c) => !widget.usedColors.contains(c),
          orElse: () => AppColors.branchColors.first,
        );

    _name    = TextEditingController(text: b?.name ?? '');
    _city    = TextEditingController(text: b?.city ?? '');
    _address = TextEditingController(text: b?.address ?? '');
    _phone   = TextEditingController(text: b?.phone ?? '');
    _ntn     = TextEditingController(text: b?.ntn ?? '');
    _tables  = TextEditingController(text: b != null ? '${b.tables}' : '');

    _aName     = TextEditingController(text: admin?.name ?? '');
    _aUsername = TextEditingController(text: admin?.username ?? '');
    _aEmail    = TextEditingController(text: admin?.email ?? '');
    _aPhone    = TextEditingController(text: admin?.phone ?? '');
    _aPassword = TextEditingController();
    _aRole     = admin?.role ?? 'admin';
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [
      _name, _city, _address, _phone, _ntn, _tables,
      _aName, _aUsername, _aEmail, _aPhone, _aPassword,
    ]) c.dispose();
    super.dispose();
  }

  bool get _valid {
    final branchOk = _name.text.trim().isNotEmpty &&
        _city.text.trim().isNotEmpty &&
        _address.text.trim().isNotEmpty;
    final email = _aEmail.text.trim();
    final pass = _aPassword.text.trim();
    final adminOk = _aName.text.trim().isNotEmpty &&
        _aUsername.text.trim().isNotEmpty &&
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    // Supabase Auth: password must be at least 6 characters
    final passOk = _isEditing ? (pass.isEmpty || pass.length >= 6) : pass.length >= 6;
    return branchOk && adminOk && passOk;
  }

  void _save() {
    if (!_valid) return;
    final branch = Branch(
      id: widget.editing?.id ?? '',
      companyId: widget.companyId,
      name: _name.text.trim(),
      city: _city.text.trim(),
      address: _address.text.trim(),
      phone: _phone.text.trim(),
      ntn: _ntn.text.trim(),
      tables: int.tryParse(_tables.text) ?? 0,
      color: _color,
      isOpen: widget.editing?.isOpen ?? true,
      isActive: widget.editing?.isActive ?? true,
      monthSales: widget.editing?.monthSales ?? 0,
      target: widget.editing?.target ?? 1000000,
      adminUser: widget.editing?.adminUser,
    );

    widget.onSave(BranchFormResult(
      branch: branch,
      adminName: _aName.text.trim(),
      adminUsername: _aUsername.text.trim(),
      adminEmail: _aEmail.text.trim().toLowerCase(),
      adminPhone: _aPhone.text.trim(),
      adminRole: _aRole,
      newPassword: _aPassword.text.trim().isEmpty ? null : _aPassword.text.trim(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: SizedBox(
      width: 560,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _DialogHeader(
            title: _isEditing ? 'Edit Branch' : 'Add New Branch',
            onClose: () => Navigator.pop(context),
          ),

          // Tabs
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: AppTabBar(
              controller: _tabController,
              items: const [
                AppTabItem('Branch Info', icon: AppIcons.storefrontRounded),
                AppTabItem('Admin Access', icon: AppIcons.shieldRounded),
              ],
            ),
          ),

          // Body
          Flexible(
            child: SizedBox(
              height: 420,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _BranchInfoTab(
                    nameCtrl: _name,
                    cityCtrl: _city,
                    addressCtrl: _address,
                    phoneCtrl: _phone,
                    ntnCtrl: _ntn,
                    tablesCtrl: _tables,
                    color: _color,
                    usedColors: widget.usedColors,
                    onColorChanged: (c) => setState(() => _color = c),
                  ),
                  _AdminAccessTab(
                    isEditing: _isEditing,
                    nameCtrl: _aName,
                    usernameCtrl: _aUsername,
                    emailCtrl: _aEmail,
                    phoneCtrl: _aPhone,
                    passwordCtrl: _aPassword,
                    role: _aRole,
                    obscurePass: _obscurePass,
                    onRoleChanged: (v) => setState(() => _aRole = v),
                    onToggleObscure: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ],
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border, width: 0.5))),
            child: Row(
              children: [
                // Dot indicators
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (_, __) => Row(
                    children: List.generate(2, (i) {
                      final active = _tabController.index == i;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: active ? 16 : 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.greyLt,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    foregroundColor: AppColors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                ListenableBuilder(
                  listenable: Listenable.merge(
                      [_name, _city, _address, _aName, _aUsername, _aEmail, _aPassword]),
                  builder: (_, __) => ElevatedButton(
                    onPressed: _valid ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                      disabledBackgroundColor: AppColors.greyLt,
                    ),
                    child: Text(
                      _isEditing ? 'Save Changes' : 'Add Branch',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
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

// ─── Tab 1: Branch Info ───────────────────────────────────────────────────────
class _BranchInfoTab extends StatelessWidget {
  final TextEditingController nameCtrl, cityCtrl, addressCtrl, phoneCtrl,
      ntnCtrl, tablesCtrl;
  final Color color;
  final List<Color> usedColors;
  final ValueChanged<Color> onColorChanged;

  const _BranchInfoTab({
    required this.nameCtrl,
    required this.cityCtrl,
    required this.addressCtrl,
    required this.phoneCtrl,
    required this.ntnCtrl,
    required this.tablesCtrl,
    required this.color,
    required this.usedColors,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('BRANCH COLOR'),
        const SizedBox(height: 8),
        Row(
          children: AppColors.branchColors.map((c) {
            final selected = color == c;
            return GestureDetector(
              onTap: () => onColorChanged(c),
              child: Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.dark : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: selected
                    ? const SvgIcon(AppIcons.check, size: 13, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        const _SectionLabel('BRANCH DETAILS'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _Field(
                  label: 'Branch Name *',
                  controller: nameCtrl,
                  hint: 'e.g. DHA Branch')),
          const SizedBox(width: 12),
          Expanded(
              child: _Field(
                  label: 'City *', controller: cityCtrl, hint: 'e.g. Lahore')),
        ]),
        const SizedBox(height: 10),
        _Field(
            label: 'Address *',
            controller: addressCtrl,
            hint: 'Full address'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _Field(
                  label: 'Phone',
                  controller: phoneCtrl,
                  hint: '042-XXXXXXX')),
          const SizedBox(width: 12),
          Expanded(
              child: _Field(
                  label: 'NTN', controller: ntnCtrl, hint: 'XXXXXXX-X')),
        ]),
        const SizedBox(height: 10),
        _Field(
          label: 'Total Tables',
          controller: tablesCtrl,
          hint: '10',
          keyboardType: TextInputType.number,
          prefixIcon: AppIcons.tableRestaurantOutlined,
        ),
      ],
    ),
  );
}

// ─── Tab 2: Admin Access ──────────────────────────────────────────────────────
class _AdminAccessTab extends StatelessWidget {
  final bool isEditing;
  final TextEditingController nameCtrl, usernameCtrl, emailCtrl, phoneCtrl, passwordCtrl;
  final String role;
  final bool obscurePass;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onToggleObscure;

  const _AdminAccessTab({
    required this.isEditing,
    required this.nameCtrl,
    required this.usernameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.passwordCtrl,
    required this.role,
    required this.obscurePass,
    required this.onRoleChanged,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('ADMIN USER CREDENTIALS'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(children: [
            const SvgIcon(AppIcons.adminPanelSettingsOutlined,
                color: AppColors.primary, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isEditing
                    ? 'The admin user will be updated. Leave the password empty to keep it unchanged.'
                    : 'The admin logs in to the POS with this email and password.',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.primary, height: 1.4),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: _Field(
              label: 'Admin Name *',
              controller: nameCtrl,
              hint: 'Full name',
              prefixIcon: AppIcons.personOutlineRounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Field(
              label: 'Phone',
              controller: phoneCtrl,
              hint: '0300-0000000',
              keyboardType: TextInputType.phone,
              prefixIcon: AppIcons.phoneOutlined,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        _Field(
          label: 'Username *',
          controller: usernameCtrl,
          hint: 'branch_admin',
          prefixIcon: AppIcons.personOutlineRounded,
        ),
        const SizedBox(height: 10),
        _Field(
          label: 'Email (login) *',
          controller: emailCtrl,
          hint: 'admin@example.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: AppIcons.alternateEmailRounded,
        ),
        const SizedBox(height: 10),

        // Role selector — all 6 roles as chips
        const _SectionLabel('ROLE'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kBranchRoles.map((r) {
            final isSelected = role == r['value'];
            return GestureDetector(
              onTap: () => onRoleChanged(r['value'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  SvgIcon(r['icon'] as AppIcon,
                      size: 13,
                      color: isSelected
                          ? Colors.white
                          : AppColors.grey),
                  const SizedBox(width: 5),
                  Text(r['label'] as String,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppColors.grey)),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        _Field(
          label: isEditing
              ? 'New Password (optional)'
              : 'Password *',
          controller: passwordCtrl,
          hint: isEditing
              ? 'Leave empty to keep current'
              : 'Min 6 characters',
          isPassword: true,
          obscure: obscurePass,
          prefixIcon: AppIcons.lockOutlineRounded,
          onToggleObscure: onToggleObscure,
        ),
      ],
    ),
  );
}

// ─── Shared Helpers ───────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  const _DialogHeader({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
    child: Row(children: [
      Text(title,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark)),
      const Spacer(),
      GestureDetector(
        onTap: onClose,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
              color: AppColors.bg, borderRadius: BorderRadius.circular(6)),
          child: const SvgIcon(AppIcons.close, size: 14, color: AppColors.grey),
        ),
      ),
    ]),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: AppColors.grey,
          letterSpacing: 0.8));
}

class _Field extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool isPassword, obscure;
  final AppIcon? prefixIcon;
  final VoidCallback? onToggleObscure;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.isPassword = false,
    this.obscure = false,
    this.prefixIcon,
    this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey)),
      const SizedBox(height: 5),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword ? obscure : false,
        style: const TextStyle(fontSize: 12, color: AppColors.dark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: AppColors.greyLt),
          prefixIcon: prefixIcon != null
              ? SvgIcon(prefixIcon, size: 15, color: AppColors.grey)
              : null,
          suffixIcon: isPassword
              ? IconButton(
            icon: SvgIcon(
                obscure
                    ? AppIcons.visibilityOffOutlined
                    : AppIcons.visibilityOutlined,
                size: 15,
                color: AppColors.grey),
            onPressed: onToggleObscure,
          )
              : null,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary)),
          filled: true,
          fillColor: AppColors.white,
          isDense: true,
        ),
      ),
    ],
  );
}
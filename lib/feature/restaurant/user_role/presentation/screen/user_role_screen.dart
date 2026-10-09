import 'package:resturent_application/core/widget/status_pill.dart';
import 'package:resturent_application/core/widget/stat_card.dart';
import 'package:resturent_application/core/widget/page_skeleton.dart';
import 'package:resturent_application/core/constants/app_icons.dart';
import 'package:resturent_application/core/widget/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../data/model/user_model.dart';
import '../provider/user_role_provider.dart';

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  final _searchCtrl   = TextEditingController();
  BranchUserRole? _roleFilter;
  String          _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<BranchUserModel> _filtered(List<BranchUserModel> users) {
    final q = _searchCtrl.text.toLowerCase();
    return users.where((u) {
      final mQ = q.isEmpty ||
          u.name.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          (u.phone?.contains(q) ?? false);
      final mR = _roleFilter == null || u.role == _roleFilter;
      final mS = _statusFilter == 'all' ||
          (_statusFilter == 'active'   && u.status == BranchUserStatus.active) ||
          (_statusFilter == 'inactive' && u.status == BranchUserStatus.inactive);
      return mQ && mR && mS;
    }).toList();
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────

  void _showFormDialog(BranchUserModel? existing) {
    final nameCtrl  = TextEditingController(text: existing?.name     ?? '');
    final userCtrl  = TextEditingController(text: existing?.username ?? '');
    final emailCtrl = TextEditingController(text: existing?.email    ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone    ?? '');
    final passCtrl  = TextEditingController();
    var   role      = existing?.role   ?? BranchUserRole.cashier;
    var   status    = existing?.status ?? BranchUserStatus.active;
    final formKey   = GlobalKey<FormState>();
    bool  showPass  = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgIcon(existing == null ? AppIcons.personAddRounded : AppIcons.editRounded,
                    color: kPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(existing == null ? 'Add New User' : 'Edit User',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Username row
                    Row(
                      children: [
                        Expanded(child: _FormField(label: 'Full Name', ctrl: nameCtrl, hint: 'Ahmed Khan',
                            validator: (v) => v!.isEmpty ? 'Required' : null)),
                        const SizedBox(width: 12),
                        Expanded(child: _FormField(label: 'Username', ctrl: userCtrl, hint: 'ahmed_khan',
                            validator: (v) => v!.isEmpty ? 'Required' : null)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Email (used for login)
                    _FormField(label: 'Email', ctrl: emailCtrl, hint: 'ahmed@example.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final email = v!.trim();
                          if (email.isEmpty) return 'Required';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return 'Invalid email';
                          return null;
                        }),
                    const SizedBox(height: 14),

                    // Phone + Password row
                    Row(
                      children: [
                        Expanded(child: _FormField(label: 'Phone', ctrl: phoneCtrl, hint: '03XX-XXXXXXX')),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel(existing == null ? 'Password' : 'New Password (optional)'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: passCtrl,
                                obscureText: !showPass,
                                validator: (v) {
                                  final pass = v!.trim();
                                  if (pass.isEmpty) return existing == null ? 'Required' : null;
                                  if (pass.length < 6) return 'At least 6 characters';
                                  return null;
                                },
                                style: const TextStyle(fontSize: 13, color: kText),
                                decoration: _inputDecoration('••••••••').copyWith(
                                  suffixIcon: IconButton(
                                    icon: SvgIcon(
                                      showPass ? AppIcons.visibilityOffRounded : AppIcons.visibilityRounded,
                                      size: 17, color: kMuted,
                                    ),
                                    onPressed: () => setS(() => showPass = !showPass),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Role selector
                    const _FieldLabel('Role'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: BranchUserRole.values.map((r) {
                        final isSelected = role == r;
                        return GestureDetector(
                          onTap: () => setS(() => role = r),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? r.bgColor : const Color(0xFFF8F9FC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? r.color.withOpacity(0.4) : kBorder,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgIcon(r.icon, size: 14, color: isSelected ? r.color : kMuted),
                                const SizedBox(width: 6),
                                Text(r.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                      color: isSelected ? r.color : kMuted,
                                    )),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Pages access preview
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: role.bgColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: role.color.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SvgIcon(AppIcons.lockOpenRounded, size: 13, color: role.color),
                              const SizedBox(width: 5),
                              Text('Pages Access (${role.allowedPages.length})',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: role.color)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: role.allowedPages.map((p) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: role.color.withOpacity(0.2)),
                              ),
                              child: Text(p,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: role.color,
                                      fontWeight: FontWeight.w500)),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Status toggle
                    Row(
                      children: [
                        const _FieldLabel('Status'),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setS(() => status = status == BranchUserStatus.active
                              ? BranchUserStatus.inactive
                              : BranchUserStatus.active),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: status == BranchUserStatus.active
                                  ? const Color(0xFFF0FDF4)
                                  : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: status == BranchUserStatus.active
                                    ? kGreen.withOpacity(0.3)
                                    : Colors.redAccent.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    color: status == BranchUserStatus.active
                                        ? kGreen
                                        : Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  status == BranchUserStatus.active ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: status == BranchUserStatus.active
                                        ? kGreen
                                        : Colors.redAccent,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                SvgIcon(AppIcons.swapHorizRounded,
                                    size: 14,
                                    color: status == BranchUserStatus.active
                                        ? kGreen
                                        : Colors.redAccent),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: kMuted)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final user = BranchUserModel(
                  id:        existing?.id ?? '',
                  branchId:  existing?.branchId ?? '',
                  name:      nameCtrl.text.trim(),
                  username:  userCtrl.text.trim(),
                  email:     emailCtrl.text.trim().toLowerCase(),
                  phone:     phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  password:  passCtrl.text.trim(),
                  role:      role,
                  status:    status,
                  avatarUrl: existing?.avatarUrl,
                  createdAt: existing?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                if (existing == null) {
                  ref.read(branchUserProvider.notifier).addUser(user);
                } else {
                  ref.read(branchUserProvider.notifier).updateUser(user);
                }
                Navigator.pop(ctx);
              },
              icon: const SvgIcon(AppIcons.checkRounded, size: 16),
              label: Text(existing == null ? 'Add User' : 'Save Changes',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BranchUserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete User',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
        content: Text('Permanently delete "${user.name}"?',
            style: const TextStyle(fontSize: 13, color: kSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: kMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              ref.read(branchUserProvider.notifier).deleteUser(user.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(branchUserProvider);
    final filtered = _filtered(state.users);

    ref.listen<BranchUserState>(branchUserProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.errorMessage!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Bar ────────────────────────────────────────────────
            _TopBar(onAdd: () => _showFormDialog(null)),
            const SizedBox(height: 20),

            // ── Stats ──────────────────────────────────────────────────
            _StatsRow(users: state.users),
            const SizedBox(height: 20),

            // ── Data Table Card ────────────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? const PageSkeleton(statCount: 0, rows: 7, columns: 5, padding: EdgeInsets.zero)
                  : _UserTableCard(
                users:          filtered,
                allUsers:       state.users,
                searchCtrl:     _searchCtrl,
                roleFilter:     _roleFilter,
                statusFilter:   _statusFilter,
                onRoleChanged:  (r) => setState(() => _roleFilter = r),
                onStatusChanged:(s) => setState(() => _statusFilter = s),
                onEdit:         _showFormDialog,
                onDelete:       _confirmDelete,
                onToggleStatus: (user) {
                  final newStatus = user.status == BranchUserStatus.active
                      ? BranchUserStatus.inactive
                      : BranchUserStatus.active;
                  ref.read(branchUserProvider.notifier)
                      .toggleStatus(user.id, newStatus);
                },
                onRefresh: () =>
                    ref.read(branchUserProvider.notifier).fetchUsers(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onAdd;
  const _TopBar({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const SvgIcon(AppIcons.peopleRounded, color: kPrimary, size: 22),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User Management',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kText)),
            Text('Manage branch staff and roles',
                style: TextStyle(fontSize: 11, color: kMuted)),
          ],
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const SvgIcon(AppIcons.personAddRounded, size: 17),
          label: const Text('Add User', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final List<BranchUserModel> users;
  const _StatsRow({required this.users});

  @override
  Widget build(BuildContext context) {
    final total    = users.length;
    final active   = users.where((u) => u.status == BranchUserStatus.active).length;
    final inactive = users.where((u) => u.status == BranchUserStatus.inactive).length;
    final roles    = BranchUserRole.values.length;

    return StatCardRow(cards: [
      StatCardData(AppIcons.peopleRounded,      'Total Users', '$total',    const Color(0xFF6366F1)),
      StatCardData(AppIcons.checkCircleRounded, 'Active',      '$active',   kGreen),
      StatCardData(AppIcons.blockRounded,       'Inactive',    '$inactive', Colors.redAccent),
      StatCardData(AppIcons.shieldRounded,      'Total Roles', '$roles',    kPrimary),
    ]);
  }
}

// ── User Table Card ───────────────────────────────────────────────────────────

class _UserTableCard extends StatelessWidget {
  final List<BranchUserModel> users, allUsers;
  final TextEditingController searchCtrl;
  final BranchUserRole? roleFilter;
  final String statusFilter;
  final ValueChanged<BranchUserRole?> onRoleChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<BranchUserModel> onEdit, onDelete, onToggleStatus;
  final Future<void> Function() onRefresh;

  const _UserTableCard({
    required this.users,
    required this.allUsers,
    required this.searchCtrl,
    required this.roleFilter,
    required this.statusFilter,
    required this.onRoleChanged,
    required this.onStatusChanged,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: const [BoxShadow(color: Color(0x0A000020), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Toolbar
          _Toolbar(
            searchCtrl:     searchCtrl,
            roleFilter:     roleFilter,
            statusFilter:   statusFilter,
            resultCount:    users.length,
            totalCount:     allUsers.length,
            onRoleChanged:  onRoleChanged,
            onStatusChanged:onStatusChanged,
          ),
          // Header
          const _TableHeader(),
          // Rows
          Expanded(
            child: users.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
              color: kPrimary,
              onRefresh: onRefresh,
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (_, i) => _UserRow(
                  user:          users[i],
                  index:         i,
                  isLast:        i == users.length - 1,
                  onEdit:        onEdit,
                  onDelete:      onDelete,
                  onToggleStatus:onToggleStatus,
                ),
              ),
            ),
          ),
          // Footer
          _Footer(showing: users.length, total: allUsers.length),
        ],
      ),
    );
  }
}

// ── Toolbar ───────────────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final BranchUserRole? roleFilter;
  final String statusFilter;
  final int resultCount, totalCount;
  final ValueChanged<BranchUserRole?> onRoleChanged;
  final ValueChanged<String> onStatusChanged;

  const _Toolbar({
    required this.searchCtrl,
    required this.roleFilter,
    required this.statusFilter,
    required this.resultCount,
    required this.totalCount,
    required this.onRoleChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          // Search
          SizedBox(
            width: 240,
            height: 36,
            child: TextField(
              controller: searchCtrl,
              style: const TextStyle(fontSize: 13, color: kText),
              decoration: InputDecoration(
                hintText: 'Name, username, phone...',
                hintStyle: const TextStyle(color: kMuted, fontSize: 13),
                prefixIcon: const SvgIcon(AppIcons.searchRounded, color: kMuted, size: 18),
                filled: true,
                fillColor: kLight,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimary, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Role filter
          _DropFilter<BranchUserRole?>(
            value: roleFilter,
            hint: 'All Roles',
            items: {
              null: 'All Roles',
              ...{for (var r in BranchUserRole.values) r: r.label},
            },
            onChanged: onRoleChanged,
          ),
          const SizedBox(width: 10),

          // Status filter
          _DropFilter<String>(
            value: statusFilter,
            hint: 'All Status',
            items: const {'all': 'All Status', 'active': 'Active', 'inactive': 'Inactive'},
            onChanged: (v) => onStatusChanged(v!),
          ),

          const Spacer(),
          Text('$resultCount / $totalCount users',
              style: const TextStyle(fontSize: 12, color: kMuted)),
        ],
      ),
    );
  }
}

class _DropFilter<T> extends StatelessWidget {
  final T value;
  final String hint;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;
  const _DropFilter({required this.value, required this.hint, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: kLight,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          style: const TextStyle(fontSize: 13, color: kText),
          icon: const SvgIcon(AppIcons.expandMoreRounded, size: 16, color: kMuted),
          hint: Text(hint, style: const TextStyle(fontSize: 13, color: kMuted)),
          onChanged: onChanged,
          items: items.entries
              .map((e) => DropdownMenuItem<T>(value: e.key, child: Text(e.value)))
              .toList(),
        ),
      ),
    );
  }
}

// ── Table Header ──────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FC),
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: const Row(
        children: [
          _HCell('#',            flex: 1),
          _HCell('Employee',     flex: 4),
          _HCell('Username',     flex: 2),
          _HCell('Role',         flex: 2),
          _HCell('Pages Access', flex: 4),
          _HCell('Status',       flex: 2),
          _HCell('Actions',      flex: 2),
        ],
      ),
    );
  }
}

class _HCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: kMuted, letterSpacing: 0.4)),
    );
  }
}

// ── User Row ──────────────────────────────────────────────────────────────────

class _UserRow extends StatelessWidget {
  final BranchUserModel user;
  final int index;
  final bool isLast;
  final ValueChanged<BranchUserModel> onEdit, onDelete, onToggleStatus;

  const _UserRow({
    required this.user,
    required this.index,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  static const _avColors = [
    [Color(0xFFEEF2FF), Color(0xFF4338CA)],
    [Color(0xFFF0FDF4), Color(0xFF15803D)],
    [Color(0xFFFFFBEB), Color(0xFFB45309)],
    [Color(0xFFFEF2F2), Color(0xFFB91C1C)],
    [Color(0xFFEFF6FF), Color(0xFF1D4ED8)],
    [Color(0xFFFDF4FF), Color(0xFF7E22CE)],
  ];

  @override
  Widget build(BuildContext context) {
    final avBg  = _avColors[index % _avColors.length][0];
    final avFg  = _avColors[index % _avColors.length][1];
    final isActive = user.status == BranchUserStatus.active;
    final pages    = user.role.allowedPages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : const Color(0xFFFAFAFB),
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF0F2F8))),
      ),
      child: Row(
        children: [
          // Index
          Expanded(
            flex: 1,
            child: Text('${index + 1}',
                style: const TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w500)),
          ),

          // Avatar + name + phone
          Expanded(
            flex: 4,
            child: Row(
              children: [
                user.avatarUrl != null
                    ? CircleAvatar(radius: 18, backgroundImage: NetworkImage(user.avatarUrl!))
                    : CircleAvatar(
                  radius: 18,
                  backgroundColor: avBg,
                  child: Text(user.initials,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: avFg)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText),
                          overflow: TextOverflow.ellipsis),
                      if (user.phone != null)
                        Row(
                          children: [
                            const SvgIcon(AppIcons.phoneRounded, size: 10, color: kMuted),
                            const SizedBox(width: 3),
                            Text(user.phone!,
                                style: const TextStyle(fontSize: 11, color: kMuted)),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Username
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const SvgIcon(AppIcons.alternateEmailRounded, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(user.username,
                      style: const TextStyle(fontSize: 12, color: kSub, fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),

          // Role badge
          Expanded(
            flex: 2,
            child: StatusPill(label: user.role.label, color: user.role.color, icon: user.role.icon),
          ),

          // Pages access chips
          Expanded(
            flex: 4,
            child: Wrap(
              spacing: 4,
              runSpacing: 3,
              children: [
                ...pages.take(3).map((p) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(p,
                      style: const TextStyle(fontSize: 10, color: kSub, fontWeight: FontWeight.w500)),
                )),
                if (pages.length > 3)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: user.role.bgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('+${pages.length - 3}',
                        style: TextStyle(fontSize: 10, color: user.role.color, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),

          // Status toggle
          Expanded(
            flex: 2,
            child: StatusPill(
              label:    isActive ? 'Active' : 'Inactive',
              color:    isActive ? kGreen : Colors.redAccent,
              dot:      true,
              trailing: AppIcons.swapHorizRounded,
              tooltip:  isActive ? 'Deactivate' : 'Activate',
              onTap:    () => onToggleStatus(user),
            ),
          ),

          // Actions
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _ActionBtn(AppIcons.editRounded,          kBlue,         'Edit',   () => onEdit(user)),
                const SizedBox(width: 6),
                _ActionBtn(AppIcons.deleteOutlineRounded, Colors.redAccent, 'Delete', () => onDelete(user)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final AppIcon icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActionBtn(this.icon, this.color, this.tooltip, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: SvgIcon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}

// ── Empty + Footer ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.08), shape: BoxShape.circle,
            ),
            child: const SvgIcon(AppIcons.peopleOutlineRounded, size: 40, color: kPrimary),
          ),
          const SizedBox(height: 14),
          const Text('No users found',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
          const SizedBox(height: 6),
          const Text('Change the filter or add a new user',
              style: TextStyle(fontSize: 13, color: kMuted)),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final int showing, total;
  const _Footer({required this.showing, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FC),
        border: Border(top: BorderSide(color: kBorder)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Text('Showing $showing of $total users',
              style: const TextStyle(fontSize: 12, color: kMuted)),
        ],
      ),
    );
  }
}

// ── Shared Form Helpers ───────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kSub));
  }
}

class _FormField extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const _FormField({
    required this.label,
    required this.ctrl,
    required this.hint,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          validator: validator,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13, color: kText),
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: kMuted, fontSize: 13),
  filled: true,
  fillColor: kLight,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimary, width: 1.5)),
  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.redAccent)),
  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.redAccent)),
);
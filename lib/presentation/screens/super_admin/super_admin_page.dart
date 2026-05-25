import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/mixins/double_tap_exit_mixin.dart';
import 'package:balaji_points/services/branch/branch_service.dart';
import 'package:balaji_points/services/auth/pin_auth_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SuperAdminPage extends StatefulWidget {
  const SuperAdminPage({super.key});

  @override
  State<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage>
    with DoubleTapExitMixin {
  int _tab = 0; // 0 = branches, 1 = create admin

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.forCard),
        title: Text(
          'Logout',
          style: AppTypography.h5(color: context.themePrimary),
        ),
        content: Text(
          'Sign out of super admin?',
          style: AppTypography.bodyMedium(color: context.themeTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge(
                color: context.themeTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.themeError,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.forButton),
            ),
            child: Text(
              'Logout',
              style: AppTypography.labelLarge(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await FirebaseAuth.instance.signOut();
    await SessionService().clearSession();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await handleDoubleTapExit();
      },
      child: Scaffold(
        backgroundColor: context.themeBackground,
        appBar: AppBar(
          backgroundColor: context.themePrimary,
          foregroundColor: AppColors.white,
          elevation: 0,
          title: Row(
            children: [
              const Icon(Icons.admin_panel_settings, size: 22),
              const SizedBox(width: 10),
              Text(
                'Super Admin',
                style: AppTypography.h5(color: AppColors.white),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Row(
              children: [
                _TabBtn(
                  label: 'Branches',
                  index: 0,
                  current: _tab,
                  onTap: () => setState(() => _tab = 0),
                ),
                _TabBtn(
                  label: 'Create Admin',
                  index: 1,
                  current: _tab,
                  onTap: () => setState(() => _tab = 1),
                ),
              ],
            ),
          ),
        ),
        body: _tab == 0 ? const _BranchesTab() : const _CreateAdminTab(),
      ),
    );
  }
}

// ── Tab button ─────────────────────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  final String label;
  final int index, current;
  final VoidCallback onTap;
  const _TabBtn({
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active
                    ? context.themeSecondary
                    : AppColors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelLarge(
              color: active ? AppColors.white : AppColors.white.withValues(alpha: 0.70),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Branches tab ──────────────────────────────────────────────────────────────

class _BranchesTab extends StatelessWidget {
  const _BranchesTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: BranchService().watchAllBranches(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        return Column(
          children: [
            Expanded(
              child: docs.isEmpty
                  ? Center(
                      child: Text(
                        'No branches yet.',
                        style: AppTypography.bodyMedium(
                          color: context.themeTextSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final d = docs[i];
                        final data = d.data();
                        final isActive = data['isActive'] as bool? ?? true;
                        return _BranchCard(
                          branchId: d.id,
                          name: data['name'] as String? ?? d.id,
                          shortName: data['shortName'] as String? ?? '',
                          address: data['address'] as String? ?? '',
                          phone: data['phone'] as String? ?? '',
                          isActive: isActive,
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateBranchDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.themePrimary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.forButton,
                    ),
                  ),
                  icon: const Icon(Icons.add_business),
                  label: Text(
                    'Add New Branch',
                    style: AppTypography.labelLarge(color: AppColors.white),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateBranchDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CreateBranchDialog(),
    );
  }
}

class _BranchCard extends StatelessWidget {
  final String branchId, name, shortName, address, phone;
  final bool isActive;
  const _BranchCard({
    required this.branchId,
    required this.name,
    required this.shortName,
    required this.address,
    required this.phone,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.forCard),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.themePrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.store, color: context.themePrimary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTypography.labelLarge(
                            color: context.themePrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.success.withValues(alpha: 0.12)
                              : context.themeError.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: AppTypography.labelSmall(
                            color: isActive
                                ? AppColors.success
                                : context.themeError,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: AppTypography.bodySmall(
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ],
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: AppTypography.bodySmall(
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'ID: $branchId',
                    style: AppTypography.caption(
                      color: context.themeTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'toggle') {
                  await BranchService().updateBranch(
                    branchId,
                    isActive: !isActive,
                  );
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(isActive ? 'Deactivate' : 'Activate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateBranchDialog extends StatefulWidget {
  const _CreateBranchDialog();

  @override
  State<_CreateBranchDialog> createState() => _CreateBranchDialogState();
}

class _CreateBranchDialogState extends State<_CreateBranchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _shortCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shortCtrl.dispose();
    _addrCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final creatorId = await SessionService().getUserId() ?? 'super_admin';
    final id = await BranchService().createBranch(
      name: _nameCtrl.text.trim(),
      shortName: _shortCtrl.text.trim(),
      address: _addrCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      createdBy: creatorId,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          id != null ? 'Branch created ($id)' : 'Failed to create branch',
        ),
        backgroundColor: id != null ? AppColors.success : context.themeError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.forCard),
      title: Text(
        'New Branch',
        style: AppTypography.h5(color: context.themePrimary),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(
                _nameCtrl,
                'Branch Full Name *',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              _field(
                _shortCtrl,
                'Short Name *',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              _field(_addrCtrl, 'Address'),
              const SizedBox(height: AppSpacing.sm),
              _field(_phoneCtrl, 'Phone', keyboardType: TextInputType.phone),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: AppTypography.labelLarge(
              color: context.themeTextSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.themePrimary,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.forButton),
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Create',
                  style: AppTypography.labelLarge(color: AppColors.white),
                ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodySmall(
          color: context.themeTextSecondary,
        ),
        border: OutlineInputBorder(borderRadius: AppRadius.forInput),
        isDense: true,
      ),
    );
  }
}

// ── Create admin tab ──────────────────────────────────────────────────────────

class _CreateAdminTab extends StatefulWidget {
  const _CreateAdminTab();

  @override
  State<_CreateAdminTab> createState() => _CreateAdminTabState();
}

class _CreateAdminTabState extends State<_CreateAdminTab> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();

  List<Map<String, dynamic>> _branches = [];
  String? _selectedBranchId;
  bool _loadingBranches = true;
  bool _saving = false;
  bool _obscurePin = true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    final b = await BranchService().listActiveBranches();
    if (mounted) {
      setState(() {
        _branches = b;
        if (b.length == 1) _selectedBranchId = b.first['id'] as String;
        _loadingBranches = false;
      });
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _pinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBranchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Select a branch first.'),
          backgroundColor: context.themeError,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final pin = _pinCtrl.text.trim();

      // 1. Create the user with role=carpenter first (setPinForPhone default),
      //    then immediately promote to admin.
      final ok = await PinAuthService().setPinForPhone(
        phone: _phoneCtrl.text.trim(),
        pin: pin,
        firstName: _firstCtrl.text.trim(),
        lastName: _lastCtrl.text.trim(),
        branchId: _selectedBranchId,
      );
      if (!ok) throw Exception('Failed to create user.');

      // 2. Find the new user doc and set role=admin + branchId.
      final phone = PinAuthService().normalizePhone(_phoneCtrl.text.trim());
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (snap.docs.isEmpty)
        throw Exception('User doc not found after creation.');

      final userId = snap.docs.first.id;
      await BranchService().assignAdminToBranch(
        userId: userId,
        branchId: _selectedBranchId!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Admin created for branch ${_selectedBranchId!}\nPhone: ${_phoneCtrl.text.trim()}  PIN: $pin',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 8),
        ),
      );
      _formKey.currentState!.reset();
      _phoneCtrl.clear();
      _firstCtrl.clear();
      _lastCtrl.clear();
      _pinCtrl.clear();
      _confirmPinCtrl.clear();
      setState(() => _selectedBranchId = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: context.themeError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionLabel('Admin Details'),
            const SizedBox(height: AppSpacing.sm),
            _field(
              _firstCtrl,
              'First Name *',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            _field(_lastCtrl, 'Last Name'),
            const SizedBox(height: AppSpacing.sm),
            _field(
              _phoneCtrl,
              'Phone Number * (10 digits)',
              keyboardType: TextInputType.phone,
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(s)) {
                  return 'Enter valid 10-digit phone';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _sectionLabel('Assign Branch'),
            const SizedBox(height: AppSpacing.sm),
            _loadingBranches
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.themeBorder,
                        width: 1.5,
                      ),
                      borderRadius: AppRadius.forInput,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedBranchId,
                        isExpanded: true,
                        hint: Text(
                          'Select branch',
                          style: AppTypography.bodyMedium(
                            color: context.themeTextSecondary,
                          ),
                        ),
                        items: _branches.map((b) {
                          return DropdownMenuItem<String>(
                            value: b['id'] as String,
                            child: Text(
                              b['name'] as String? ?? b['id'] as String,
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedBranchId = v),
                      ),
                    ),
                  ),
            const SizedBox(height: AppSpacing.md),
            _sectionLabel('Set PIN'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _pinCtrl,
              keyboardType: TextInputType.number,
              obscureText: _obscurePin,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: AppTypography.h4(
                color: context.themePrimary,
              ).copyWith(letterSpacing: 10),
              decoration: InputDecoration(
                labelText: '4-digit PIN *',
                counterText: '',
                border: OutlineInputBorder(borderRadius: AppRadius.forInput),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePin ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length != 4) ? 'Enter 4-digit PIN' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _confirmPinCtrl,
              keyboardType: TextInputType.number,
              obscureText: _obscurePin,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: AppTypography.h4(
                color: context.themePrimary,
              ).copyWith(letterSpacing: 10),
              decoration: InputDecoration(
                labelText: 'Confirm PIN *',
                counterText: '',
                border: OutlineInputBorder(borderRadius: AppRadius.forInput),
              ),
              validator: (v) {
                if (v == null || v.length != 4) return 'Enter 4-digit PIN';
                if (v != _pinCtrl.text.trim()) return 'PINs do not match';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: _saving ? null : _create,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.themePrimary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.forButton,
                ),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.person_add),
              label: Text(
                'Create Admin Account',
                style: AppTypography.labelLarge(color: AppColors.white),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: AppRadius.forCard,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Note the PIN shown in the success message — '
                      'share it securely with the admin. '
                      'They can change it after first login.',
                      style: AppTypography.bodySmall(
                        color: context.themeTextSecondary,
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

  Widget _sectionLabel(String text) => Text(
    text,
    style: AppTypography.labelLarge(color: context.themePrimary),
  );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: AppRadius.forInput),
        isDense: true,
      ),
    );
  }
}

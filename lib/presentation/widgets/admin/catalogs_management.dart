import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/presentation/widgets/shared/admin_form_footer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/layout/responsive.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/core/models/catalog.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/common/catalog/catalog_widgets.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/presentation/widgets/shared/empty_state.dart';
import 'package:balaji_points/services/platform/catalog_admin_service.dart';

/// Admin / super admin: manage the product catalogs every member sees.
/// Categories hold catalogs; each catalog is one PDF in Firebase Storage.
class CatalogsManagement extends ConsumerWidget {
  const CatalogsManagement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(adminCatalogCategoriesProvider);
    final catalogs = ref.watch(adminCatalogsProvider);

    if (categories.isLoading || catalogs.isLoading) {
      return const Center(child: AppLoader());
    }
    if (categories.hasError || catalogs.hasError) {
      return Center(
        child: EmptyState(
          icon: Icons.wifi_off_rounded,
          title: l10n.catalogLoadError,
        ),
      );
    }
    final cats = categories.value ?? const <CatalogCategory>[];
    final all = catalogs.value ?? const <Catalog>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        ResponsiveContainer(
          maxWidth: 900,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      label: l10n.catalogAdminAddCategory,
                      icon: Icons.create_new_folder_outlined,
                      onPressed: () => showCategoryDialog(context, ref),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton.primary(
                      label: l10n.catalogAdminAddCatalog,
                      icon: Icons.upload_file_rounded,
                      onPressed: cats.isEmpty
                          ? null
                          : () => openCatalogForm(context, categories: cats),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (cats.isEmpty)
                EmptyState(
                  icon: Icons.menu_book_rounded,
                  title: l10n.catalogAdminEmpty,
                )
              else
                for (final c in cats) ...[
                  _CategorySection(
                    category: c,
                    catalogs: all.where((x) => x.categoryId == c.id).toList(),
                    allCategories: cats,
                  ),
                  const SizedBox(height: 16),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CategorySection extends ConsumerWidget {
  const _CategorySection({
    required this.category,
    required this.catalogs,
    required this.allCategories,
  });

  final CatalogCategory category;
  final List<Catalog> catalogs;
  final List<CatalogCategory> allCategories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.read(catalogAdminServiceProvider);
    return Container(
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: AppRadius.forCard,
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: Icon(Icons.folder_rounded, color: context.themeGold),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    category.name,
                    style: AppTypography.h5(color: context.themeTextPrimary),
                  ),
                ),
                if (!category.active) ...[
                  const SizedBox(width: 8),
                  _HiddenChip(label: l10n.catalogAdminHidden),
                ],
              ],
            ),
            subtitle: Text(
              l10n.catalogCount(catalogs.length),
              style: AppTypography.caption(color: context.themeTextSecondary),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                switch (v) {
                  case 'edit':
                    await showCategoryDialog(context, ref, existing: category);
                  case 'toggle':
                    await _run(
                      context,
                      () => service.setCategoryActive(
                        category.id,
                        !category.active,
                      ),
                    );
                  case 'delete':
                    if (catalogs.isNotEmpty) {
                      _snack(context, l10n.catalogAdminCategoryNotEmpty);
                      return;
                    }
                    if (await _confirm(
                      context,
                      l10n.catalogAdminDeleteCategoryConfirm(category.name),
                    )) {
                      if (!context.mounted) return;
                      await _run(
                        context,
                        () => service.deleteCategory(category.id),
                      );
                    }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                    category.active
                        ? l10n.catalogAdminHide
                        : l10n.catalogAdminShow,
                  ),
                ),
                PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
              ],
            ),
          ),
          if (catalogs.isNotEmpty)
            Divider(height: 1, color: context.themeDivider),
          for (final c in catalogs)
            _CatalogRow(catalog: c, categories: allCategories),
        ],
      ),
    );
  }
}

class _CatalogRow extends ConsumerWidget {
  const _CatalogRow({required this.catalog, required this.categories});

  final Catalog catalog;
  final List<CatalogCategory> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.read(catalogAdminServiceProvider);
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
      leading: CatalogCover(
        url: catalog.coverUrl,
        width: 44,
        height: 58,
        radius: AppRadius.sm8,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              catalog.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelLarge(color: context.themeTextPrimary),
            ),
          ),
          if (!catalog.active) ...[
            const SizedBox(width: 8),
            _HiddenChip(label: l10n.catalogAdminHidden),
          ],
        ],
      ),
      subtitle: Text(
        [
          if (catalog.brand.isNotEmpty) catalog.brand,
          catalogMeta(l10n, catalog),
        ].join('  ·  '),
        style: AppTypography.caption(color: context.themeTextSecondary),
      ),
      onTap: () =>
          openCatalogForm(context, categories: categories, existing: catalog),
      trailing: PopupMenuButton<String>(
        onSelected: (v) async {
          switch (v) {
            case 'edit':
              await openCatalogForm(
                context,
                categories: categories,
                existing: catalog,
              );
            case 'toggle':
              await _run(
                context,
                () => service.setCatalogActive(catalog, !catalog.active),
              );
            case 'delete':
              if (await _confirm(
                context,
                l10n.catalogAdminDeleteCatalogConfirm(catalog.title),
              )) {
                if (!context.mounted) return;
                await _run(context, () => service.deleteCatalog(catalog));
              }
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
          PopupMenuItem(
            value: 'toggle',
            child: Text(
              catalog.active ? l10n.catalogAdminHide : l10n.catalogAdminShow,
            ),
          ),
          PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
        ],
      ),
    );
  }
}

class _HiddenChip extends StatelessWidget {
  const _HiddenChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: context.themeSoftSurface,
      borderRadius: AppRadius.pill,
      border: Border.all(color: context.themeBorder),
    ),
    child: Text(
      label,
      style: AppTypography.labelSmall(color: context.themeTextSecondary),
    ),
  );
}

// ── Category dialog ─────────────────────────────────────────────────────────

Future<void> showCategoryDialog(
  BuildContext context,
  WidgetRef ref, {
  CatalogCategory? existing,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final name = TextEditingController(text: existing?.name ?? '');
  final desc = TextEditingController(text: existing?.description ?? '');
  final formKey = GlobalKey<FormState>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        existing == null
            ? l10n.catalogAdminAddCategory
            : l10n.catalogAdminEditCategory,
      ),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: name,
              autofocus: true,
              maxLength: 40,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.catalogAdminCategoryName,
                hintText: l10n.catalogAdminHintCategoryName,
              ),
              validator: (v) => (v ?? '').trim().length < 2
                  ? l10n.catalogAdminRequired
                  : null,
            ),
            TextFormField(
              controller: desc,
              maxLength: 120,
              decoration: InputDecoration(
                labelText: l10n.catalogAdminDescription,
                hintText: l10n.catalogAdminHintDescription,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
          },
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await _run(
    context,
    () => ref
        .read(catalogAdminServiceProvider)
        .saveCategory(
          id: existing?.id,
          name: name.text,
          description: desc.text,
          active: existing?.active ?? true,
        ),
  );
}

// ── Catalog form ────────────────────────────────────────────────────────────

Future<void> openCatalogForm(
  BuildContext context, {
  required List<CatalogCategory> categories,
  Catalog? existing,
}) {
  if (categories.isEmpty) {
    _snack(context, AppLocalizations.of(context)!.catalogAdminNeedCategory);
    return Future.value();
  }
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          CatalogFormPage(categories: categories, existing: existing),
    ),
  );
}

/// Add or edit one catalog. Picking a PDF uploads it to Firebase Storage
/// when Save is tapped; the PDF is not kept anywhere else.
class CatalogFormPage extends ConsumerStatefulWidget {
  const CatalogFormPage({super.key, required this.categories, this.existing});

  final List<CatalogCategory> categories;
  final Catalog? existing;

  @override
  ConsumerState<CatalogFormPage> createState() => _CatalogFormPageState();
}

class _CatalogFormPageState extends ConsumerState<CatalogFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _brand = TextEditingController(text: widget.existing?.brand);
  late final _desc = TextEditingController(text: widget.existing?.description);
  late final _year = TextEditingController(
    text: '${widget.existing?.year ?? DateTime.now().year}',
  );
  late final _order = TextEditingController(
    text: widget.existing == null ? '' : '${widget.existing!.sortOrder}',
  );
  late String _categoryId =
      widget.existing?.categoryId ?? widget.categories.first.id;

  PlatformFile? _pdf;
  PlatformFile? _cover;
  double? _progress;
  String? _pdfError;

  bool get _busy => _progress != null;

  @override
  void dispose() {
    for (final c in [_title, _brand, _desc, _year, _order]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final l10n = AppLocalizations.of(context)!;
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    final f = res?.files.single;
    if (f == null || f.bytes == null) return;
    String? error;
    try {
      CatalogAdminService.validatePdf(f.bytes!);
    } on CatalogPdfTooLarge catch (e) {
      error = l10n.catalogAdminPdfTooLarge(formatFileSize(e.bytes));
    } on CatalogNotPdf {
      error = l10n.catalogAdminNotPdf;
    }
    setState(() {
      _pdfError = error;
      _pdf = error == null ? f : null;
      if (error == null && _title.text.trim().isEmpty) {
        _title.text = f.name.replaceAll(
          RegExp(r'\.pdf$', caseSensitive: false),
          '',
        );
      }
    });
  }

  Future<void> _pickCover() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final f = res?.files.single;
    if (f?.bytes != null) setState(() => _cover = f);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (widget.existing == null && _pdf == null) {
      setState(() => _pdfError = l10n.catalogAdminPdfRequired);
      return;
    }
    setState(() => _progress = 0);
    try {
      await ref
          .read(catalogAdminServiceProvider)
          .saveCatalog(
            existing: widget.existing,
            categoryId: _categoryId,
            title: _title.text,
            brand: _brand.text,
            description: _desc.text,
            year: int.tryParse(_year.text.trim()) ?? 0,
            sortOrder: int.tryParse(_order.text.trim()),
            pdfBytes: _pdf?.bytes,
            coverBytes: _cover?.bytes,
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          );
      if (!mounted) return;
      _snack(context, l10n.catalogAdminSaved);
      Navigator.of(context).pop();
    } catch (e) {
      AppLogger.error('Catalog save failed', e);
      if (!mounted) return;
      setState(() => _progress = null);
      _snack(context, _errorText(l10n, e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final existing = widget.existing;
    final pdfLabel = _pdf != null
        ? '${_pdf!.name}  ·  ${formatFileSize(_pdf!.size)}'
        : existing != null
        ? '${existing.fileName}  ·  ${catalogMeta(l10n, existing)}'
        : null;

    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        title: Text(
          existing == null
              ? l10n.catalogAdminAddCatalog
              : l10n.catalogAdminEditCatalog,
        ),
      ),
      // Save stays fixed at the bottom: above Android's navigation bar
      // (gestures or buttons) and above the keyboard while typing.
      bottomNavigationBar: AdminFormFooter(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_busy) ...[
              LinearProgressIndicator(
                value: _progress == 0 ? null : _progress,
                color: context.themePrimary,
                backgroundColor: context.themeBorder,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.catalogAdminUploading(((_progress ?? 0) * 100).round()),
                textAlign: TextAlign.center,
                style: AppTypography.caption(color: context.themeTextSecondary),
              ),
              const SizedBox(height: 8),
            ],
            AppButton.primary(
              label: l10n.save,
              icon: Icons.cloud_upload_rounded,
              isLoading: _busy,
              onPressed: _busy ? null : _save,
            ),
          ],
        ),
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ResponsiveContainer(
                maxWidth: 640,
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // PDF
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.themeCard,
                        borderRadius: AppRadius.forCard,
                        border: Border.all(
                          color: _pdfError != null
                              ? context.themeError
                              : context.themeBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.picture_as_pdf_rounded,
                                color: context.themePrimary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  pdfLabel ?? l10n.catalogAdminPdfRequired,
                                  style: AppTypography.body(
                                    color: context.themeTextPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_pdfError != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _pdfError!,
                              style: AppTypography.caption(
                                color: context.themeError,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          AppButton.outline(
                            label: existing == null && _pdf == null
                                ? l10n.catalogAdminPickPdf
                                : l10n.catalogAdminReplacePdf,
                            icon: Icons.attach_file_rounded,
                            onPressed: _pickPdf,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _categoryId,
                      decoration: InputDecoration(
                        labelText: l10n.catalogAdminCategory,
                      ),
                      items: [
                        for (final c in widget.categories)
                          DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (v) =>
                          setState(() => _categoryId = v ?? _categoryId),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _title,
                      maxLength: 80,
                      decoration: InputDecoration(
                        labelText: l10n.catalogAdminTitle,
                        hintText: l10n.catalogAdminHintTitle,
                      ),
                      validator: (v) => (v ?? '').trim().length < 2
                          ? l10n.catalogAdminRequired
                          : null,
                    ),
                    TextFormField(
                      controller: _brand,
                      maxLength: 40,
                      decoration: InputDecoration(
                        labelText: l10n.catalogAdminBrand,
                        hintText: l10n.catalogAdminHintBrand,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _year,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            decoration: InputDecoration(
                              labelText: l10n.catalogAdminYear,
                              hintText: l10n.catalogAdminHintYear,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _order,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            decoration: InputDecoration(
                              labelText: l10n.catalogAdminOrder,
                              hintText: l10n.catalogAdminHintOrder,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _desc,
                      maxLength: 300,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: l10n.catalogAdminDescription,
                        hintText: l10n.catalogAdminHintDescription,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Cover
                    Row(
                      children: [
                        _cover?.bytes != null
                            ? ClipRRect(
                                borderRadius: AppRadius.sm8,
                                child: Image.memory(
                                  _cover!.bytes!,
                                  width: 56,
                                  height: 74,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : CatalogCover(
                                url: existing?.coverUrl ?? '',
                                width: 56,
                                height: 74,
                                radius: AppRadius.sm8,
                              ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextButton.icon(
                                onPressed: _pickCover,
                                icon: const Icon(Icons.image_outlined),
                                label: Text(l10n.catalogAdminPickCover),
                              ),
                              Text(
                                l10n.catalogAdminCoverAuto,
                                style: AppTypography.caption(
                                  color: context.themeTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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

// ── Helpers ─────────────────────────────────────────────────────────────────

String _errorText(AppLocalizations l10n, Object e) {
  if (e is CatalogPdfTooLarge) {
    return l10n.catalogAdminPdfTooLarge(formatFileSize(e.bytes));
  }
  if (e is CatalogNotPdf) return l10n.catalogAdminNotPdf;
  if (e is CatalogCategoryNotEmpty) return l10n.catalogAdminCategoryNotEmpty;
  if (e is FirebaseException &&
      (e.code == 'permission-denied' || e.code == 'unauthorized')) {
    return l10n.catalogAdminPermission;
  }
  return l10n.catalogAdminSaveFailed('$e');
}

Future<void> _run(BuildContext context, Future<Object?> Function() job) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    await job();
  } catch (e) {
    AppLogger.error('Catalog admin action failed', e);
    if (context.mounted) _snack(context, _errorText(l10n, e), error: true);
  }
}

Future<bool> _confirm(BuildContext context, String message) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  return ok == true;
}

void _snack(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: error ? context.themeError : null,
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';

/// Desktop data table in a spec card: white surface, 1 px border, radius 16,
/// horizontal scroll inside the card, and "Page X of Y · 20 per page" footer
/// with Previous / Next (UI spec "Admin dashboard").
class AppTableCard extends StatefulWidget {
  const AppTableCard({
    super.key,
    required this.columns,
    required this.rows,
    this.pageSize = 20,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.minTableWidth = 720,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final int pageSize;
  final int? sortColumnIndex;
  final bool sortAscending;

  /// Below this width the table scrolls horizontally inside the card.
  final double minTableWidth;

  @override
  State<AppTableCard> createState() => _AppTableCardState();
}

class _AppTableCardState extends State<AppTableCard> {
  int _page = 0;

  int get _pageCount =>
      widget.rows.isEmpty ? 1 : (widget.rows.length / widget.pageSize).ceil();

  @override
  void didUpdateWidget(covariant AppTableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-sorting goes back to page 1; shrinking lists keep a valid page.
    if (oldWidget.sortColumnIndex != widget.sortColumnIndex ||
        oldWidget.sortAscending != widget.sortAscending) {
      _page = 0;
    }
    if (_page >= _pageCount) _page = _pageCount - 1;
  }

  @override
  Widget build(BuildContext context) {
    final start = _page * widget.pageSize;
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    final pageRows = widget.rows.sublist(start, end);
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: context.themeCard,
          borderRadius: AppRadius.all16,
          border: Border.all(color: context.themeBorder),
          boxShadow: context.themeShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth < widget.minTableWidth
                        ? widget.minTableWidth
                        : constraints.maxWidth,
                  ),
                  child: DataTable(
                    sortColumnIndex: widget.sortColumnIndex,
                    sortAscending: widget.sortAscending,
                    border: TableBorder(
                      horizontalInside: BorderSide(color: context.themeDivider),
                    ),
                    columns: widget.columns,
                    rows: pageRows,
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: context.themeBorder),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              // Wraps onto two lines on narrow screens / large text instead
              // of overflowing (long Tamil labels at 1.3x on 320 px).
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  Text(
                    widget.rows.isEmpty
                        ? l10n.noRows
                        : l10n.tablePageInfo(
                            '${_page + 1}',
                            '$_pageCount',
                            '${start + 1}',
                            '$end',
                            '${widget.rows.length}',
                          ),
                    style: AppTypography.caption(
                      color: context.themeTextSecondary,
                    ),
                  ),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      OutlinedButton(
                        onPressed: _page > 0
                            ? () => setState(() => _page--)
                            : null,
                        child: Text(l10n.previousPage),
                      ),
                      OutlinedButton(
                        onPressed: _page < _pageCount - 1
                            ? () => setState(() => _page++)
                            : null,
                        child: Text(l10n.next),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

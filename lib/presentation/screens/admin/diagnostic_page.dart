// TEMPORARY DIAGNOSTIC PAGE - Remove after verification
// This page verifies Firestore data for user 9894223355

import 'package:flutter/material.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_card.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DiagnosticPage extends StatefulWidget {
  final String phoneNumber;

  const DiagnosticPage({super.key, this.phoneNumber = '9894223355'});

  @override
  State<DiagnosticPage> createState() => _DiagnosticPageState();
}

class _DiagnosticPageState extends State<DiagnosticPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _diagnosticData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final phone = widget.phoneNumber;
      final normalizedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

      AppLogger.debug('🔍 [DIAGNOSTIC] Starting verification for phone: $phone');
      AppLogger.debug('🔍 [DIAGNOSTIC] Normalized phone: $normalizedPhone');

      // 1. Check user document by document ID
      AppLogger.debug('🔍 [DIAGNOSTIC] Step 1: Checking user document by ID...');
      final userDocById = await _firestore
          .collection('users')
          .doc(normalizedPhone)
          .get();
      AppLogger.debug('   User doc exists (by ID): ${userDocById.exists}');
      AppLogger.debug('   User doc ID: ${userDocById.id}');

      Map<String, dynamic>? userDataById;
      if (userDocById.exists) {
        userDataById = userDocById.data();
        AppLogger.debug('   User data keys: ${userDataById?.keys.toList() ?? []}');
        AppLogger.debug('   User phone field: ${userDataById?['phone']}');
      }

      // 2. Check user document by phone field query
      AppLogger.debug('🔍 [DIAGNOSTIC] Step 2: Checking user document by phone field...');
      final userQueryByPhone = await _firestore
          .collection('users')
          .where('phone', isEqualTo: normalizedPhone)
          .limit(1)
          .get();
      AppLogger.debug(
        '   User docs found (by phone field): ${userQueryByPhone.docs.length}',
      );

      Map<String, dynamic>? userDataByPhone;
      if (userQueryByPhone.docs.isNotEmpty) {
        final doc = userQueryByPhone.docs.first;
        userDataByPhone = doc.data();
        AppLogger.debug('   User doc ID (from query): ${doc.id}');
        AppLogger.debug('   User phone field: ${userDataByPhone['phone']}');
      }

      // 3. Check bills with carpenterPhone
      AppLogger.debug('🔍 [DIAGNOSTIC] Step 3: Checking bills with carpenterPhone...');
      final billsByPhone = await _firestore
          .collection('bills')
          .where('carpenterPhone', isEqualTo: phone)
          .get();
      AppLogger.debug(
        '   Bills found (carpenterPhone=$phone): ${billsByPhone.docs.length}',
      );

      // 4. Check bills with normalized carpenterPhone
      AppLogger.debug(
        '🔍 [DIAGNOSTIC] Step 4: Checking bills with normalized carpenterPhone...',
      );
      final billsByNormalizedPhone = await _firestore
          .collection('bills')
          .where('carpenterPhone', isEqualTo: normalizedPhone)
          .get();
      AppLogger.debug(
        '   Bills found (carpenterPhone=$normalizedPhone): ${billsByNormalizedPhone.docs.length}',
      );

      // 5. Check bills with carpenterId
      AppLogger.debug('🔍 [DIAGNOSTIC] Step 5: Checking bills with carpenterId...');
      final billsById = await _firestore
          .collection('bills')
          .where('carpenterId', isEqualTo: phone)
          .get();
      AppLogger.debug('   Bills found (carpenterId=$phone): ${billsById.docs.length}');

      // 6. Check bills with normalized carpenterId
      AppLogger.debug(
        '🔍 [DIAGNOSTIC] Step 6: Checking bills with normalized carpenterId...',
      );
      final billsByNormalizedId = await _firestore
          .collection('bills')
          .where('carpenterId', isEqualTo: normalizedPhone)
          .get();
      AppLogger.debug(
        '   Bills found (carpenterId=$normalizedPhone): ${billsByNormalizedId.docs.length}',
      );

      // 7. Get all pending bills and check for this user
      AppLogger.debug('🔍 [DIAGNOSTIC] Step 7: Checking all pending bills...');
      final allPendingBills = await _firestore
          .collection('bills')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      AppLogger.debug('   Total pending bills: ${allPendingBills.docs.length}');

      final matchingPendingBills = <Map<String, dynamic>>[];
      final today = DateTime.now();

      for (final doc in allPendingBills.docs) {
        final billData = doc.data();
        final carpenterId = billData['carpenterId'] as String? ?? '';
        final carpenterPhone = billData['carpenterPhone'] as String? ?? '';

        // Check if this bill belongs to our user (exact or normalized match)
        final matchesId =
            carpenterId == phone || carpenterId == normalizedPhone;
        final matchesPhone =
            carpenterPhone == phone || carpenterPhone == normalizedPhone;

        if (matchesId || matchesPhone) {
          final billDate = billData['billDate'] as Timestamp?;
          final billDateTime = billDate?.toDate();
          final isToday =
              billDateTime != null &&
              billDateTime.year == today.year &&
              billDateTime.month == today.month &&
              billDateTime.day == today.day;

          matchingPendingBills.add({
            'billId': doc.id,
            'carpenterId': carpenterId,
            'carpenterPhone': carpenterPhone,
            'amount': billData['amount'],
            'status': billData['status'],
            'billDate': billDateTime,
            'isToday': isToday,
            'createdAt': (billData['createdAt'] as Timestamp?)?.toDate(),
            'storeName': billData['storeName'],
          });
        }
      }

      AppLogger.debug('   Matching pending bills: ${matchingPendingBills.length}');

      // Compile diagnostic data
      _diagnosticData = {
        'phoneNumber': phone,
        'normalizedPhone': normalizedPhone,
        'userDocument': {
          'existsById': userDocById.exists,
          'docId': userDocById.id,
          'dataById': userDataById,
          'existsByPhoneField': userQueryByPhone.docs.isNotEmpty,
          'docIdFromQuery': userQueryByPhone.docs.isNotEmpty
              ? userQueryByPhone.docs.first.id
              : null,
          'dataByPhoneField': userDataByPhone,
        },
        'bills': {
          'byCarpenterPhone': {
            'count': billsByPhone.docs.length,
            'bills': billsByPhone.docs
                .map(
                  (d) => {
                    'id': d.id,
                    'carpenterId': d.data()['carpenterId'],
                    'carpenterPhone': d.data()['carpenterPhone'],
                    'status': d.data()['status'],
                    'amount': d.data()['amount'],
                    'billDate': (d.data()['billDate'] as Timestamp?)?.toDate(),
                  },
                )
                .toList(),
          },
          'byNormalizedCarpenterPhone': {
            'count': billsByNormalizedPhone.docs.length,
          },
          'byCarpenterId': {'count': billsById.docs.length},
          'byNormalizedCarpenterId': {'count': billsByNormalizedId.docs.length},
          'matchingPendingBills': matchingPendingBills,
        },
        'totalPendingBills': allPendingBills.docs.length,
      };

      AppLogger.debug('✅ [DIAGNOSTIC] Verification complete');
    } catch (e, st) {
      AppLogger.debug('❌ [DIAGNOSTIC] Error: $e');
      AppLogger.debug('   StackTrace: $st');
      _error = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.themeBackground,
        foregroundColor: context.themeTextPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: AppText.h4(
          AppLocalizations.of(context)!.diagnosticUser('${widget.phoneNumber}'),
          color: context.themeTextPrimary,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _runDiagnostics,
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: AppLoader())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_rounded,
                    color: context.themeError,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  AppText.body(
                    AppLocalizations.of(context)!.error3('$_error'),
                    color: context.themeError,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  AppButton.outline(
                    label: AppLocalizations.of(context)!.retry,
                    onPressed: _runDiagnostics,
                    fullWidth: false,
                  ),
                ],
              ),
            )
          : _diagnosticData == null
          ? Center(child: Text(AppLocalizations.of(context)!.noData))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    AppLocalizations.of(context)!.phoneNumberInformation,
                    [
                      _buildInfoRow(
                        AppLocalizations.of(context)!.originalPhone,
                        _diagnosticData!['phoneNumber'],
                      ),
                      _buildInfoRow(
                        AppLocalizations.of(context)!.normalizedPhone,
                        _diagnosticData!['normalizedPhone'],
                      ),
                      _buildInfoRow(
                        AppLocalizations.of(context)!.match,
                        _diagnosticData!['phoneNumber'] ==
                                _diagnosticData!['normalizedPhone']
                            ? 'YES'
                            : 'NO',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildUserDocumentSection(),
                  const SizedBox(height: 24),
                  _buildBillsSection(),
                  const SizedBox(height: 24),
                  _buildPendingBillsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.h4(title, color: context.themeContentColor),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: AppText.label('$label:', color: context.themeContentColor),
          ),
          Expanded(
            child: AppText.body(
              value?.toString() ?? 'null',
              color: context.themeTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDocumentSection() {
    final userDoc = _diagnosticData!['userDocument'] as Map<String, dynamic>;

    return _buildSection(AppLocalizations.of(context)!.userDocumentStatus, [
      _buildInfoRow(
        AppLocalizations.of(context)!.existsByDocumentId,
        userDoc['existsById'] ? 'YES' : 'NO',
      ),
      _buildInfoRow(
        AppLocalizations.of(context)!.documentId,
        userDoc['docId'] ?? 'N/A',
      ),
      if (userDoc['dataById'] != null) ...[
        _buildInfoRow(
          AppLocalizations.of(context)!.phoneFieldInData,
          userDoc['dataById']?['phone'] ?? 'N/A',
        ),
        _buildInfoRow(
          AppLocalizations.of(context)!.firstName,
          userDoc['dataById']?['firstName'] ?? 'N/A',
        ),
        _buildInfoRow(
          AppLocalizations.of(context)!.lastName,
          userDoc['dataById']?['lastName'] ?? 'N/A',
        ),
      ],
      const Divider(height: 24),
      _buildInfoRow(
        AppLocalizations.of(context)!.existsByPhoneFieldQuery,
        userDoc['existsByPhoneField'] ? 'YES' : 'NO',
      ),
      if (userDoc['docIdFromQuery'] != null)
        _buildInfoRow(
          AppLocalizations.of(context)!.documentIdFromQuery,
          userDoc['docIdFromQuery'],
        ),
      if (userDoc['dataByPhoneField'] != null) ...[
        _buildInfoRow(
          AppLocalizations.of(context)!.phoneFieldInData,
          userDoc['dataByPhoneField']?['phone'] ?? 'N/A',
        ),
      ],
      const Divider(height: 24),
      _buildInfoRow(
        AppLocalizations.of(context)!.issueDetected,
        (userDoc['existsById'] &&
                userDoc['existsByPhoneField'] &&
                userDoc['docId'] != userDoc['docIdFromQuery'])
            ? AppLocalizations.of(context)!.documentIdMismatch
            : (userDoc['existsById'] || userDoc['existsByPhoneField'])
            ? AppLocalizations.of(context)!.userDocumentFound
            : AppLocalizations.of(context)!.userDocumentNotFound,
      ),
    ]);
  }

  Widget _buildBillsSection() {
    final bills = _diagnosticData!['bills'] as Map<String, dynamic>;

    return _buildSection(AppLocalizations.of(context)!.billsCollectionStatus, [
      _buildInfoRow(
        'Bills (carpenterPhone=original)',
        '${bills['byCarpenterPhone']?['count'] ?? 0}',
      ),
      _buildInfoRow(
        'Bills (carpenterPhone=normalized)',
        '${bills['byNormalizedCarpenterPhone']?['count'] ?? 0}',
      ),
      _buildInfoRow(
        'Bills (carpenterId=original)',
        '${bills['byCarpenterId']?['count'] ?? 0}',
      ),
      _buildInfoRow(
        'Bills (carpenterId=normalized)',
        '${bills['byNormalizedCarpenterId']?['count'] ?? 0}',
      ),
      const Divider(height: 24),
      _buildInfoRow(
        AppLocalizations.of(context)!.issueDetected,
        (bills['byCarpenterPhone']?['count'] ?? 0) !=
                (bills['byNormalizedCarpenterPhone']?['count'] ?? 0)
            ? AppLocalizations.of(context)!.phoneFormatMismatchInBills
            : AppLocalizations.of(context)!.phoneFormatConsistent,
      ),
    ]);
  }

  Widget _buildPendingBillsSection() {
    final matchingBills =
        _diagnosticData!['bills']?['matchingPendingBills'] as List<dynamic>? ??
        [];
    final totalPending = _diagnosticData!['totalPendingBills'] ?? 0;

    return _buildSection(AppLocalizations.of(context)!.pendingBillsStatus, [
      _buildInfoRow(
        AppLocalizations.of(context)!.totalPendingBills,
        totalPending.toString(),
      ),
      _buildInfoRow(
        AppLocalizations.of(context)!.matchingBillsFound,
        matchingBills.length.toString(),
      ),
      const Divider(height: 24),
      if (matchingBills.isEmpty)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppText.body(
            AppLocalizations.of(context)!.noPendingBillsFoundForThis,
            color: context.themeError,
          ),
        )
      else
        ...matchingBills.map(
          (bill) => AppCard(
            margin: const EdgeInsets.only(bottom: 8),
            color: context.themeSoftSurface,
            padding: const EdgeInsets.all(12),
            showShadow: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  AppLocalizations.of(context)!.billId,
                  bill['billId'],
                ),
                _buildInfoRow(
                  AppLocalizations.of(context)!.carpenterId,
                  bill['carpenterId'],
                ),
                _buildInfoRow(
                  AppLocalizations.of(context)!.carpenterPhone,
                  bill['carpenterPhone'],
                ),
                _buildInfoRow(
                  AppLocalizations.of(context)!.amountLabel,
                  '₹${bill['amount']}',
                ),
                _buildInfoRow(
                  AppLocalizations.of(context)!.status,
                  bill['status'],
                ),
                _buildInfoRow(
                  AppLocalizations.of(context)!.billDateLabel,
                  bill['billDate'] != null
                      ? DateFormat('dd MMM yyyy').format(bill['billDate'])
                      : 'N/A',
                ),
                _buildInfoRow(
                  AppLocalizations.of(context)!.isToday,
                  bill['isToday'] == true ? 'YES' : 'NO',
                ),
                _buildInfoRow(
                  AppLocalizations.of(context)!.createdAt,
                  bill['createdAt'] != null
                      ? DateFormat(
                          'dd MMM yyyy, hh:mm a',
                        ).format(bill['createdAt'])
                      : 'N/A',
                ),
                if (bill['isToday'] != true)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: AppText.bodySmall(
                      AppLocalizations.of(context)!.thisBillWonTShowIn,
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),
          ),
        ),
    ]);
  }
}

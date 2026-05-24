// TEMPORARY DIAGNOSTIC PAGE - Remove after verification
// This page verifies Firestore data for user 9894223355

import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
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

      print('🔍 [DIAGNOSTIC] Starting verification for phone: $phone');
      print('🔍 [DIAGNOSTIC] Normalized phone: $normalizedPhone');

      // 1. Check user document by document ID
      print('🔍 [DIAGNOSTIC] Step 1: Checking user document by ID...');
      final userDocById = await _firestore
          .collection('users')
          .doc(normalizedPhone)
          .get();
      print('   User doc exists (by ID): ${userDocById.exists}');
      print('   User doc ID: ${userDocById.id}');

      Map<String, dynamic>? userDataById;
      if (userDocById.exists) {
        userDataById = userDocById.data();
        print('   User data keys: ${userDataById?.keys.toList() ?? []}');
        print('   User phone field: ${userDataById?['phone']}');
      }

      // 2. Check user document by phone field query
      print('🔍 [DIAGNOSTIC] Step 2: Checking user document by phone field...');
      final userQueryByPhone = await _firestore
          .collection('users')
          .where('phone', isEqualTo: normalizedPhone)
          .limit(1)
          .get();
      print(
        '   User docs found (by phone field): ${userQueryByPhone.docs.length}',
      );

      Map<String, dynamic>? userDataByPhone;
      if (userQueryByPhone.docs.isNotEmpty) {
        final doc = userQueryByPhone.docs.first;
        userDataByPhone = doc.data();
        print('   User doc ID (from query): ${doc.id}');
        print('   User phone field: ${userDataByPhone['phone']}');
      }

      // 3. Check bills with carpenterPhone
      print('🔍 [DIAGNOSTIC] Step 3: Checking bills with carpenterPhone...');
      final billsByPhone = await _firestore
          .collection('bills')
          .where('carpenterPhone', isEqualTo: phone)
          .get();
      print(
        '   Bills found (carpenterPhone=$phone): ${billsByPhone.docs.length}',
      );

      // 4. Check bills with normalized carpenterPhone
      print(
        '🔍 [DIAGNOSTIC] Step 4: Checking bills with normalized carpenterPhone...',
      );
      final billsByNormalizedPhone = await _firestore
          .collection('bills')
          .where('carpenterPhone', isEqualTo: normalizedPhone)
          .get();
      print(
        '   Bills found (carpenterPhone=$normalizedPhone): ${billsByNormalizedPhone.docs.length}',
      );

      // 5. Check bills with carpenterId
      print('🔍 [DIAGNOSTIC] Step 5: Checking bills with carpenterId...');
      final billsById = await _firestore
          .collection('bills')
          .where('carpenterId', isEqualTo: phone)
          .get();
      print('   Bills found (carpenterId=$phone): ${billsById.docs.length}');

      // 6. Check bills with normalized carpenterId
      print(
        '🔍 [DIAGNOSTIC] Step 6: Checking bills with normalized carpenterId...',
      );
      final billsByNormalizedId = await _firestore
          .collection('bills')
          .where('carpenterId', isEqualTo: normalizedPhone)
          .get();
      print(
        '   Bills found (carpenterId=$normalizedPhone): ${billsByNormalizedId.docs.length}',
      );

      // 7. Get all pending bills and check for this user
      print('🔍 [DIAGNOSTIC] Step 7: Checking all pending bills...');
      final allPendingBills = await _firestore
          .collection('bills')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      print('   Total pending bills: ${allPendingBills.docs.length}');

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

      print('   Matching pending bills: ${matchingPendingBills.length}');

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

      print('✅ [DIAGNOSTIC] Verification complete');
    } catch (e, st) {
      print('❌ [DIAGNOSTIC] Error: $e');
      print('   StackTrace: $st');
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
        backgroundColor: Colors.white,
        foregroundColor: AppColors.lightPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Diagnostic: User ${widget.phoneNumber}',
          style: TextStyle(fontSize: 18, color: AppColors.lightPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDiagnostics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $_error',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _runDiagnostics,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _diagnosticData == null
          ? const Center(child: Text('No data'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Phone Number Information', [
                    _buildInfoRow(
                      'Original Phone',
                      _diagnosticData!['phoneNumber'],
                    ),
                    _buildInfoRow(
                      'Normalized Phone',
                      _diagnosticData!['normalizedPhone'],
                    ),
                    _buildInfoRow(
                      'Match',
                      _diagnosticData!['phoneNumber'] ==
                              _diagnosticData!['normalizedPhone']
                          ? '✅ YES'
                          : '❌ NO',
                    ),
                  ]),
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.labelLarge().copyWith(
                fontSize: 18,
                color: AppColors.lightPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
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
            child: Text(
              '$label:',
              style: AppTypography.labelLarge().copyWith(
                fontSize: 14,
                color: AppColors.lightPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'null',
              style: AppTypography.bodyMedium().copyWith(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDocumentSection() {
    final userDoc = _diagnosticData!['userDocument'] as Map<String, dynamic>;

    return _buildSection('User Document Status', [
      _buildInfoRow(
        'Exists (by Document ID)',
        userDoc['existsById'] ? '✅ YES' : '❌ NO',
      ),
      _buildInfoRow('Document ID', userDoc['docId'] ?? 'N/A'),
      if (userDoc['dataById'] != null) ...[
        _buildInfoRow(
          'Phone Field (in data)',
          userDoc['dataById']?['phone'] ?? 'N/A',
        ),
        _buildInfoRow('First Name', userDoc['dataById']?['firstName'] ?? 'N/A'),
        _buildInfoRow('Last Name', userDoc['dataById']?['lastName'] ?? 'N/A'),
      ],
      const Divider(height: 24),
      _buildInfoRow(
        'Exists (by Phone Field Query)',
        userDoc['existsByPhoneField'] ? '✅ YES' : '❌ NO',
      ),
      if (userDoc['docIdFromQuery'] != null)
        _buildInfoRow('Document ID (from query)', userDoc['docIdFromQuery']),
      if (userDoc['dataByPhoneField'] != null) ...[
        _buildInfoRow(
          'Phone Field (in data)',
          userDoc['dataByPhoneField']?['phone'] ?? 'N/A',
        ),
      ],
      const Divider(height: 24),
      _buildInfoRow(
        '⚠️ ISSUE DETECTED',
        (userDoc['existsById'] &&
                userDoc['existsByPhoneField'] &&
                userDoc['docId'] != userDoc['docIdFromQuery'])
            ? '❌ Document ID mismatch!'
            : (userDoc['existsById'] || userDoc['existsByPhoneField'])
            ? '✅ User document found'
            : '❌ User document NOT FOUND',
      ),
    ]);
  }

  Widget _buildBillsSection() {
    final bills = _diagnosticData!['bills'] as Map<String, dynamic>;

    return _buildSection('Bills Collection Status', [
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
        '⚠️ ISSUE DETECTED',
        (bills['byCarpenterPhone']?['count'] ?? 0) !=
                (bills['byNormalizedCarpenterPhone']?['count'] ?? 0)
            ? '❌ Phone format mismatch in bills!'
            : '✅ Phone format consistent',
      ),
    ]);
  }

  Widget _buildPendingBillsSection() {
    final matchingBills =
        _diagnosticData!['bills']?['matchingPendingBills'] as List<dynamic>? ??
        [];
    final totalPending = _diagnosticData!['totalPendingBills'] ?? 0;

    return _buildSection('Pending Bills Status', [
      _buildInfoRow('Total Pending Bills', totalPending.toString()),
      _buildInfoRow('Matching Bills Found', matchingBills.length.toString()),
      const Divider(height: 24),
      if (matchingBills.isEmpty)
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            '❌ No pending bills found for this user!',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        )
      else
        ...matchingBills.map(
          (bill) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: Colors.grey[100],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Bill ID', bill['billId']),
                  _buildInfoRow('Carpenter ID', bill['carpenterId']),
                  _buildInfoRow('Carpenter Phone', bill['carpenterPhone']),
                  _buildInfoRow('Amount', '₹${bill['amount']}'),
                  _buildInfoRow('Status', bill['status']),
                  _buildInfoRow(
                    'Bill Date',
                    bill['billDate'] != null
                        ? DateFormat('dd MMM yyyy').format(bill['billDate'])
                        : 'N/A',
                  ),
                  _buildInfoRow(
                    'Is Today',
                    bill['isToday'] == true ? '✅ YES' : '❌ NO',
                  ),
                  _buildInfoRow(
                    'Created At',
                    bill['createdAt'] != null
                        ? DateFormat(
                            'dd MMM yyyy HH:mm',
                          ).format(bill['createdAt'])
                        : 'N/A',
                  ),
                  if (bill['isToday'] != true)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '⚠️ This bill won\'t show in default admin view (not today)',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
    ]);
  }
}

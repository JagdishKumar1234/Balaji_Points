import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/services/platform/cart_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService _cartService = CartService();
  final SessionService _sessionService = SessionService();

  String? _userId;
  bool _loadingUser = true;
  final TextEditingController _addressController = TextEditingController();

  static const String _adminWhatsAppNumber =
      '919600609121'; // Sri Balaji Plywood & Hardware WhatsApp

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final id = await _sessionService.getUserId();
    if (!mounted) return;
    setState(() {
      _userId = id;
      _loadingUser = false;
    });
  }

  Future<void> _placeOrder(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (_userId == null) return;

    try {
      final enteredAddress = _addressController.text.trim();
      final result = await _cartService.placeOrder(
        userId: _userId!,
        address: enteredAddress.isEmpty ? null : enteredAddress,
      );
      if (result == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Your cart is empty.')));
        return;
      }

      final orderId = result['orderId'] as String;
      final items = (result['items'] as List).cast<Map<String, dynamic>>();
      final total = (result['totalAmount'] as num).toDouble();
      final address = (result['address'] as String?) ?? '';

      final phone = await _sessionService.getPhoneNumber() ?? '';

      final buffer = StringBuffer();
      buffer.writeln('New order from carpenter');
      if (phone.isNotEmpty) {
        buffer.writeln('Phone: $phone');
      }
      buffer.writeln('Order ID: $orderId');
      if (address.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('Address: $address');
      }
      buffer.writeln('');
      buffer.writeln('Items:');
      for (final item in items) {
        final name = item['name'] ?? '';
        final qty = item['quantity'] ?? 0;
        final price = (item['price'] ?? 0) as num;
        buffer.writeln('- $name x$qty @ ₹${price.toStringAsFixed(0)}');
      }
      buffer.writeln('');
      buffer.writeln('Total: ₹${total.toStringAsFixed(0)}');

      final message = buffer.toString();
      final uri = Uri.parse(
        'https://wa.me/$_adminWhatsAppNumber?text=${Uri.encodeComponent(message)}',
      );

      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open WhatsApp.')),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order placed successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: context.themeError,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appBarFill =
        theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor;
    final borderColor = isDark
        ? AppColors.white.withValues(alpha: 0.12)
        : AppColors.black.withValues(alpha: 0.08);

    if (_loadingUser) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: appBarFill,
          foregroundColor: context.themeTextPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
            onPressed: () => context.pop(),
          ),
          title: const Text('Your Cart'),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: borderColor),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(color: context.themePrimary),
        ),
      );
    }

    if (_userId == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: appBarFill,
          foregroundColor: context.themeTextPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
            onPressed: () => context.pop(),
          ),
          title: const Text('Your Cart'),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: borderColor),
          ),
        ),
        body: const Center(child: Text('Please log in to use cart.')),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarFill,
        foregroundColor: context.themeTextPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => context.pop(),
        ),
        title: const Text('Your Cart'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _cartService.watchCart(_userId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading cart:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium().copyWith(
                    fontSize: 14,
                    color: context.themeError,
                  ),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: context.themePrimary),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: context.themeBorder,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: AppTypography.buttonMedium().copyWith(
                      fontSize: 20,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Browse products and add items to your cart.',
                    style: AppTypography.bodyMedium().copyWith(
                      fontSize: 14,
                      color: context.themeTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          double total = 0;
          for (final doc in docs) {
            final data = doc.data();
            final qty = (data['quantity'] ?? 0) as int;
            final price = (data['price'] ?? 0) as num;
            total += qty * price.toDouble();
          }

          return Padding(
            padding: CarpenterShellLayout.scrollViewPadding(
              MediaQuery.of(context),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final productId = data['productId'] as String? ?? doc.id;
                      final name = (data['name'] ?? '') as String;
                      final imageUrl = (data['imageUrl'] ?? '') as String;
                      final qty = (data['quantity'] ?? 0) as int;
                      final price = (data['price'] ?? 0) as num;
                      final mainCategory =
                          (data['mainCategory'] ?? '') as String;
                      final subCategory = (data['subCategory'] ?? '') as String;
                      final lineTotal = qty * price.toDouble();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: context.themePrimary.withValues(
                                            alpha: 0.1,
                                          ),
                                          child: Icon(
                                            Icons.layers_rounded,
                                            color: context.themePrimary,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.labelLarge()
                                          .copyWith(
                                            fontSize: 16,
                                            color: context.themeTextPrimary,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      subCategory.isNotEmpty
                                          ? '$mainCategory • $subCategory'
                                          : mainCategory,
                                      style: AppTypography.bodyMedium()
                                          .copyWith(
                                            fontSize: 12,
                                            color: context.themeTextSecondary,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '₹${price.toStringAsFixed(0)}',
                                      style: AppTypography.buttonMedium().copyWith(
                                        fontSize: 14,
                                        color: context.themePrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle),
                                        color: context.themePrimary,
                                        onPressed: () {
                                          final newQty = qty - 1;
                                          _cartService.updateQuantity(
                                            userId: _userId!,
                                            productId: productId,
                                            quantity: newQty,
                                          );
                                        },
                                      ),
                                      Text(
                                        '$qty',
                                        style: AppTypography.buttonMedium()
                                            .copyWith(fontSize: 14),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle),
                                        color: context.themePrimary,
                                        onPressed: () {
                                          final newQty = qty + 1;
                                          _cartService.updateQuantity(
                                            userId: _userId!,
                                            productId: productId,
                                            quantity: newQty,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '₹${lineTotal.toStringAsFixed(0)}',
                                    style: AppTypography.labelLarge()
                                        .copyWith(
                                          fontSize: 12,
                                          color: context.themeTextPrimary,
                                        ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      _cartService.updateQuantity(
                                        userId: _userId!,
                                        productId: productId,
                                        quantity: 0,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Remove',
                                      style: AppTypography.bodyMedium(),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: context.themeError,
                                      padding: const EdgeInsets.only(top: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Delivery address (optional)',
                      hintText: 'Site / shop address to show in order',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total',
                              style: AppTypography.bodyMedium().copyWith(
                                fontSize: 13,
                                color: context.themeTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${total.toStringAsFixed(0)}',
                              style: AppTypography.buttonMedium().copyWith(
                                fontSize: 18,
                                color: context.themePrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => _placeOrder(docs),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.themeSecondary,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          icon: const Icon(Icons.shopping_bag),
                          label: Text(
                            'Place Order (WhatsApp)',
                            style: AppTypography.buttonMedium(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Static shop details captured on each order for invoice/print.
  static const String _shopName = 'Sri Balaji Plywood & Hardware';
  static const String _shopAddress =
      '150 VCTV MAIN ROAD, Sathy Rd, opposite UNION BANK, Erode, Tamil Nadu 638001';
  static const String _shopGstNo = '33DFXPS5949H2ZH';
  static const String _shopEmail = 'sribalajihardwares1008@gmail.com';
  static const String _shopPhone = '9600609121';

  CollectionReference<Map<String, dynamic>> _cartItemsRef(String userId) {
    return _firestore.collection('carts').doc(userId).collection('items');
  }

  Future<void> addToCart({
    required String userId,
    required String productId,
    required String name,
    required double price,
    required String mainCategory,
    String? subCategory,
    String? imageUrl,
    int quantity = 1,
  }) async {
    final ref = _cartItemsRef(userId).doc(productId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        final existingQty = (data['quantity'] ?? 0) as int;
        tx.update(ref, {'quantity': existingQty + quantity});
      } else {
        tx.set(ref, {
          'productId': productId,
          'name': name,
          'price': price,
          'mainCategory': mainCategory,
          'subCategory': subCategory ?? '',
          'imageUrl': imageUrl ?? '',
          'quantity': quantity,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Watches the total quantity of items in the user's cart.
  Stream<int> watchCartCount(String userId) {
    return _cartItemsRef(userId).snapshots().map((snap) {
      var count = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final qty = (data['quantity'] ?? 0) as int;
        count += qty;
      }
      return count;
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCart(String userId) {
    return _cartItemsRef(userId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> updateQuantity({
    required String userId,
    required String productId,
    required int quantity,
  }) async {
    final ref = _cartItemsRef(userId).doc(productId);
    if (quantity <= 0) {
      await ref.delete();
    } else {
      await ref.update({'quantity': quantity});
    }
  }

  Future<void> clearCart(String userId) async {
    final snap = await _cartItemsRef(userId).get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  /// Creates an order from the user's cart and clears the cart.
  /// Returns a map with orderId, items, totalAmount.
  Future<Map<String, dynamic>?> placeOrder({
    required String userId,
    String? address,
  }) async {
    final cartSnap = await _cartItemsRef(userId).get();
    if (cartSnap.docs.isEmpty) return null;

    final items = <Map<String, dynamic>>[];
    double total = 0;

    for (final doc in cartSnap.docs) {
      final data = doc.data();
      final qty = (data['quantity'] ?? 0) as int;
      final price = (data['price'] ?? 0) as num;
      final lineTotal = qty * price.toDouble();
      total += lineTotal;
      items.add({
        'productId': data['productId'],
        'name': data['name'],
        'price': price.toDouble(),
        'quantity': qty,
        'mainCategory': data['mainCategory'],
        'subCategory': data['subCategory'],
        'imageUrl': data['imageUrl'],
        'lineTotal': lineTotal,
      });
    }

    // Fetch carpenter (user) details for order header
    String carpenterName = '';
    String carpenterPhone = '';
    try {
      final userDoc =
          await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      if (userData != null) {
        final firstName = userData['firstName'] as String? ?? '';
        final lastName = userData['lastName'] as String? ?? '';
        final fullName = '$firstName $lastName'.trim();
        carpenterName = fullName.isNotEmpty
            ? fullName
            : (userData['displayName'] as String? ?? '');
        carpenterPhone = userData['phone'] as String? ?? '';
      }
    } catch (_) {
      // ignore errors, keep defaults
    }

    final ordersRef = _firestore.collection('orders').doc();
    final orderId = ordersRef.id;

    await _firestore.runTransaction((tx) async {
      tx.set(ordersRef, {
        'orderId': orderId,
        'userId': userId,
        'items': items,
        'totalAmount': total,
        'address': address ?? '',
        'carpenterName': carpenterName,
        'carpenterPhone': carpenterPhone,
        'shopName': _shopName,
        'shopAddress': _shopAddress,
        'shopGstNo': _shopGstNo,
        'shopEmail': _shopEmail,
        'shopPhone': _shopPhone,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      for (final doc in cartSnap.docs) {
        tx.delete(doc.reference);
      }
    });

    return {
      'orderId': orderId,
      'items': items,
      'totalAmount': total,
    };
  }
}


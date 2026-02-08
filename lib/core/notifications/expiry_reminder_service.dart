import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

class ExpiryReminderService {
  ExpiryReminderService._();

  static final ExpiryReminderService instance = ExpiryReminderService._();

  StreamSubscription<QuerySnapshot>? _inventorySub;
  Timer? _debounceTimer;

  Future<void> startForUser(String uid) async {
    await refreshExpiryNotifications(uid);
    _inventorySub?.cancel();
    _inventorySub = FirebaseFirestore.instance
        .collection('artifacts')
        .doc('FreshBasket-app-v1')
        .collection('users')
        .doc(uid)
        .collection('inventory')
        .snapshots()
        .listen((_) => _debouncedRefresh(uid));
  }

  Future<void> stop() async {
    await _inventorySub?.cancel();
    _inventorySub = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  void _debouncedRefresh(String uid) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      refreshExpiryNotifications(uid);
    });
  }

  Future<void> refreshExpiryNotifications(String uid) async {
    try {
      await NotificationService.instance.cancelAll();

      final snapshot = await FirebaseFirestore.instance
          .collection('artifacts')
          .doc('FreshBasket-app-v1')
          .collection('users')
          .doc(uid)
          .collection('inventory')
          .get();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = (data['name'] as String?)?.trim();
        final ts = data['expiration_date'];
        if (name == null || name.isEmpty || ts is! Timestamp) continue;

        final expiry = ts.toDate();
        final expiryDate = DateTime(expiry.year, expiry.month, expiry.day);
        final daysLeft = expiryDate.difference(today).inDays;

        if (daysLeft == 0 || daysLeft == 1 || daysLeft == 3) {
          final suffix = daysLeft == 0
              ? 'today'
              : daysLeft == 1
                  ? 'tomorrow'
                  : 'in 3 days';

          await NotificationService.instance.showNow(
            id: doc.id.hashCode & 0x7fffffff,
            title: 'Expiring soon',
            body: '$name expires $suffix.',
          );
        }
      }
    } catch (e) {
      debugPrint('Expiry reminders refresh failed: $e');
    }
  }
}

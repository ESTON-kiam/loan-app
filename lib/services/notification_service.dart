import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize notification service
  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    }

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Get FCM token
    String? token = await _messaging.getToken();
    print('FCM Token: $token');
  }

  // Handle foreground notifications
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');
    
    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  // Handle background notifications
  void _handleBackgroundMessage(RemoteMessage message) {
    print('Background message: ${message.notification?.title}');
    // Navigate to specific screen based on notification data
  }

  // Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Navigate to specific screen
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'loan_app_channel',
      'Loan Notifications',
      channelDescription: 'Notifications for loan updates and payments',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Create notification in Firestore
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    final notification = NotificationModel(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
      data: data,
    );

    await _firestore
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toJson());

    // Also send push notification
    await _showLocalNotification(
      title: title,
      body: message,
      payload: notification.id,
    );
  }

  // Get user notifications
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => NotificationModel.fromJson(doc.data()))
        .toList();
  }

  // Get user notifications stream
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromJson(doc.data()))
            .toList());
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Get unread count
  Future<int> getUnreadCount(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }

  // Send notification for loan approval
  Future<void> sendLoanApprovalNotification({
    required String userId,
    required String loanId,
    required double amount,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Loan Approved! 🎉',
      message: 'Your loan application for KES ${amount.toStringAsFixed(2)} has been approved.',
      type: NotificationType.loanApproved,
      data: {'loanId': loanId},
    );
  }

  // Send notification for loan rejection
  Future<void> sendLoanRejectionNotification({
    required String userId,
    required String loanId,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Loan Application Update',
      message: 'Unfortunately, your loan application was not approved.',
      type: NotificationType.loanRejected,
      data: {'loanId': loanId},
    );
  }

  // Send notification for loan disbursement
  Future<void> sendLoanDisbursementNotification({
    required String userId,
    required String loanId,
    required double amount,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Loan Disbursed! 💰',
      message: 'KES ${amount.toStringAsFixed(2)} has been disbursed to your account.',
      type: NotificationType.loanDisbursed,
      data: {'loanId': loanId},
    );
  }

  // Send payment due reminder
  Future<void> sendPaymentDueNotification({
    required String userId,
    required String loanId,
    required double amount,
    required DateTime dueDate,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Payment Due Reminder 📅',
      message: 'Your payment of KES ${amount.toStringAsFixed(2)} is due soon.',
      type: NotificationType.paymentDue,
      data: {
        'loanId': loanId,
        'dueDate': dueDate.toIso8601String(),
      },
    );
  }

  // Send payment received confirmation
  Future<void> sendPaymentReceivedNotification({
    required String userId,
    required String loanId,
    required double amount,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Payment Received ✅',
      message: 'We have received your payment of KES ${amount.toStringAsFixed(2)}.',
      type: NotificationType.paymentReceived,
      data: {'loanId': loanId},
    );
  }

  // Send overdue payment notification
  Future<void> sendPaymentOverdueNotification({
    required String userId,
    required String loanId,
    required double amount,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Payment Overdue ⚠️',
      message: 'Your payment of KES ${amount.toStringAsFixed(2)} is overdue. Please make payment soon.',
      type: NotificationType.paymentOverdue,
      data: {'loanId': loanId},
    );
  }
}

// Background message handler (place at top level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
}

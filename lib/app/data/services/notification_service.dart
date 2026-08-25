import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/data/services/auth_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("📩 [FCM BACKGROUND MESSAGE] ID: ${message.messageId} | Data: ${message.data}");
}

class NotificationService extends GetxService {
  static NotificationService get to => Get.find();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? fcmToken;

  static const AndroidNotificationChannel _callChannel = AndroidNotificationChannel(
    'high_importance_call_channel',
    'Incoming Call Alerts',
    description: 'Channel used for high priority incoming call alerts.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel _chatChannel = AndroidNotificationChannel(
    'chat_messages_channel',
    'Chat Messages',
    description: 'Channel used for chat message notifications.',
    importance: Importance.high,
    playSound: true,
  );

  @override
  void onInit() {
    super.onInit();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    debugPrint("⚙️ [NOTIFICATION SERVICE INIT] 🚀 Starting NotificationService initialization...");

    // 1. Request Push Notification permissions (iOS & Android 13+)
    try {
      debugPrint("🔔 [FCM PERMISSION REQUEST] 🔑 Requesting FCM notification permissions...");
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint("✅ [FCM PERMISSION GRANTED] 🎯 Authorization Status: ${settings.authorizationStatus}");
    } catch (e) {
      debugPrint("❌ [FCM PERMISSION ERROR] ⚠️ Failed to request FCM permissions: $e");
    }

    // 2. Fetch and register FCM Token
    try {
      fcmToken = await _fcm.getToken();
      debugPrint("🔑 [FCM TOKEN FETCHED] 🎟️ Device Token: $fcmToken");
      _saveTokenToFirestore(fcmToken);
    } catch (e) {
      debugPrint("❌ [FCM TOKEN FETCH ERROR] ⚠️ $e");
    }

    // 3. Watch for token updates
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint("🔄 [FCM TOKEN REFRESHED] 🎟️ New Token: $newToken");
      fcmToken = newToken;
      _saveTokenToFirestore(newToken);
    });

    // 4. Initialize Local Notifications Plugin
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    final bool? initialized = await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("👇 [NOTIFICATION TAP DETECTED] 👆 Payload: ${response.payload}");
      },
    );
    debugPrint("📱 [LOCAL NOTIFICATIONS INIT] 🎉 Plugin Initialized Result: $initialized");

    // 5. Register Android Notification Channels & Request Android 13+ Permission
    final androidImpl = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      debugPrint("📢 [ANDROID NOTIFICATION CHANNELS] 📡 Creating high importance channels...");
      await androidImpl.createNotificationChannel(_callChannel);
      await androidImpl.createNotificationChannel(_chatChannel);
      debugPrint("✅ [ANDROID CHANNELS CREATED] 🔊 Call Channel ID: ${_callChannel.id} | Chat Channel ID: ${_chatChannel.id}");

      // Request runtime notification permission for Android 13+
      try {
        final granted = await androidImpl.requestNotificationsPermission();
        debugPrint("🔐 [ANDROID 13+ PERMISSION] 📱 Local notification permission granted: $granted");
      } catch (e) {
        debugPrint("⚠️ [ANDROID 13+ PERMISSION ERROR] $e");
      }
    }

    // 6. Listen to Foreground FCM Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📩 [FCM FOREGROUND MESSAGE RECEIVED] 📬 Title: '${message.notification?.title}', Body: '${message.notification?.body}', Data: ${message.data}");
      showLocalNotification(message);
    });

    // 7. Listen to App Opened via Notification Tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("🚀 [FCM MESSAGE OPENED APP] 📱 Opened from notification tap! Data: ${message.data}");
    });

    // 8. Auto sync FCM token & start incoming message listener on login
    ever(AuthService.to.currentUser, (user) {
      if (user != null) {
        debugPrint("👤 [AUTH EVENT] 🔓 Active user detected: ${user.userName} (${user.uid})");
        syncUserFcmToken(user.uid);
      }
    });

    if (AuthService.to.currentUser.value != null) {
      final user = AuthService.to.currentUser.value!;
      debugPrint("👤 [AUTH EXISTING] 🔓 User already logged in: ${user.userName} (${user.uid})");
      syncUserFcmToken(user.uid);
    }
  }

  StreamSubscription? _incomingMessageSub;

  // Save current FCM device token to Firestore under current user's document
  void _saveTokenToFirestore(String? token) async {
    final uid = AuthService.to.currentUser.value?.uid;
    if (uid != null && token != null && token.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint("💾 [FCM TOKEN STORED IN FIRESTORE] ✅ Saved token for UID: $uid");
      } catch (e) {
        debugPrint("❌ [FCM TOKEN STORE ERROR] ⚠️ $e");
      }
    }
  }

  final Map<String, StreamSubscription> _chatMessageSubs = {};

  // Listen to incoming real-time messages for the active user
  void listenToIncomingMessages(String myUid) {
    debugPrint("👂 [NOTIFICATION MESSAGE LISTENER] 🎧 Subscribing to chats for UID: $myUid");
    _incomingMessageSub?.cancel();
    _cancelMessageSubs();
    final startTime = DateTime.now();

    try {
      _incomingMessageSub = _firestore
          .collection('chats')
          .where('participants', arrayContains: myUid)
          .snapshots()
          .listen((chatsSnapshot) {
        debugPrint("🔥 [FIRESTORE CHATS SNAPSHOT] 📦 Active chats count: ${chatsSnapshot.docs.length}");
        for (var chatDoc in chatsSnapshot.docs) {
          final chatId = chatDoc.id;

          // Avoid duplicate listeners per chat
          if (_chatMessageSubs.containsKey(chatId)) continue;

          debugPrint("📡 [CHAT SUB] Listening to messages subcollection for chat: '$chatId'");
          _chatMessageSubs[chatId] = chatDoc.reference
              .collection('messages')
              .where('receiverId', isEqualTo: myUid)
              .snapshots()
              .listen((messagesSnapshot) {
            for (var change in messagesSnapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final data = change.doc.data();
                if (data == null) continue;

                final Timestamp? timestamp = data['timestamp'] as Timestamp?;
                final senderId = data['senderId'] ?? '';
                final text = data['text'] ?? 'Sent you a message';

                debugPrint("📩 [INCOMING MSG DATA] SenderId: $senderId | Text: '$text' | Timestamp: ${timestamp?.toDate()}");

                // Filter for newly arrived messages
                if (timestamp != null && timestamp.toDate().isAfter(startTime.subtract(const Duration(seconds: 5)))) {
                  debugPrint("🎉 [NOTIFICATION TRIGGER] 🔔 Displaying heads-up banner for sender: $senderId");
                  _firestore.collection('users').doc(senderId).get().then((doc) {
                    final senderName = doc.data()?['userName'] ?? 'StreamChat User';
                    showCustomNotification(
                      title: senderName,
                      body: text,
                      isCall: false,
                      data: {'type': 'message', 'senderId': senderId, 'chatId': chatId},
                    );
                  }).catchError((err) {
                    showCustomNotification(
                      title: "StreamChat",
                      body: text,
                      isCall: false,
                      data: {'type': 'message', 'senderId': senderId, 'chatId': chatId},
                    );
                  });
                } else {
                  debugPrint("⏳ [MSG SKIPPED] Older message (Timestamp: ${timestamp?.toDate()})");
                }
              }
            }
          }, onError: (err) {
            debugPrint("❌ [CHAT MESSAGES ERROR] ⚠️ Chat $chatId error: $err");
          });
        }
      }, onError: (error) {
        debugPrint("❌ [FIRESTORE CHATS LISTENER ERROR] ⚠️ $error");
      });
    } catch (e) {
      debugPrint("❌ [MESSAGE LISTENER EXCEPTION] 💥 $e");
    }
  }

  void _cancelMessageSubs() {
    for (var sub in _chatMessageSubs.values) {
      sub.cancel();
    }
    _chatMessageSubs.clear();
  }

  // Display Local Heads-Up Banner Notification
  void showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    final isCall = data['type'] == 'call';

    final title = notification?.title ?? data['title'] ?? (isCall ? 'Incoming Call' : 'New Message');
    final body = notification?.body ?? data['body'] ?? '';

    debugPrint("📱 [LOCAL NOTIFICATION DISPATCH] 📣 Title: '$title' | Body: '$body' | IsCall: $isCall");

    showCustomNotification(
      title: title,
      body: body,
      isCall: isCall,
      data: data,
    );
  }

  // Directly trigger system heads-up banner notification
  Future<void> showCustomNotification({
    required String title,
    required String body,
    bool isCall = false,
    Map<String, dynamic>? data,
  }) async {
    final channel = isCall ? _callChannel : _chatChannel;
    final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

    debugPrint("🔔 [SHOWING CUSTOM NOTIFICATION] 🚨 ID: $notificationId | Title: '$title' | Body: '$body' | Channel: ${channel.id}");

    try {
      await _localNotifications.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentSound: true,
            presentAlert: true,
            presentBadge: true,
          ),
        ),
        payload: jsonEncode(data ?? {}),
      );
      debugPrint("✅ [NOTIFICATION SHOWN SUCCESS] 🎉 System heads-up banner displayed for '$title'");
    } catch (e, stack) {
      debugPrint("❌ [NOTIFICATION DISPLAY ERROR] 💥 Failed to show notification: $e\n$stack");
    }
  }

  // Save token helper callable on login or user change
  void syncUserFcmToken(String uid) {
    debugPrint("🔄 [SYNC USER FCM TOKEN] 🎟️ Syncing token & starting listener for UID: $uid");
    if (fcmToken != null && fcmToken!.isNotEmpty) {
      _saveTokenToFirestore(fcmToken);
    }
    listenToIncomingMessages(uid);
  }

  @override
  void onClose() {
    _incomingMessageSub?.cancel();
    _cancelMessageSubs();
    super.onClose();
  }
}

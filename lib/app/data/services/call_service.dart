import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/data/models/call_model.dart';
import 'package:stream_chat/app/data/models/user_model.dart';
import 'package:stream_chat/app/data/services/auth_service.dart';
import 'package:stream_chat/app/modules/call/controllers/call_controller.dart';
import 'package:stream_chat/app/routes/app_pages.dart';
import 'package:stream_chat/const.dart';

class CallService extends GetxService {
  static CallService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _incomingCallSub;

  @override
  void onInit() {
    super.onInit();
    debugPrint("⚙️ [CALL SERVICE INIT] Initializing CallService...");
    ever(AuthService.to.currentUser, (UserModel? user) {
      if (user != null) {
        debugPrint("👤 [CALL SERVICE USER] Active user logged in: ${user.userName} (${user.uid})");
        _listenToIncomingCalls(user.uid);
      } else {
        debugPrint("🚪 [CALL SERVICE USER] User logged out, stopping incoming call listener.");
        _incomingCallSub?.cancel();
        _incomingCallSub = null;
      }
    });

    if (AuthService.to.currentUser.value != null) {
      _listenToIncomingCalls(AuthService.to.currentUser.value!.uid);
    }
  }

  void _listenToIncomingCalls(String myUid) {
    debugPrint("📡 [CALL SERVICE LISTEN] Subscribing to incoming calls for UID: $myUid");
    _incomingCallSub?.cancel();
    _incomingCallSub = _firestore
        .collection('calls')
        .where('receiverId', isEqualTo: myUid)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final call = CallModel.fromMap(doc.data(), doc.id);
        debugPrint("🔔 [CALL SERVICE INCOMING] Call received! From: ${call.callerName} | CallType: ${call.callType} | Doc: ${call.docId}");

        if (Get.currentRoute != Routes.CALL) {
          debugPrint("🚀 [CALL SERVICE NAVIGATE] Navigating to CallView for incoming call...");
          final callerUser = UserModel(
            uid: call.callerId,
            userName: call.callerName,
            email: '',
            imgUrl: call.callerPic,
          );

          Get.toNamed(
            Routes.CALL,
            arguments: {
              'channelId': call.channelId,
              'callType': call.callType,
              'targetUser': callerUser,
              'isIncoming': true,
              'callDocId': call.docId,
            },
          );
        }
      }
    });
  }

  Future<CallModel?> makeCall({
    required UserModel receiver,
    required CallType callType,
    required String channelId,
  }) async {
    final caller = AuthService.to.currentUser.value;
    if (caller == null) {
      debugPrint("❌ [CALL SERVICE MAKE] Failed: Current user is null!");
      return null;
    }

    final docId = "${caller.uid}_${receiver.uid}";
    debugPrint("📲 [CALL SERVICE MAKE] Creating Call Document: '$docId' from ${caller.userName} to ${receiver.userName}...");
    final call = CallModel(
      docId: docId,
      callerId: caller.uid,
      callerName: caller.userName,
      callerPic: caller.imgUrl,
      receiverId: receiver.uid,
      receiverName: receiver.userName,
      receiverPic: receiver.imgUrl,
      channelId: channelId,
      token: agoraToken,
      callType: callType,
      status: 'ringing',
    );

    await _firestore.collection('calls').doc(docId).set(call.toMap());
    debugPrint("✅ [CALL SERVICE MAKE] Call document successfully created in Firestore!");
    return call;
  }

  Future<void> acceptCall(String docId) async {
    try {
      debugPrint("✅ [CALL SERVICE ACCEPT] Updating call '$docId' status to 'accepted'");
      await _firestore.collection('calls').doc(docId).update({
        'status': 'accepted',
      });
    } catch (e) {
      debugPrint("❌ [CALL SERVICE ACCEPT ERROR] $e");
    }
  }

  Future<void> declineCall(String docId) async {
    try {
      debugPrint("🚫 [CALL SERVICE DECLINE] Updating call '$docId' status to 'declined'");
      await _firestore.collection('calls').doc(docId).update({
        'status': 'declined',
      });
    } catch (e) {
      debugPrint("❌ [CALL SERVICE DECLINE ERROR] $e");
    }
  }

  Future<void> endCall(String docId) async {
    try {
      debugPrint("🔴 [CALL SERVICE END] Updating call '$docId' status to 'ended'");
      await _firestore.collection('calls').doc(docId).update({
        'status': 'ended',
      });
    } catch (e) {
      debugPrint("❌ [CALL SERVICE END ERROR] $e");
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> listenToCall(String docId) {
    return _firestore.collection('calls').doc(docId).snapshots();
  }

  @override
  void onClose() {
    debugPrint("🧹 [CALL SERVICE CLOSE] Cancelling incoming call subscription.");
    _incomingCallSub?.cancel();
    super.onClose();
  }
}

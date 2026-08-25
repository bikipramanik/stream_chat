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
  // Global getter shortcut to easily access CallService anywhere via `CallService.to`
  static CallService get to => Get.find();

  // Instance of Firebase Firestore to interact with the database
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Holds the active subscription handle for listening to incoming calls in Firestore
  StreamSubscription<QuerySnapshot>? _incomingCallSub;

  @override
  void onInit() {
    super.onInit();
    debugPrint("⚙️ [CALL SERVICE INIT] Initializing CallService...");

    // Reactively watch for changes in currentUser (log in / log out events)
    ever(AuthService.to.currentUser, (UserModel? user) {
      if (user != null) {
        // If a user logs in, start listening for incoming calls for their user ID
        debugPrint("👤 [CALL SERVICE USER] Active user logged in: ${user.userName} (${user.uid})");
        _listenToIncomingCalls(user.uid);
      } else {
        // If user logs out, stop and cancel the active incoming call listener
        debugPrint("🚪 [CALL SERVICE USER] User logged out, stopping incoming call listener.");
        _incomingCallSub?.cancel();
        _incomingCallSub = null;
      }
    });

    // If a user is already logged in when the app starts, immediately start listening for calls
    if (AuthService.to.currentUser.value != null) {
      _listenToIncomingCalls(AuthService.to.currentUser.value!.uid);
    }
  }

  // Starts listening to Firestore for incoming calls matching the current user's UID
  void _listenToIncomingCalls(String myUid) {
    debugPrint("📡 [CALL SERVICE LISTEN] Subscribing to incoming calls for UID: $myUid");
    
    // Cancel any previous active listener to avoid duplicate subscriptions
    _incomingCallSub?.cancel();
    
    // Listen in real-time to the 'calls' collection where receiverId is my UID and status is 'ringing'
    _incomingCallSub = _firestore
        .collection('calls')
        .where('receiverId', isEqualTo: myUid)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
      // Check if there are any incoming call documents found
      if (snapshot.docs.isNotEmpty) {
        // Get the first incoming call document
        final doc = snapshot.docs.first;
        // Convert the Firestore document data into a CallModel object
        final call = CallModel.fromMap(doc.data(), doc.id);
        debugPrint("🔔 [CALL SERVICE INCOMING] Call received! From: ${call.callerName} | CallType: ${call.callType} | Doc: ${call.docId}");

        // Only navigate to Call screen if the user is not already on the Call screen
        if (Get.currentRoute != Routes.CALL) {
          debugPrint("🚀 [CALL SERVICE NAVIGATE] Navigating to CallView for incoming call...");
          
          // Create a UserModel object for the person calling us
          final callerUser = UserModel(
            uid: call.callerId,
            userName: call.callerName,
            email: '',
            imgUrl: call.callerPic,
          );

          // Open the CallView screen and pass call data as arguments
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

  // Function to make a new outgoing audio/video call to a receiver user
  Future<CallModel?> makeCall({
    required UserModel receiver,
    required CallType callType,
    required String channelId,
  }) async {
    // Get the currently logged-in caller user details
    final caller = AuthService.to.currentUser.value;
    if (caller == null) {
      debugPrint("❌ [CALL SERVICE MAKE] Failed: Current user is null!");
      return null;
    }

    // Create a unique document ID for each call log entry
    final docId = _firestore.collection('calls').doc().id;
    debugPrint("📲 [CALL SERVICE MAKE] Creating Call Document: '$docId' from ${caller.userName} to ${receiver.userName}...");
    
    // Construct the CallModel data object
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
      status: 'ringing', // Initial call state is 'ringing'
    );

    // Save the call document into Firestore 'calls' collection
    await _firestore.collection('calls').doc(docId).set(call.toMap());
    debugPrint("✅ [CALL SERVICE MAKE] Call document successfully created in Firestore!");
    return call;
  }

  // Updates the call document status in Firestore to 'accepted' when receiver picks up
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

  // Updates the call document status in Firestore to 'declined' when receiver declines
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

  // Updates the call document status in Firestore to 'ended' when either user hangs up
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

  // Listens real-time to a specific call document to watch for status changes (accepted/ended/declined)
  Stream<DocumentSnapshot<Map<String, dynamic>>> listenToCall(String docId) {
    return _firestore.collection('calls').doc(docId).snapshots();
  }

  // Get real-time stream of all calls involving the specified user ID (sorted newest first)
  Stream<List<CallModel>> getCallHistoryStream(String myUid) {
    return _firestore
        .collection('calls')
        .snapshots()
        .map((snapshot) {
      final calls = snapshot.docs
          .map((doc) => CallModel.fromMap(doc.data(), doc.id))
          .where((call) => call.callerId == myUid || call.receiverId == myUid)
          .toList();
      // Sort newest call first
      calls.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return calls;
    });
  }

  // Delete a specific call history item from Firestore
  Future<void> deleteCallHistoryItem(String docId) async {
    try {
      await _firestore.collection('calls').doc(docId).delete();
      debugPrint("🗑️ [CALL SERVICE DELETE] Deleted call log docId: $docId");
    } catch (e) {
      debugPrint("❌ [CALL SERVICE DELETE ERROR] $e");
    }
  }

  // Clear all call history records for current user
  Future<void> clearCallHistory(String myUid) async {
    try {
      final snapshot = await _firestore.collection('calls').get();
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['callerId'] == myUid || data['receiverId'] == myUid) {
          batch.delete(doc.reference);
        }
      }
      await batch.commit();
      debugPrint("🧹 [CALL SERVICE CLEAR] Cleared all call logs for $myUid");
    } catch (e) {
      debugPrint("❌ [CALL SERVICE CLEAR ERROR] $e");
    }
  }

  // Called automatically by GetX when CallService is disposed to clean up resources
  @override
  void onClose() {
    debugPrint("🧹 [CALL SERVICE CLOSE] Cancelling incoming call subscription.");
    // Cancel the Firestore incoming call subscription to prevent memory leaks
    _incomingCallSub?.cancel();
    super.onClose();
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/data/models/call_model.dart';
import 'package:stream_chat/app/data/models/user_model.dart';
import 'package:stream_chat/app/data/services/auth_service.dart';
import 'package:stream_chat/app/data/services/call_service.dart';
import 'package:stream_chat/app/modules/call/controllers/call_controller.dart';
import 'package:stream_chat/app/routes/app_pages.dart';
import 'package:stream_chat/app/theme/app_theme.dart';

enum HistoryFilter { all, missed }

class CallHistoryController extends GetxController {
  final selectedFilter = HistoryFilter.all.obs;
  final searchQuery = ''.obs;
  final searchController = TextEditingController();

  UserModel? get currentUser => AuthService.to.currentUser.value;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchQuery.value = searchController.text.trim();
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Stream<List<CallModel>> getCallHistoryStream() {
    final uid = currentUser?.uid ?? '';
    if (uid.isEmpty) return Stream.value([]);
    return CallService.to.getCallHistoryStream(uid);
  }

  List<CallModel> filterCallLogs(List<CallModel> logs) {
    final uid = currentUser?.uid ?? '';
    return logs.where((call) {
      final isOutgoing = call.callerId == uid;
      final targetName = isOutgoing ? call.receiverName : call.callerName;

      // Filter by search query
      if (searchQuery.isNotEmpty) {
        if (!targetName.toLowerCase().contains(searchQuery.value.toLowerCase())) {
          return false;
        }
      }

      // Filter by tab selection
      if (selectedFilter.value == HistoryFilter.missed) {
        // Missed call = incoming call that was declined or not accepted ('ringing'/'declined')
        return !isOutgoing && (call.status == 'declined' || call.status == 'ringing');
      }

      return true;
    }).toList();
  }

  Future<void> initiateCallBack(CallModel call, CallType type) async {
    final uid = currentUser?.uid ?? '';
    final isOutgoing = call.callerId == uid;

    final targetUid = isOutgoing ? call.receiverId : call.callerId;
    final targetName = isOutgoing ? call.receiverName : call.callerName;
    final targetPic = isOutgoing ? call.receiverPic : call.callerPic;

    final targetUser = UserModel(
      uid: targetUid,
      userName: targetName,
      email: '',
      imgUrl: targetPic,
    );

    final currentUid = currentUser?.uid ?? 'user1';
    final uids = [currentUid, targetUid]..sort();
    final channelId = "call_${uids[0]}_${uids[1]}";

    final callModel = await CallService.to.makeCall(
      receiver: targetUser,
      callType: type,
      channelId: channelId,
    );

    Get.toNamed(
      Routes.CALL,
      arguments: {
        'channelId': channelId,
        'callType': type,
        'targetUser': targetUser,
        'isIncoming': false,
        'callDocId': callModel?.docId ?? "${currentUid}_$targetUid",
      },
    );
  }

  Future<void> deleteLog(String docId) async {
    await CallService.to.deleteCallHistoryItem(docId);
    Get.snackbar(
      "Call Log Removed",
      "Selected call history record deleted.",
      backgroundColor: AppTheme.surfaceColor,
      colorText: AppTheme.textPrimary,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> clearAllLogs() async {
    final uid = currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    Get.dialog(
      AlertDialog(
        title: const Text("Clear Call History"),
        content: const Text("Are you sure you want to delete all call logs? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Get.back();
              await CallService.to.clearCallHistory(uid);
              Get.snackbar(
                "History Cleared",
                "All call logs have been deleted.",
                backgroundColor: AppTheme.surfaceColor,
                colorText: AppTheme.textPrimary,
              );
            },
            child: const Text("Clear All"),
          ),
        ],
      ),
    );
  }
}

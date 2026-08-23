import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stream_chat/app/modules/call/controllers/call_controller.dart';

class CallModel {
  final String docId;
  final String callerId;
  final String callerName;
  final String callerPic;
  final String receiverId;
  final String receiverName;
  final String receiverPic;
  final String channelId;
  final String token;
  final CallType callType;
  final String status; // 'ringing', 'accepted', 'declined', 'ended'
  final DateTime? createdAt;

  CallModel({
    required this.docId,
    required this.callerId,
    required this.callerName,
    required this.callerPic,
    required this.receiverId,
    required this.receiverName,
    required this.receiverPic,
    required this.channelId,
    required this.token,
    required this.callType,
    required this.status,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'docId': docId,
      'callerId': callerId,
      'callerName': callerName,
      'callerPic': callerPic,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverPic': receiverPic,
      'channelId': channelId,
      'token': token,
      'callType': callType == CallType.video ? 'video' : 'audio',
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory CallModel.fromMap(Map<String, dynamic> data, String id) {
    return CallModel(
      docId: id,
      callerId: data['callerId'] ?? '',
      callerName: data['callerName'] ?? 'Unknown Caller',
      callerPic: data['callerPic'] ?? '',
      receiverId: data['receiverId'] ?? '',
      receiverName: data['receiverName'] ?? 'Unknown Receiver',
      receiverPic: data['receiverPic'] ?? '',
      channelId: data['channelId'] ?? '',
      token: data['token'] ?? '',
      callType: data['callType'] == 'video' ? CallType.video : CallType.audio,
      status: data['status'] ?? 'ringing',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

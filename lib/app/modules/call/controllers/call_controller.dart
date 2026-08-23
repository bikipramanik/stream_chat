import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stream_chat/app/data/models/user_model.dart';
import 'package:stream_chat/app/data/services/auth_service.dart';
import 'package:stream_chat/const.dart';

enum CallType { audio, video }
enum CallState { incoming, outgoing, connected, ended }

class CallController extends GetxController {
  late final String channelId;
  late final CallType callType;
  late final UserModel targetUser;
  late final bool isIncomingCall;

  final callState = CallState.outgoing.obs;
  final callSeconds = 0.obs;
  Timer? _timer;

  RtcEngine? rtcEngine;
  final isEngineInitialized = false.obs;

  final isMuted = false.obs;
  final isVideoEnabled = true.obs;
  final isSpeakerOn = true.obs;
  final isFrontCamera = true.obs;

  final localUid = 0.obs;
  final remoteUid = RxnInt();

  UserModel? get currentUser => AuthService.to.currentUser.value;

  String get formattedDuration {
    final minutes = (callSeconds.value ~/ 60).toString().padLeft(2, '0');
    final seconds = (callSeconds.value % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  String get statusText {
    switch (callState.value) {
      case CallState.incoming:
        return "Incoming ${callType == CallType.video ? 'Video' : 'Audio'} Call...";
      case CallState.outgoing:
        return "Connecting...";
      case CallState.connected:
        return formattedDuration;
      case CallState.ended:
        return "Call Ended";
    }
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    
    channelId = args['channelId'] ?? 'test_channel';
    callType = args['callType'] as CallType? ?? CallType.video;
    targetUser = args['targetUser'] as UserModel? ??
        UserModel(
          uid: 'unknown',
          userName: 'Unknown User',
          email: 'unknown@email.com',
          imgUrl: '',
        );
    isIncomingCall = args['isIncoming'] as bool? ?? false;

    isVideoEnabled.value = (callType == CallType.video);

    if (isIncomingCall) {
      callState.value = CallState.incoming;
    } else {
      callState.value = CallState.outgoing;
      _initAgoraEngineAndJoin();
    }
  }

  Future<void> acceptCall() async {
    callState.value = CallState.outgoing;
    await _initAgoraEngineAndJoin();
  }

  Future<void> _initAgoraEngineAndJoin() async {
    try {
      // Request Camera & Mic permissions
      final statuses = await [
        Permission.microphone,
        Permission.camera,
      ].request();

      if (statuses[Permission.microphone] != PermissionStatus.granted) {
        Get.log("Microphone permission denied");
      }

      // Initialize Agora RtcEngine
      final engine = createAgoraRtcEngine();
      await engine.initialize(const RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));
      rtcEngine = engine;

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            Get.log("Agora local joined channel: ${connection.channelId}");
            localUid.value = connection.localUid ?? 0;
            if (remoteUid.value != null) {
              _startCallTimer();
              callState.value = CallState.connected;
            }
          },
          onUserJoined: (RtcConnection connection, int remoteUidParam, int elapsed) {
            Get.log("Agora remote user joined: $remoteUidParam");
            remoteUid.value = remoteUidParam;
            _startCallTimer();
            callState.value = CallState.connected;
          },
          onUserOffline:
              (RtcConnection connection, int remoteUidParam, UserOfflineReasonType reason) {
            Get.log("Agora remote user left: $remoteUidParam");
            remoteUid.value = null;
            endCall();
          },
          onError: (ErrorCodeType err, String msg) {
            Get.log("Agora Error [$err]: $msg");
          },
        ),
      );

      if (callType == CallType.video) {
        await engine.enableVideo();
        await engine.startPreview();
      } else {
        await engine.enableAudio();
      }

      await engine.joinChannel(
        token: '',
        channelId: channelId,
        uid: 0,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishCameraTrack: callType == CallType.video,
          publishMicrophoneTrack: true,
        ),
      );

      isEngineInitialized.value = true;
    } catch (e) {
      Get.log("Error initializing Agora: $e");
    }
  }

  void _startCallTimer() {
    if (_timer != null) return;
    callSeconds.value = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      callSeconds.value++;
    });
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
    rtcEngine?.muteLocalAudioStream(isMuted.value);
  }

  void toggleVideo() {
    if (callType != CallType.video) return;
    isVideoEnabled.value = !isVideoEnabled.value;
    rtcEngine?.muteLocalVideoStream(!isVideoEnabled.value);
  }

  void switchCamera() {
    if (callType != CallType.video) return;
    isFrontCamera.value = !isFrontCamera.value;
    rtcEngine?.switchCamera();
  }

  void toggleSpeaker() {
    isSpeakerOn.value = !isSpeakerOn.value;
    rtcEngine?.setEnableSpeakerphone(isSpeakerOn.value);
  }

  void endCall() {
    if (callState.value == CallState.ended) return;
    callState.value = CallState.ended;
    _timer?.cancel();
    _timer = null;

    try {
      rtcEngine?.leaveChannel();
      rtcEngine?.release();
      rtcEngine = null;
    } catch (e) {
      Get.log("Error leaving channel: $e");
    }

    Get.back();
  }

  @override
  void onClose() {
    _timer?.cancel();
    try {
      rtcEngine?.leaveChannel();
      rtcEngine?.release();
    } catch (_) {}
    super.onClose();
  }
}

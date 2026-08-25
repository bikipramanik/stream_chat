import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stream_chat/app/data/models/user_model.dart';
import 'package:stream_chat/app/data/services/auth_service.dart';
import 'package:stream_chat/app/data/services/call_service.dart';
import 'package:stream_chat/const.dart';

enum CallType { audio, video }
enum CallState { incoming, outgoing, connected, ended }

class CallController extends GetxController {
  late final String channelId;
  late final CallType callType;
  late final UserModel targetUser;
  late final bool isIncomingCall;
  late final String callDocId;

  final callState = CallState.outgoing.obs;
  final callSeconds = 0.obs;
  Timer? _timer;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _callDocSub;

  final AudioPlayer _ringtonePlayer = AudioPlayer();

  RtcEngine? rtcEngine;
  final isEngineInitialized = false.obs;

  final isMuted = false.obs;
  final isVideoEnabled = true.obs;
  final isSpeakerOn = true.obs;
  final isFrontCamera = true.obs;

  final localUid = 0.obs;
  final remoteUid = RxnInt();

  UserModel? get currentUser => AuthService.to.currentUser.value;
  String get activeChannelId => channelName.isNotEmpty ? channelName : channelId;

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
        return "Ringing...";
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
    callDocId = args['callDocId'] ??
        (isIncomingCall
            ? "${targetUser.uid}_${currentUser?.uid ?? 'me'}"
            : "${currentUser?.uid ?? 'me'}_${targetUser.uid}");

    isVideoEnabled.value = (callType == CallType.video);

    debugPrint("🎬 [CALL INIT] CallType: $callType | Target: ${targetUser.userName} | Incoming: $isIncomingCall | DocID: $callDocId");

    _listenToCallDoc();

    if (isIncomingCall) {
      callState.value = CallState.incoming;
      debugPrint("🔔 [CALL STATE] Set to INCOMING");
      _playRingtone(isIncoming: true);
    } else {
      callState.value = CallState.outgoing;
      debugPrint("📞 [CALL STATE] Set to OUTGOING (Connecting...)");
      _playRingtone(isIncoming: false);
      _initAgoraEngineAndJoin();
    }
  }

  Future<void> _playRingtone({required bool isIncoming}) async {
    try {
      await _ringtonePlayer.stop();
      await _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
      
      // Clean phone ringing sound preview URL
      final url = isIncoming
          ? 'https://assets.mixkit.co/active_storage/sfx/1359/1359-preview.mp3'
          : 'https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3';

      debugPrint("🔔 [RINGTONE] Playing ringtone audio (Incoming: $isIncoming): $url");
      await _ringtonePlayer.play(UrlSource(url));
    } catch (e) {
      debugPrint("⚠️ [RINGTONE ERROR] Failed to play ringtone: $e");
    }
  }

  Future<void> _stopRingtone() async {
    try {
      debugPrint("🔕 [RINGTONE] Stopping ringtone audio.");
      await _ringtonePlayer.stop();
    } catch (e) {
      debugPrint("⚠️ [RINGTONE STOP ERROR] $e");
    }
  }

  void _listenToCallDoc() {
    debugPrint("👂 [CALL FIRESTORE] Listening to call document: $callDocId");
    _callDocSub = CallService.to.listenToCall(callDocId).listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final status = snapshot.data()!['status'];
        debugPrint("🔥 [CALL FIRESTORE UPDATE] Status is now: '$status'");
        if (status == 'declined' || status == 'ended') {
          debugPrint("🚫 [CALL FIRESTORE] Call was declined or ended remotely.");
          _stopRingtone();
          endCall(updateFirestore: false);
        } else if (status == 'accepted' && callState.value == CallState.outgoing) {
          debugPrint("✅ [CALL FIRESTORE] Remote user accepted the call!");
          _stopRingtone();
          _startCallTimer();
          callState.value = CallState.connected;
        }
      }
    });
  }

  Future<void> acceptCall() async {
    debugPrint("🟢 [CALL ACTION] Accept Call pressed by recipient");
    _stopRingtone();
    callState.value = CallState.outgoing;
    await CallService.to.acceptCall(callDocId);
    await _initAgoraEngineAndJoin();
  }

  Future<void> _initAgoraEngineAndJoin() async {
    try {
      debugPrint("🔐 [AGORA PERMISSIONS] Requesting Camera & Microphone permissions...");
      final statuses = await [
        Permission.microphone,
        Permission.camera,
      ].request();

      debugPrint("🎙️ Mic status: ${statuses[Permission.microphone]} | 📷 Camera status: ${statuses[Permission.camera]}");

      debugPrint("🚀 [AGORA INIT] Creating RtcEngine with AppId: $agoraAppId");
      final engine = createAgoraRtcEngine();
      await engine.initialize(const RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));
      rtcEngine = engine;

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("🟢 [AGORA SUCCESS] Local user joined channel! Channel: '${connection.channelId}', Local UID: ${connection.localUid}, Elapsed: ${elapsed}ms");
            localUid.value = connection.localUid ?? 0;

            // Enable speakerphone safely once joined
            try {
              rtcEngine?.setEnableSpeakerphone(true);
              isSpeakerOn.value = true;
            } catch (e) {
              debugPrint("⚠️ [AGORA SPEAKER ON JOIN ERROR] $e");
            }

            // Only start timer if remote user is already connected
            if (remoteUid.value != null) {
              callState.value = CallState.connected;
              _startCallTimer(reset: true);
            }
          },
          onUserJoined: (RtcConnection connection, int remoteUidParam, int elapsed) {
            debugPrint("🎉 [AGORA REMOTE JOINED] Remote UID: $remoteUidParam joined channel '${connection.channelId}' after ${elapsed}ms!");
            remoteUid.value = remoteUidParam;
            callState.value = CallState.connected;
            _stopRingtone();
            _startCallTimer(reset: true);
          },
          onUserOffline:
              (RtcConnection connection, int remoteUidParam, UserOfflineReasonType reason) {
            debugPrint("👋 [AGORA REMOTE LEFT] Remote UID: $remoteUidParam left channel. Reason: $reason");
            remoteUid.value = null;
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint("❌ [AGORA ERROR] Code: $err, Message: $msg");
          },
          onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
            debugPrint("🔄 [AGORA CONNECTION STATE] State: $state, Reason: $reason");
          },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            debugPrint("⚠️ [AGORA WARNING] Token privilege will expire soon!");
          },
        ),
      );

      if (callType == CallType.video) {
        debugPrint("📹 [AGORA MEDIA] Enabling Video & Starting Local Preview...");
        await engine.enableVideo();
        await engine.startPreview();
      } else {
        debugPrint("🎙️ [AGORA MEDIA] Enabling Audio Mode...");
        await engine.enableAudio();
      }

      // Default audio routing to speakerphone
      try {
        await engine.setDefaultAudioRouteToSpeakerphone(true);
      } catch (e) {
        debugPrint("⚠️ [AGORA AUDIO ROUTE ERROR] $e");
      }

      final tokenToUse = agoraToken.isNotEmpty ? agoraToken : '';
      final channelToJoin = activeChannelId;
      
      // Each user MUST have a unique integer UID in an Agora channel for audio/video to route properly!
      final uidToUse = currentUser != null
          ? (currentUser!.uid.hashCode & 0x3FFFFFFF)
          : (DateTime.now().millisecondsSinceEpoch % 100000 + 1);

      debugPrint("📡 [AGORA JOIN] Joining Channel '$channelToJoin' with Unique UID: $uidToUse...");
      await engine.joinChannel(
        token: tokenToUse,
        channelId: channelToJoin,
        uid: uidToUse,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishCameraTrack: callType == CallType.video,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: callType == CallType.video,
        ),
      );

      isEngineInitialized.value = true;
      debugPrint("✨ [AGORA INIT COMPLETE] Engine initialized successfully.");
    } catch (e, stack) {
      debugPrint("💥 [AGORA INIT EXCEPTION] Error: $e\n$stack");
    }
  }

  void _startCallTimer({bool reset = false}) {
    if (reset || _timer == null) {
      _timer?.cancel();
      callSeconds.value = 0;
      debugPrint("⏱️ [CALL TIMER] Starting minute/second call duration timer from 00:00.");
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        callSeconds.value++;
      });
    }
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
    debugPrint("🎙️ [CALL ACTION] Mic Muted: ${isMuted.value}");
    rtcEngine?.muteLocalAudioStream(isMuted.value);
  }

  void toggleVideo() {
    if (callType != CallType.video) return;
    isVideoEnabled.value = !isVideoEnabled.value;
    debugPrint("📷 [CALL ACTION] Video Enabled: ${isVideoEnabled.value}");
    rtcEngine?.muteLocalVideoStream(!isVideoEnabled.value);
  }

  void switchCamera() {
    if (callType != CallType.video) return;
    isFrontCamera.value = !isFrontCamera.value;
    debugPrint("🔄 [CALL ACTION] Switch Camera to ${isFrontCamera.value ? 'Front' : 'Rear'}");
    rtcEngine?.switchCamera();
  }

  void toggleSpeaker() {
    isSpeakerOn.value = !isSpeakerOn.value;
    debugPrint("🔊 [CALL ACTION] Speaker On: ${isSpeakerOn.value}");
    try {
      rtcEngine?.setEnableSpeakerphone(isSpeakerOn.value);
    } catch (e) {
      debugPrint("⚠️ [AGORA SPEAKER TOGGLE ERROR] $e");
    }
  }

  void endCall({bool updateFirestore = true}) {
    if (callState.value == CallState.ended) return;
    debugPrint("🔴 [CALL END] Ending Call. Update Firestore: $updateFirestore");
    callState.value = CallState.ended;
    _stopRingtone();
    _timer?.cancel();
    _timer = null;
    _callDocSub?.cancel();

    if (updateFirestore) {
      CallService.to.endCall(callDocId);
    }

    try {
      rtcEngine?.leaveChannel();
      rtcEngine?.release();
      rtcEngine = null;
      debugPrint("🧹 [AGORA CLEANUP] Left channel and released engine.");
    } catch (e) {
      debugPrint("⚠️ [AGORA CLEANUP ERROR] $e");
    }

    Get.back();
  }

  @override
  void onClose() {
    debugPrint("🚪 [CALL CONTROLLER CLOSE] Cleaning up resources.");
    _stopRingtone();
    _ringtonePlayer.dispose();
    _timer?.cancel();
    _callDocSub?.cancel();
    try {
      rtcEngine?.leaveChannel();
      rtcEngine?.release();
    } catch (_) {}
    super.onClose();
  }
}

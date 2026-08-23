import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/modules/call/controllers/call_controller.dart';
import 'package:stream_chat/app/theme/app_theme.dart';

class CallView extends GetView<CallController> {
  const CallView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Obx(() {
          final callState = controller.callState.value;
          final isVideoCall = controller.callType == CallType.video;
          final isConnected = callState == CallState.connected;
          final isIncoming = callState == CallState.incoming;

          return Stack(
            children: [
              // 1. Background / Video View Layer
              Positioned.fill(
                child: isVideoCall && isConnected && controller.isEngineInitialized.value
                    ? _buildVideoLayer()
                    : _buildAudioOrConnectingBackground(),
              ),

              // Gradient Dark Overlay for contrast
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // 2. Top Header Bar (Call Type, Status/Timer, Logged-in Account)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    // Call Type & Status Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          onPressed: () => controller.endCall(),
                        ),

                        // Call Type Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isVideoCall ? Icons.videocam_rounded : Icons.phone_rounded,
                                color: AppTheme.primaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isVideoCall ? "HD Video Call" : "Audio Call",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 40), // Balance top bar spacing
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Call Status / Minute Count Timer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        controller.statusText,
                        style: TextStyle(
                          fontSize: isConnected ? 22 : 16,
                          fontWeight: isConnected ? FontWeight.bold : FontWeight.w500,
                          color: isConnected ? Colors.greenAccent : Colors.white70,
                          letterSpacing: isConnected ? 1.2 : 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Logged-in Account Info Badge
                    if (controller.currentUser != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_circle_outlined, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              "Logged in as: @${controller.currentUser!.userName}",
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // 3. Center Showcase (Target Caller / User Info when non-video or connecting)
              if (!isConnected || !isVideoCall)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Target User Avatar
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ripple animation background ring
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryColor.withValues(alpha: 0.15),
                            ),
                          ),
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.surfaceColorLight,
                            backgroundImage: controller.targetUser.imgUrl.isNotEmpty
                                ? NetworkImage(controller.targetUser.imgUrl)
                                : null,
                            child: controller.targetUser.imgUrl.isEmpty
                                ? const Icon(Icons.person_rounded, size: 50, color: Colors.white70)
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Target Username
                      Text(
                        controller.targetUser.userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Target Email
                      Text(
                        controller.targetUser.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

              // 4. Floating Local Camera View (PIP) for Video Calls
              if (isVideoCall && isConnected && controller.isEngineInitialized.value)
                Positioned(
                  right: 16,
                  bottom: 120,
                  width: 110,
                  height: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.6), width: 2),
                      ),
                      child: controller.rtcEngine != null
                          ? AgoraVideoView(
                              controller: VideoViewController(
                                rtcEngine: controller.rtcEngine!,
                                canvas: const VideoCanvas(uid: 0),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),

              // 5. Bottom Action Controls (Pickup, End Call, Mute, Video, Speaker)
              Positioned(
                left: 0,
                right: 0,
                bottom: 30,
                child: isIncoming
                    ? _buildIncomingCallControls()
                    : _buildActiveCallControls(isVideoCall),
              ),
            ],
          );
        }),
      ),
    );
  }

  // Build Fullscreen Remote Video View Layer
  Widget _buildVideoLayer() {
    final remoteUid = controller.remoteUid.value;
    final rtcEngine = controller.rtcEngine;

    if (rtcEngine != null && remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: rtcEngine,
          canvas: VideoCanvas(uid: remoteUid),
          connection: RtcConnection(channelId: controller.activeChannelId),
        ),
      );
    }

    return _buildAudioOrConnectingBackground();
  }

  // Build Dark Background with Subtle Glow for Audio or Connecting states
  Widget _buildAudioOrConnectingBackground() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Icon(
          Icons.waves_rounded,
          size: 200,
          color: AppTheme.primaryColor.withValues(alpha: 0.05),
        ),
      ),
    );
  }

  // Incoming Call Action Controls (Accept / Pickup & Decline)
  Widget _buildIncomingCallControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Decline / End Button
        _buildCircleActionButton(
          icon: Icons.call_end_rounded,
          color: Colors.redAccent,
          label: "Decline",
          onTap: () => controller.endCall(),
        ),

        // Accept / Pickup Button
        _buildCircleActionButton(
          icon: Icons.call_rounded,
          color: Colors.greenAccent.shade700,
          label: "Pickup",
          onTap: () => controller.acceptCall(),
        ),
      ],
    );
  }

  // Active or Outgoing Call Controls (Mute, Video, Flip, Speaker, End)
  Widget _buildActiveCallControls(bool isVideoCall) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Mute Mic Button
          _buildCircleIconButton(
            icon: controller.isMuted.value ? Icons.mic_off_rounded : Icons.mic_rounded,
            isActive: controller.isMuted.value,
            onTap: () => controller.toggleMute(),
          ),

          // Speaker Button
          _buildCircleIconButton(
            icon: controller.isSpeakerOn.value ? Icons.volume_up_rounded : Icons.volume_down_rounded,
            isActive: controller.isSpeakerOn.value,
            onTap: () => controller.toggleSpeaker(),
          ),

          // Toggle Video Button (Only for video calls)
          if (isVideoCall)
            _buildCircleIconButton(
              icon: controller.isVideoEnabled.value ? Icons.videocam_rounded : Icons.videocam_off_rounded,
              isActive: !controller.isVideoEnabled.value,
              onTap: () => controller.toggleVideo(),
            ),

          // Switch Camera Button (Only for video calls)
          if (isVideoCall)
            _buildCircleIconButton(
              icon: Icons.cameraswitch_rounded,
              isActive: false,
              onTap: () => controller.switchCamera(),
            ),

          // End Call Button
          _buildCircleIconButton(
            icon: Icons.call_end_rounded,
            color: Colors.redAccent,
            size: 28,
            onTap: () => controller.endCall(),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
    Color? color,
    double size = 24,
  }) {
    final btnColor = color ?? (isActive ? AppTheme.primaryColor : Colors.white24);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: btnColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

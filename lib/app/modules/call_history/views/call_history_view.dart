import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stream_chat/app/data/models/call_model.dart';
import 'package:stream_chat/app/modules/call/controllers/call_controller.dart';
import 'package:stream_chat/app/modules/call_history/controllers/call_history_controller.dart';
import 'package:stream_chat/app/theme/app_theme.dart';

class CallHistoryView extends GetView<CallHistoryController> {
  const CallHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = controller.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Call History",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              "Recent calls & logs",
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Clear All History",
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.textSecondary),
            onPressed: () => controller.clearAllLogs(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs & Search Bar Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withValues(alpha: 0.5),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.surfaceColorLight.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Column(
              children: [
                // Search Input Field
                TextField(
                  controller: controller.searchController,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Search call log...",
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => controller.searchController.clear(),
                          )
                        : const SizedBox.shrink()),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Pill Selector (All vs Missed)
                Obx(() {
                  final activeFilter = controller.selectedFilter.value;
                  return Row(
                    children: [
                      _buildFilterChip(
                        label: "All Calls",
                        isSelected: activeFilter == HistoryFilter.all,
                        onTap: () => controller.selectedFilter.value = HistoryFilter.all,
                      ),
                      const SizedBox(width: 10),
                      _buildFilterChip(
                        label: "Missed Calls",
                        isSelected: activeFilter == HistoryFilter.missed,
                        onTap: () => controller.selectedFilter.value = HistoryFilter.missed,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          // Real-time Call Logs Stream List
          Expanded(
            child: StreamBuilder<List<CallModel>>(
              stream: controller.getCallHistoryStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error loading call logs",
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                  );
                }

                final rawLogs = snapshot.data ?? [];
                final filteredLogs = controller.filterCallLogs(rawLogs);

                if (filteredLogs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final call = filteredLogs[index];
                    final isOutgoing = call.callerId == currentUid;
                    final targetName = isOutgoing ? call.receiverName : call.callerName;
                    final targetPic = isOutgoing ? call.receiverPic : call.callerPic;

                    return Dismissible(
                      key: Key(call.docId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: AppTheme.errorColor.withValues(alpha: 0.8),
                        child: const Icon(Icons.delete_forever_rounded, color: Colors.white),
                      ),
                      onDismissed: (_) => controller.deleteLog(call.docId),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.surfaceColorLight.withValues(alpha: 0.6),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.surfaceColorLight,
                            backgroundImage: targetPic.isNotEmpty ? NetworkImage(targetPic) : null,
                            child: targetPic.isEmpty
                                ? const Icon(Icons.person_rounded, color: AppTheme.textSecondary, size: 26)
                                : null,
                          ),
                          title: Text(
                            targetName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              // Direction Icon (Incoming / Outgoing / Missed)
                              _getDirectionIcon(isOutgoing, call.status),
                              const SizedBox(width: 6),

                              // Call Type Badge
                              Icon(
                                call.callType == CallType.video
                                    ? Icons.videocam_rounded
                                    : Icons.phone_rounded,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),

                              // Formatted Status & Date/Time
                              Expanded(
                                child: Text(
                                  "${_getStatusLabel(isOutgoing, call.status)} • ${_formatTimestamp(call.createdAt)}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getStatusColor(isOutgoing, call.status),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Call Back Audio Button
                              IconButton(
                                tooltip: "Audio Call",
                                icon: const Icon(Icons.phone_outlined, color: AppTheme.secondaryColor, size: 22),
                                onPressed: () => controller.initiateCallBack(call, CallType.audio),
                              ),

                              // Call Back Video Button
                              IconButton(
                                tooltip: "Video Call",
                                icon: const Icon(Icons.videocam_outlined, color: AppTheme.primaryColor, size: 22),
                                onPressed: () => controller.initiateCallBack(call, CallType.video),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColorLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.surfaceColorLight),
            ),
            child: const Icon(
              Icons.phone_missed_rounded,
              size: 48,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "No Call History",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Your recent audio and video call logs will appear here.",
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getDirectionIcon(bool isOutgoing, String status) {
    if (isOutgoing) {
      return const Icon(
        Icons.call_made_rounded,
        size: 15,
        color: AppTheme.primaryColor,
      );
    } else if (status == 'declined' || status == 'ringing') {
      return const Icon(
        Icons.call_missed_rounded,
        size: 15,
        color: AppTheme.errorColor,
      );
    } else {
      return const Icon(
        Icons.call_received_rounded,
        size: 15,
        color: AppTheme.onlineColor,
      );
    }
  }

  String _getStatusLabel(bool isOutgoing, String status) {
    if (isOutgoing) {
      if (status == 'accepted' || status == 'ended') return "Outgoing";
      if (status == 'declined') return "Declined";
      return "Outgoing";
    } else {
      if (status == 'accepted' || status == 'ended') return "Incoming";
      if (status == 'declined') return "Missed";
      return "Incoming";
    }
  }

  Color _getStatusColor(bool isOutgoing, String status) {
    if (!isOutgoing && (status == 'declined' || status == 'ringing')) {
      return AppTheme.errorColor;
    }
    return AppTheme.textSecondary;
  }

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return "Just now";
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    final hour = dateTime.hour == 0 ? 12 : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final timeStr = "$hour:$minute $period";

    if (difference.inDays == 0 && now.day == dateTime.day) {
      return timeStr;
    } else if (difference.inDays <= 1 && now.day != dateTime.day) {
      return "Yesterday $timeStr";
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months[dateTime.month - 1];
      return "$month ${dateTime.day}, $timeStr";
    }
  }
}

import 'package:get/get.dart';
import 'package:stream_chat/app/modules/call_history/controllers/call_history_controller.dart';

class CallHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CallHistoryController>(
      () => CallHistoryController(),
    );
  }
}

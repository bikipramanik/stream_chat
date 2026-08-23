import 'package:get/get.dart';
import 'package:stream_chat/app/modules/call/controllers/call_controller.dart';

class CallBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CallController>(() => CallController());
  }
}

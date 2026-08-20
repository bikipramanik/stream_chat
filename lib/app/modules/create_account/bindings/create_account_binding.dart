import 'package:get/get.dart';
import 'package:stream_chat/app/modules/create_account/controllers/create_account_controller.dart';

class CreateAccountBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateAccountController>(
      () => CreateAccountController(),
    );
  }
}

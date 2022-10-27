import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:walk_with_thooly/controller/state_controller.dart';

final StateService _service = Get.put(StateService());

Future dialogLogout(context) {
  return showCupertinoDialog(
    context: context,
    builder: (context) => Theme(
      data: ThemeData.light(),
      child: CupertinoAlertDialog(
        title: Text('Sign out'.tr),
        content: Text('Are you sure to sign out?'.tr),
        actions: [
          CupertinoDialogAction(
            child: Text('NO'.tr),
            onPressed: () => Get.back(),
          ),
          CupertinoDialogAction(
            child: Text('YES'.tr),
            onPressed: () {
              /// logout task - remove userinfo from getStorage and service
              _service.resetLogout();
              Get.offAndToNamed('/');
              // Get.snackbar('Sign out'.tr, 'Hope to see you again!'.tr,
              //     backgroundColor: Colors.grey[100]);
            },
          ),
        ],
      ),
    ),
  );
}


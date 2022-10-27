import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:walk_with_thooly/controller/state_controller.dart';
import 'package:walk_with_thooly/resources/kConstant.dart';

final StateService _service = Get.put(StateService());

Future dialogSendMessage(context, String uid) {
  return showCupertinoDialog(
    context: context,
    builder: (context) => Theme(
      data: ThemeData.light(),
      child: CupertinoAlertDialog(
        title: Text('Send Message'.tr),
        content: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(uid, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            ),
            FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Do you want to send message to your friend?'.tr)),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel'.tr),
            onPressed: () => Get.back(),
          ),
          CupertinoDialogAction(
            child: Text('Confirm'.tr),
            onPressed: () {
              Get.offAndToNamed(kRoutes.MESSAGE_PAGE);
            },
          ),
        ],
      ),
    ),
  );
}


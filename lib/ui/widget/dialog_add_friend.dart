import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:walk_with_thooly/controller/state_controller.dart';
import 'package:walk_with_thooly/controller/firebase_service.dart';

final FirebaseService _fbService = Get.put(FirebaseService());

Future dialogAddFriend(context, String userid) {
  return showCupertinoDialog(
    context: context,
    builder: (context) => Theme(
      data: ThemeData.light(),
      child: CupertinoAlertDialog(
        title: Text('Add to your friend'.tr),
        content: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(userid, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            ),
            Text('Do you want to follow as friend?'.tr),
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
              /// add friend to follow
              _fbService.addFriend(userid);
              Get.back();
            },
          ),
        ],
      ),
    ),
  );
}


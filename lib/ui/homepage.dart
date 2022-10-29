import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/cupertino.dart';

import 'package:walk_with_thooly/controller/state_controller.dart';
import 'package:walk_with_thooly/resources/kConstant.dart';
import 'package:walk_with_thooly/resources/model/user_model.dart';
import 'package:walk_with_thooly/ui/user_page.dart';
import 'package:walk_with_thooly/ui/widget/home.dart';
import 'package:walk_with_thooly/ui/users/widget/dialog_logout.dart';
import 'package:walk_with_thooly/ui/widget/message.dart';
import 'package:walk_with_thooly/ui/widget/my_map.dart';
import 'package:walk_with_thooly/controller/firebase_service.dart';

final StateService _service = Get.put(StateService());
final FirebaseService _fbService = Get.put(FirebaseService());
final GetStorage _storage = Get.put(GetStorage(kStorageKey.CONTAINER));

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);
  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final List<Widget> navPages = const [Home(), MyGoogleMap(), Messaging(),  UserPage()];

  @override
  void initState() {
    super.initState();
    _getJournal();
    _initStorage();
  }

  void _getJournal() async {
    String journal = await _fbService.downloadJournal();
    setState(() {
      _service.journal.value = journal;
    });
  }

  void _initStorage() async {
    if (_storage.read(kStorageKey.USERINFO) != null) {
      final userinfo = await _storage.read(kStorageKey.USERINFO);
      _service.userInfo.value = UserModel.fromMap(userinfo);
    }
    if (_storage.read(kStorageKey.THUMBNAIL) != null) {
      String thumbnail = await _storage.read(kStorageKey.THUMBNAIL);
      _service.userThumbnail.value = thumbnail;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget action = Container();
    if (_service.navIndex.value == 3) {
      if (_service.userInfo.value.userid != null && _service.userInfo.value.userid!.isNotEmpty) {
        action = TextButton(
            onPressed: () {
              dialogLogout(context).then((_) {
                // Future.delayed(const Duration(milliseconds: 500));
                _navItemTap(0);
              });  // back to home
            },
            child: Text('Sign Out'.tr, style: TextStyle(color: Colors.grey[700]))
        );
      }
    } else if (_service.navIndex.value == 0) {
      action = TextButton(
          onPressed: () => {},  // todo remove
          child: Icon(Icons.menu, color: kColor.appbarMenu,)
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text(kConst.titleAppbar[_service.navIndex.value].tr, style: TextStyle(color: kColor.appbarText),
        ),
        centerTitle: true,
        backgroundColor: kColor.appbar,
        automaticallyImplyLeading: false,
        actions: [
          action
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: kColor.navigationBar,
        selectedItemColor: kColor.navigationBarSelected,
        unselectedItemColor: kColor.navigationBarUnselected,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: 'Home'.tr),
          BottomNavigationBarItem(icon: const Icon(Icons.map), label: 'Map'.tr),
          BottomNavigationBarItem(icon: const Icon(Icons.message), label: 'Message'.tr),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: 'User'.tr),
        ],
        currentIndex: _service.navIndex.value,
        onTap: _navItemTap,
      ),
      backgroundColor: kColor.background,
      body: SafeArea(
          child: navPages[_service.navIndex.value]
      ),
    );
  }

  void _navItemTap(int idx) async {
    if (idx == 1) {
      bool isGranted = await _checkLocationPermission(context);
      if (isGranted) {
        setState(() {
          _service.navIndex.value = 1;
        });
      }
    } else {
      setState(() {
        _service.navIndex.value = idx;
      });
    }
  }

  Future<bool> _checkLocationPermission(context) async {
    bool isGranted = await checkGranted();
    if (!isGranted) {     // if not location access granted
      _showDialogPermission(context);
      return false;
    } else {
      return true;
    }
  }

  Future<bool> checkGranted() async {
    var status = await Permission.location.status;
    if (status.isGranted) {
      return true;
    } else {
      return false;
    }
  }

  void _showDialogPermission(context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => Theme(
        data: ThemeData.light(),
        child: CupertinoAlertDialog(
          title: Text('permission_title'.tr),
          content: Text('permission_info'.tr),
          actions: [
            CupertinoDialogAction(
                child: Text('Cancel'.tr),
                onPressed: () => Get.back()
            ),
            CupertinoDialogAction(
                child: Text('Confirm'.tr),
                onPressed: () {
                  Permission.location.request();
                  Get.back();
                  setState(() {
                    _service.navIndex.value = 1;
                  });
                }
            ),
          ],
        ),
      ),
    );
  }

}

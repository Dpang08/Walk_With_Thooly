import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:walk_with_thooly/controller/firebase_service.dart';
import 'package:walk_with_thooly/controller/state_controller.dart';
import 'package:walk_with_thooly/resources/kConstant.dart';

final StateService _service = Get.put(StateService());
final FirebaseService _fbService = Get.put(FirebaseService());

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  int initHeight = 75;
  int initWeight = 45;
  final List<int> listHeight = List<int>.generate(100, (index) => 100 + index);
  final List<int> listWeight = List<int>.generate(100, (index) => 30 + index);

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  void _initSettings() {
    if (_service.userInfo.value.height != null) {
      print('---> height: ${_service.userInfo.value.height}');

      initHeight = _service.userInfo.value.height! - 100;
      print('---> height idx: $initHeight');
    }
    if (_service.userInfo.value.weight != null) {
      print('---> height: ${_service.userInfo.value.weight}');

      initWeight = _service.userInfo.value.weight! - 30;
      print('---> weight idx: $initWeight');
    }
  }

  void _updateSettings() async {
    await _fbService.updateUserSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text('Setting'.tr, style: TextStyle(color: kColor.appbarText),
        ),
        centerTitle: true,
        backgroundColor: kColor.appbar,
        automaticallyImplyLeading: false,
        leading: IconButton(
                  onPressed: () {
                    _updateSettings();
                    Get.offAllNamed('/');
                  },
                  icon: Icon(CupertinoIcons.back, color: kColor.appbarMenu,)),
      ),
      backgroundColor: kColor.background,
      resizeToAvoidBottomInset: false,
      // to avoid overflow, when keyboard comes up
      body: _body(),
    );
  }

  Widget _body() {
    return ListView(
      children: [
        const Padding(padding: EdgeInsets.all(10.0)),
        _userSettings(),
      ],
    );
  }

  BoxDecoration _boxDecorationTop() {
    return BoxDecoration(
      color: Colors.grey[50],
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(15.0),
        topRight: Radius.circular(15.0),
      ),
    );
  }
  BoxDecoration _boxDecorationBottom() {
    return BoxDecoration(
      color:  Colors.grey[50],
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(15.0),
        bottomRight: Radius.circular(15.0),
      ),
    );
  }

  Widget _userSettings() {
    return Column(
        children: [
          GestureDetector(
            onTap: () => {},
            child: Container(
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.only(left: 10.0, bottom: 5.0),
                child: Text('Physical Information'.tr, style: const TextStyle(fontSize: 20, color: Colors.black45),)
            ),
          ),
          Container(
            height: 60,
            padding: const EdgeInsets.only(left:20.0, right: 20.0, top: 5, bottom: 5),
            decoration: _boxDecorationTop(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Height'.tr, style: const TextStyle(fontSize: 20, color: Colors.black87)
                ),
                GestureDetector(
                  onTap: () => _pickHeight(),
                  child: Container(
                    height: 40,
                    width: 120,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(left:10, right: 5),
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1,
                        color: Colors.black26
                      ),
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _service.userInfo.value.height != null
                            ? Text('${_service.userInfo.value.height} cm', style: const TextStyle(fontSize: 20),)
                            : const Text('select'),
                        const Icon(Icons.keyboard_arrow_down),
                      ],
                    ),

                  ),
                )
              ],
            ),
          ),
          Container(
            height: 60,
            padding: const EdgeInsets.only(left:20.0, right: 20.0, top: 5, bottom: 5),
            decoration: _boxDecorationBottom(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Weight'.tr, style: const TextStyle(fontSize: 20, color: Colors.black87)
                ),
                GestureDetector(
                  onTap: () => _pickWeight(),
                  child: Container(
                    height: 40,
                    width: 120,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(left:10, right: 5),
                    decoration: BoxDecoration(
                        border: Border.all(
                            width: 1,
                            color: Colors.black26
                        ),
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _service.userInfo.value.weight != null
                            ? Text('${_service.userInfo.value.weight} kg', style: const TextStyle(fontSize: 20),)
                            : const Text('select'),
                        const Icon(Icons.keyboard_arrow_down),
                      ],
                    ),

                  ),
                )
              ],
            ),
          ),
        ]
    );
  }

  Future _pickHeight() {
    return showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SizedBox(
            height: MediaQuery.of(context).size.width * 0.6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                        initialItem: initHeight),
                    itemExtent: 35,
                    useMagnifier: true,
                    magnification: 1.1,
                    onSelectedItemChanged: (int idx) {
                      setState(() {
                        // _service.indexHeight.value = idx;
                        initHeight = idx;
                        _service.userInfo.value.height = listHeight[idx];
                      });
                    },
                    children: List.generate(
                        listHeight.length, (int idx) {
                      return Center(
                        child: Text('${listHeight[idx]} cm', style: const TextStyle(fontSize: 18),),
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

  Future _pickWeight() {
    return showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SizedBox(
            height: MediaQuery.of(context).size.width * 0.6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                        initialItem: initWeight),
                    itemExtent: 35,
                    useMagnifier: true,
                    magnification: 1.1,
                    onSelectedItemChanged: (int idx) {
                      setState(() {
                        // _service.indexWeight.value = idx;
                        initWeight = idx;
                        _service.userInfo.value.weight = listWeight[idx];
                      });
                    },
                    children: List.generate(
                        listWeight.length, (int idx) {
                      return Center(
                        child: Text('${listWeight[idx]} kg', style: const TextStyle(fontSize: 18),),
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        }
    );
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:walk_with_thooly/controller/firebase_service.dart';
import 'package:walk_with_thooly/resources/model/chat_model.dart';
import 'package:walk_with_thooly/resources/model/user_model.dart';
import 'package:walk_with_thooly/controller/state_controller.dart';
import 'package:walk_with_thooly/resources/kConstant.dart';
import 'package:walk_with_thooly/ui/widget/dialog_add_friend.dart';

final StateService _service = Get.put(StateService());
final FirebaseService _fbService = Get.put(FirebaseService());

class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  bool isAllUsers = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _body();
  }

  Widget _body() {
    double height = MediaQuery.of(context).size.height - 100;
    double width = MediaQuery.of(context).size.width;
    double ratio = 0.72;
    TextStyle textStyle = TextStyle(fontSize: 12, color: Colors.grey[800]);

    String id = 'Sign in'.tr;
    if (_service.userInfo.value.userid != null) {
      id = _service.userInfo.value.userid!;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _showThumbnail(),
                  const SizedBox(width: 15,),
                  GestureDetector(
                      onTap: () {
                        _service.printAll();
                      },
                      child: Text(id, style: TextStyle(fontSize: 22, color: kColor.userid))
                  ),
                ],
              ),
              IconButton(
                  onPressed: () => Get.toNamed(kRoutes.SETTINGS),
                  icon: const Icon(Icons.settings, size: 30, color: Colors.black26)
              ),
            ],
          ),
        ),
        const _HorizontalSpacer(),

        const SizedBox(height: 5),
        Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        isAllUsers = true;
                        _getUserList();
                      }),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isAllUsers ? Colors.blue[100]: null,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black12)
                        ),
                        padding: const EdgeInsets.all(5),
                        margin: const EdgeInsets.only(left:15),
                        child: Text('Ranking All Users'.tr,  style: const TextStyle(fontSize:16, color: Colors.black54)),
                      ),
                    ),
                    const SizedBox(width: 15,),
                    GestureDetector(
                      onTap: () => setState(() {
                        isAllUsers = false;
                        _getUserList();
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                            color: isAllUsers ? null : Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black12)
                        ),
                        padding: const EdgeInsets.all(5),
                        margin: const EdgeInsets.only(right:15),
                        child: Text('Friends'.tr,  style: const TextStyle(fontSize:16, color: Colors.black54)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10,),
                Row(
                  children: [
                    const SizedBox(width: 20,),
                    Text('Rank', style: textStyle,),
                    SizedBox(width: width * 0.15,),
                    Text('ID', style: textStyle),
                    SizedBox(width: width * 0.30,),
                    Text('kcal', style: textStyle),
                    SizedBox(width: width * 0.12,),
                    Text('Distance', style: textStyle)
                  ],
                ),
                _listUsers(height * ratio),
              ],
            )
        ),
      ],
    );
  }

  Future<List<UserModel>> _getUserList() async {
    List<UserModel> data;
    if (isAllUsers) {
      data = await _fbService.getAllUsers();
    } else {
      data = await _fbService.getAllFriends();
    }

    return data;
  }

  Widget _listUsers(height) {
    return FutureBuilder(
        future: _getUserList(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData && snapshot.connectionState == ConnectionState.done) {
            return _allUsers(height, snapshot.data);    // return list<UserInfo>
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.only(top: 100),
              child: Center(child: CupertinoActivityIndicator(radius: 15, color: Colors.blueGrey)),
            );
          } else if (snapshot.hasError) {
            return Container(
              padding: const EdgeInsets.all(30),
              alignment: Alignment.center,
              child: const Center(child: Text('Error occurred while getting user dataset from server.'
                  '\nPlease try again later.')),
            );
          } else {
            return const Padding(
              padding: EdgeInsets.only(top: 100),
              child: Center(child: CupertinoActivityIndicator(radius: 15, color: Colors.blueGrey)),
            );
          }
        }
    );
  }

  Widget _allUsers(double height, users) {
    final width = MediaQuery.of(context).size.width;
    TextStyle textStyle = TextStyle(fontSize: 16, color: kColor.rankText);
    TextStyle textStyleMe = TextStyle(fontSize: 18, color: kColor.rankTextHighlight, fontWeight: FontWeight.w500);

    return Container(
      height: height,
      margin: const EdgeInsets.only(left: 10, right: 10, top: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: kColor.decorationBox,
      ),
      padding: const EdgeInsets.only(left: 15, right: 15, top:5, bottom: 5),
      child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: users.length,
          itemBuilder: (BuildContext context, int index) {
            /// set image url to download using cased network image
            Widget thumbnail;
            if (users[index].thumbnail!.isNotEmpty) {
              thumbnail = CachedNetworkImage(
                imageUrl: users[index].thumbnail!,
                fit: BoxFit.fill,
              );
            } else {
              thumbnail = Icon(CupertinoIcons.person_fill, color: kColor.emoji);
            }

            return GestureDetector(
              onTap: () {
                _service.messageBuddy.value = users[index];
                isAllUsers
                    ? dialogAddFriend(context, users[index].userid!)
                    : Get.toNamed(kRoutes.MESSAGE_PAGE);
              },
              child: Container(
                height: 50,
                color: kColor.decorationBox,
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('$index',
                            style: TextStyle(fontSize: 14, color: kColor.rankText),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10,),
                      SizedBox(
                        height: 30,
                        width: 30,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(35),
                            child: thumbnail,
                            // child: Icon(CupertinoIcons.person_fill, color: kColor.emoji)
                        ),
                      ),
                      const SizedBox(width: 10,),
                      SizedBox(
                        width: width * 0.2,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(users[index].userid!,
                            style: users[index].userid == _service.userInfo.value.userid   // 내가 순위에 있으면 highlight
                                ? textStyleMe
                                : textStyle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10,),
                      SizedBox(
                        width: width * 0.2,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text('${users[index].totalKcal!}',
                            style: users[index].userid == _service.userInfo.value.userid   // 내가 순위에 있으면 highlight
                                ? textStyleMe
                                : textStyle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20,),
                      SizedBox(
                        width: width * 0.2,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text('${users[index].totalDist!.toStringAsFixed(1)}km',
                            style: users[index].userid == _service.userInfo.value.userid   // 내가 순위에 있으면 highlight
                                ? textStyleMe
                                : textStyle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
      ),
    );
  }

  Widget _showThumbnail() {
    return GestureDetector(
      onTap: () {
        if (_service.userInfo.value.userid != null) {
          _getThumbnail();
        }
      },
      child: SizedBox(
          width: 60,
          height: 60,
          child: _service.userInfo.value.userid != null && _service.userThumbnail.value.isNotEmpty
              ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    // child: Image.file(File(imagePath), fit: BoxFit.fill,)
                    child: Image.file(
                        File(_service.userThumbnail.value),
                        fit: BoxFit.fill))
              : FittedBox(child: Icon(Icons.person, color: kColor.defaultThumbnail))
      ),
    );
  }

  void _getThumbnail() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 120,
        maxHeight: 120,
      );
      if (image == null) return;
      /// get size of image
      // var img = image.readAsBytes();
      // var size = await decodeImageFromList(await img);
      // print('=====> img width x height: ${size.width} x ${size.height}');
      /// save selected thumbnail to local storage and upload it to firestore storage
      await _fbService.saveImageToLocal(await image.readAsBytes())
          .then((_) {
            _fbService.uploadProfileImageToFb();
      });
    } on PlatformException catch(err) {
      Get.snackbar('error@image picker', '$err');
    }
  }

}

class _HorizontalSpacer extends StatelessWidget {
  const _HorizontalSpacer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 0.9;
    return Center(
      child: Container(
        height: 2,
        width: width,
        color: Colors.grey[300],
      ),
    );
  }
}

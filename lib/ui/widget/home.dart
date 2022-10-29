import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:walk_with_thooly/controller/state_controller.dart';
import 'package:walk_with_thooly/resources/kConstant.dart';
import 'package:walk_with_thooly/controller/firebase_service.dart';
import 'package:walk_with_thooly/resources/model/user_model.dart';
import 'package:walk_with_thooly/ui/widget/dialog_send_message.dart';

final StateService _service = Get.put(StateService());
final FirebaseService _fbService = Get.put(FirebaseService());

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<Widget> navPages = [];

  @override
  void initState() {
    super.initState();
    getMyData();
  }

  void getMyData() async {
    await _fbService.getMyWalkData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    TextStyle textStyle = TextStyle(fontSize: 12, color: Colors.grey[800]);

    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(1),
      child: Obx(() => Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _login(),
              _mainCircle(),
              _commentary(),
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 15, bottom: 12),
                child: Text('Ranking Top 10'.tr, style: const TextStyle(color: Colors.black54),),
              ),
              Row(
                children: [
                  const SizedBox(width: 20,),
                  Text('Rank', style: textStyle,),
                  SizedBox(width: width * 0.15,),
                  Text('ID', style: textStyle),
                  SizedBox(width: width * 0.28,),
                  Text('kcal', style: textStyle),
                  SizedBox(width: width * 0.12,),
                  Text('Distance', style: textStyle)
                ],
              ),
            ]
          ),
              _service.userInfo.value.userid == null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Center(child: Text('Please sign in'.tr, style: const TextStyle(color: Colors.blueGrey),),),
                    )
                  : _service.top10Friends.isEmpty
                    ? _top10Friends()   // height * 0.4
                    : _top10(_service.top10Friends)
        ],
      )),
    );
  }

  Widget _login() {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(right: 10),
      alignment: Alignment.centerRight,
      child: _service.userInfo.value.userid != null
          ? SizedBox(
              height: 50,
              width: 50,
              child: _service.userThumbnail.value.isNotEmpty
                  ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(File(_service.userThumbnail.value), fit: BoxFit.fill,)
                    )
                  : FittedBox(child: Icon(Icons.person, color: kColor.defaultThumbnail))
          )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () {
                      Get.toNamed(kRoutes.LOGIN);
                    },
                    child: Text('Sign in'.tr, style: TextStyle(fontSize: 16, color: kColor.login))
                ),
                Icon(Icons.login, size: 20, color: kColor.login)
              ],
            ),
    );
  }

  Widget _commentary() {
    return GestureDetector(
      onTap: () {
        Get.toNamed(kRoutes.JOURNAL);
      },
      child: Container(
        height: 80,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 15, right: 15),
        margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
        decoration: BoxDecoration(
          color: kColor.decorationBox,
          borderRadius: BorderRadius.circular(15)
        ),
        child: Obx(() => _service.journal.value.isEmpty
            ? const Center(child: Text('No journal to show', style: TextStyle(fontSize: 16),))
            : Text(_service.journal.value, style: const TextStyle(fontSize: 16), maxLines: 3,
          overflow: TextOverflow.ellipsis)),
      ),
    );
  }

  Widget _mainCircle() {
    double rSize = 180;
    int days = 0;
    int streak = 0;
    double kcalTotal = 0;
    if (_service.userInfo.value.userid != null) {
      days = _service.userInfo.value.totalDays!;
      streak = _service.userInfo.value.streakDays!;
      kcalTotal = _service.userInfo.value.totalKcal!;
    }

    return ElevatedButton(
      onPressed: () => {},
      style: ElevatedButton.styleFrom(
          fixedSize: Size(rSize, rSize),
          primary: kColor.decorationBox,
          shape: const CircleBorder(side: BorderSide(width: 1, color: Colors.transparent))
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10,),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              children: [
                Text('$days ', style: TextStyle(fontSize: 28, color: kColor.circleText,
                    fontWeight: FontWeight.w500),
                ),
                Text('days'.tr, style: TextStyle(fontSize: 16, color: kColor.circleText,
                    fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10,),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('streak $streak', style: TextStyle(fontSize: 18, color: kColor.circleText,
                fontWeight: FontWeight.w500),),
          ),
          const SizedBox(height: 5,),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('${kcalTotal.toInt()} kcal', style: TextStyle(fontSize: 18, color: kColor.circleText,
                fontWeight: FontWeight.w500),),
          ),
        ],
      ),
    );
  }

  Widget _top10Friends() {
    return FutureBuilder(
        future: _fbService.getTop10Friends(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData && snapshot.connectionState == ConnectionState.done) {
            List<UserModel> users = snapshot.data;
            if (users.isNotEmpty) {
              return _top10(users); // return list<UserInfo>
            } else {
              return Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Center(child: Text('No friends in the list'.tr,
                  style: const TextStyle(color: Colors.blueGrey),)),
              );
            }
          } else if (snapshot.hasError) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.3,
              padding: const EdgeInsets.all(30),
              alignment: Alignment.center,
              child: const Center(child: Text('Error occurred while getting data from server. '
                  'Please try again later.', style: TextStyle(fontSize: 14),)),
            );
          } else {
            return const Padding(
              padding: EdgeInsets.only(top:100),
              child: Center(child: CupertinoActivityIndicator(radius: 15, color: Colors.blueGrey)),
            );
          }
        }
    );
  }

  Widget _top10(List<UserModel> users) {
    double width = MediaQuery.of(context).size.width;
    TextStyle textStyle = TextStyle(fontSize: 16, color: kColor.rankText);
    TextStyle textStyleMe = TextStyle(fontSize: 18, color: kColor.rankTextHighlight, fontWeight: FontWeight.w500);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(left: 10, right: 10, top: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: kColor.decorationBox,
        ),
        padding: const EdgeInsets.only(left: 5, right: 5, top:5, bottom: 5),
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
                  dialogSendMessage(context, users[index].userid!);
                  },
                child: Container(
                  height: 55,
                  color: kColor.decorationBox,
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text('${index + 1}', textAlign: TextAlign.end,
                            style: TextStyle(fontSize: 14, color: kColor.rankText),
                          ),
                        ),
                        const SizedBox(width: 10,),
                        SizedBox(
                          height: 30,
                          width: 30,
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(35),
                              child: thumbnail,
                          ),
                        ),
                        const SizedBox(width: 10,),
                        SizedBox(
                          width: width * 0.2,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text('${users[index].userid}',
                              style: users[index].userid == _service.userInfo.value.userid   // 내가 순위에 있으면 highlight
                                  ? textStyleMe
                                  : textStyle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10,),
                        SizedBox(
                          width: width * 0.20,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text('${users[index].totalKcal!.toInt()}',
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
      ),
    );
  }

}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:walk_with_thooly/resources/model/chat_model.dart';
import 'package:walk_with_thooly/controller/state_controller.dart';
import 'package:walk_with_thooly/resources/kConstant.dart';
import 'package:walk_with_thooly/controller/firebase_service.dart';

final StateService _service = Get.put(StateService());
final FirebaseService _fbService = Get.put(FirebaseService());

class Messaging extends StatefulWidget {
  const Messaging({Key? key}) : super(key: key);
  @override
  State<Messaging> createState() => _MessagingState();
}

class _MessagingState extends State<Messaging> {
  late ScrollController _scrollController;
  late List<ChatModel> messages;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
      return _mainBody();
  }

  Widget _mainBody() {
    return FutureBuilder(
        future: _fbService.getAllMessages(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            return _messages(snapshot.data);    // return list<UserInfo>
          } else if (snapshot.hasError) {
            return Container(
              padding: const EdgeInsets.all(30),
              alignment: Alignment.center,
              child: const Center(child: Text('Error occurred while getting message from server.'
                  '\nPlease try again later.')),
            );
          } else {
            return const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Center(child: CupertinoActivityIndicator(radius: 15, color: Colors.blueGrey)),
            );
          }
        }
    );
  }

  Widget _messages(List<ChatModel> data) {
    return data.isNotEmpty ?
        ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(10),
            itemCount: data.length,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _thumbnail(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left:5),
                            child: Text('${data[index].sender}', style: const TextStyle(fontSize: 14),),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                                decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                        // bottomRight: Radius.circular(15),
                                    ),
                                    color: Colors.indigo[100]
                                ),
                                child: Text(data[index].message!, style: const TextStyle(fontSize: 15)),
                              ),
                              _dateTime(data[index]),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
        )
        : Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Center(
                child: Text('No friends to follow'.tr, style: const TextStyle(
                    fontSize: 18, color: Colors.blueGrey))
            )
          );
  }

  Widget _thumbnail() {
    return Row(
      children: [
        // SizedBox(
        //   width: 35,  // equal to radius 20
        //   height: 35,
        //   child: ClipRRect(
        //     borderRadius: BorderRadius.circular(16),
        //     child: CachedNetworkImage(
        //       imageUrl: _service.messageBuddy.value.thumbnail!,
        //       fit: BoxFit.fill,
        //     ),
        //   ),
        // ),
        Icon(CupertinoIcons.person_crop_circle, size: 40, color: kColor.emoji),
      ],
    );
  }

  Widget _dateTime(ChatModel msg) {
    DateTime dt = DateTime.parse(msg.timeAt.toString());
    String year = dt.year.toString();
    year = year.replaceFirst('20', '');  // 2022년 --> 22년
    int month = dt.month;
    int date = dt.day;
    String hour = dt.hour.toString();
    String min = dt.minute.toString();
    if (dt.hour < 10) {
      hour = '0${dt.hour}';
    }
    if (dt.minute < 10) {
      min = '0${dt.minute}';
    }
    return SizedBox(
      height: 20,
      width: 50,
      child: FittedBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$year.$month.$date'),
            Text('$hour:$min'),
          ],
        ),
      ),
    );
  }

}

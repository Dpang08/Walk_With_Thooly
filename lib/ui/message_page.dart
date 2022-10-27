import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:walk_with_thooly/resources/kConstant.dart';
import 'package:walk_with_thooly/controller/state_controller.dart';
import 'package:walk_with_thooly/controller/firebase_service.dart';
import 'package:walk_with_thooly/resources/model/chat_model.dart';

final StateService _service = Get.put(StateService());
final FirebaseService _fbService = Get.put(FirebaseService());

class MessagePage extends StatefulWidget {
  const MessagePage({Key? key}) : super(key: key);

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatModel> messages = [];
  bool isTextInput = false;   // 텍스트 필드에 입력이 들어 왔는지 확인

  @override
  void dispose() {
    super.dispose();
    _textEditingController.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Container(
            padding: const EdgeInsets.only(right:15),
            child: Row(
              children: [
                IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black45,)
                ),
                const SizedBox(width: 15,),
                _service.messageBuddy.value.thumbnail!.isNotEmpty
                    ? _thumbnail()
                    : Icon(CupertinoIcons.person_fill, size: 40, color: kColor.emoji),
                Text(_service.messageBuddy.value.userid!, style: TextStyle(
                    fontSize: 22, color: kColor.appbarText, fontWeight: FontWeight.w400))
              ],
            ),
          ),
        ),
        backgroundColor: kColor.appbar,
      ),
      backgroundColor: kColor.background,
      body: _mainBody(),
    );
  }

  Widget _mainBody() {
    return Column(
      children: [
        Flexible(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              physics: const BouncingScrollPhysics(),
              itemCount: messages.length,
              itemBuilder: (_, index) => _messageBody(index),
            ),
        ),
        Container(
          decoration: BoxDecoration(
            color: kColor.inputTextField
          ),
          child: _inputTextField(),
        )
      ],
    );
  }

  Widget _thumbnail() {
    return SizedBox(
      width: 40,  // equal to radius 20
      height: 40,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: _service.messageBuddy.value.thumbnail!,
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  Widget _messageBody(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Align(
        alignment: Alignment.topRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _dateTime(index),
            Container(
              padding: const EdgeInsets.all(10),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: kColor.messageBoxSender
              ),
              child: Text(messages[index].message ?? '', style: const TextStyle(fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTime(int index) {
    String year = messages[index].timeAt!.year.toString();
    year = year.replaceFirst('20', '');  // 2022년 --> 22년
    int month = messages[index].timeAt!.month;
    int date = messages[index].timeAt!.day;
    String hour = messages[index].timeAt!.hour.toString();
    String min = messages[index].timeAt!.minute.toString();
    if (messages[index].timeAt!.hour < 10) {
      hour = '0${messages[index].timeAt!.hour}';
    }
    if (messages[index].timeAt!.minute < 10) {
      min = '0${messages[index].timeAt!.minute}';
    }
    return SizedBox(
      height: 20,
      width: 50,
      child: FittedBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$year.$month.$date'),
            Text('$hour:$min'),
          ],
        ),
      ),
    );
  }

  Widget _inputTextField() {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 2, top: 2),
      child: Row(
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 5, right: 5, top: 2, bottom: 2),
              child: TextField(
                controller: _textEditingController,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: kColor.textField,
                  focusedBorder: InputBorder.none,
                  hintText: 'Write message'.tr,
                  prefixIcon: Icon(Icons.chat_outlined, size: 20, color: kColor.textFieldIcon,),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: kColor.textField)
                  ),
                  // border: OutlineInputBorder(
                  //   borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                  //   borderSide: BorderSide(color: kColor.textField)
                  // ),
                ),
                onChanged: (text) => setState(() {
                  isTextInput = text.isNotEmpty;
                }),
                onSubmitted: isTextInput ? _onSubmit : null,
              ),
            ),
          ),
          IconButton(
            icon: isTextInput
                ? Icon(CupertinoIcons.arrow_up_circle_fill, size: 30, color: kColor.submitIconOn)
                : Icon(CupertinoIcons.arrow_up_circle, size: 30, color: kColor.submitIconOff),
            onPressed: () => _onSubmit(_textEditingController.text)),
        ],
      ),
    );
  }

  /// handling submit to send the text
  void _onSubmit(String text) {
    _textEditingController.clear();   // clear text field
    setState(() {
      ChatModel msg = ChatModel(
          message: text,
          sender: _service.userInfo.value.userid,
          timeAt: DateTime.now());
      messages.add(msg);
      _fbService.sendMessage(msg);

      if (_scrollController.position.maxScrollExtent > 0) {
        _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 60,
            duration: const Duration(milliseconds: 10),
            curve: Curves.easeOutQuint);
      }
      isTextInput = false;
    });
  }

}

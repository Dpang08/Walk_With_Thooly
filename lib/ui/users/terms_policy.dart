import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:walk_with_thooly/controller/state_controller.dart';
import 'package:walk_with_thooly/resources/kConstant.dart';

final StateService _service = Get.put(StateService());

class TermsPolicy extends StatelessWidget {
  const TermsPolicy({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String title;
    final int selectedTerms = Get.arguments;   // 0 - privacy policy, 1 - terms of use

    if (selectedTerms == 0) {
      title = 'Privacy Policy'.tr;   // 0 - privacy policy
    } else {
      title = 'Terms of Use'.tr;   // 1 - terms of use
    }
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text(title, style: TextStyle(color: kColor.appbarText),
        ),
        centerTitle: true,
        backgroundColor: kColor.appbar,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
              onPressed: () => Get.back(),
              icon: Icon(CupertinoIcons.back, color: kColor.appbarMenu,)),
        ),
      ),
      backgroundColor: kColor.background,
      body: _body(title, selectedTerms),
    );
  }

  Widget _body(String title, int selectedTerms) {
    String content = 'There is a technical issue to show $title.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 20,),
          FutureBuilder(
            future: _getTextFromAsset(selectedTerms),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return _showTextError(content);
                case ConnectionState.waiting:
                  return Container(
                    padding: const EdgeInsets.all(30),
                    alignment: Alignment.center,
                    child: const CupertinoActivityIndicator(radius: 20, color: Colors.grey),
                  );
                default:
                  if (snapshot.hasError) {
                    return _showTextError(content);
                  } else if (snapshot.data.length < 1) {
                      return _showTextError(content);
                  } else {
                      return _showText(snapshot.data);
                  }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _showTextError(String text) {
    return Center(
      child: Text(
        text, style: TextStyle(fontSize: 20, color: kColor.termsText),
      ),
    );
  }

  Widget _showText(String text) {
    return Text(text, style: TextStyle(fontSize: 12, color: kColor.termsText),
    );
  }

  Future<String> _getTextFromAsset(int index) async {
    final locale = Get.deviceLocale;
    if (locale == const Locale('ko', 'KR')) {  // in case ko_KR
      if (index == 0) {   // 0 - privacy policy
        return await rootBundle.loadString(kConst.privacyPathKR);
      } else {    // 1 - terms of use
        return await rootBundle.loadString(kConst.termsPathKR);
      }
    } else {  // in case en_US
      if (index == 0) {   // 0 - privacy policy
        return await rootBundle.loadString(kConst.privacyPathEN);
      } else {    // 1 - terms of use
        return await rootBundle.loadString(kConst.termsPathEN);
      }
    }
  }
}

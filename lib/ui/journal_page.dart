import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:walk_with_thooly/resources/kConstant.dart';
import 'package:walk_with_thooly/controller/state_controller.dart';

final StateService _service = Get.put(StateService());

class JournalPage extends StatefulWidget {
  const JournalPage({Key? key}) : super(key: key);

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text(kConst.titleJournal, style: TextStyle(color: kColor.appbarText),
        ),
        centerTitle: true,
        backgroundColor: kColor.appbar,
        automaticallyImplyLeading: false,
        leading: IconButton(
            onPressed: () => Get.offNamed(kRoutes.HOME),
            icon: Icon(Icons.arrow_back_ios, color: kColor.appbarMenu,)
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints size) {
              return _mainBody(size);
            }
        ),
      ),
      backgroundColor: kColor.background,
    );
  }

  Widget _mainBody(BoxConstraints size) {
    return Container(
      color: kColor.background,
      padding: const EdgeInsets.all(5),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(10),
        child: Obx(() => _service.journal.value.isEmpty
            ? const Center(child: Text('No journal to show', style: TextStyle(fontSize: 16),))
            : Text(_service.journal.value, style: TextStyle(fontSize: 15, color: kColor.journal),),
      )),
    );
  }

}

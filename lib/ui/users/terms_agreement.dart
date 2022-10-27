import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roundcheckbox/roundcheckbox.dart';

import 'package:walk_with_thooly/controller/state_controller.dart';
import 'package:walk_with_thooly/resources/kConstant.dart';

final StateService _service = Get.put(StateService());

class TermsAgreement extends StatefulWidget {
  const TermsAgreement({Key? key}) : super(key: key);

  @override
  State<TermsAgreement> createState() => _TermsAgreementState();
}

class _TermsAgreementState extends State<TermsAgreement> {
  bool _isAgreePrivacy = false;
  bool _isAgreeTerms = false;

  @override
  void dispose() {
    super.dispose();
    _service.isAllTermsAgreed = false.obs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text('Service Agreement'.tr, style: TextStyle(color: kColor.appbarText),
        ),
        centerTitle: true,
        backgroundColor: kColor.appbar,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
              onPressed: () => Get.offAllNamed('/'),
              icon: Icon(CupertinoIcons.xmark, color: kColor.appbarMenu,)),
        ),
      ),
      backgroundColor: kColor.background,
      body: WillPopScope(
        child: SafeArea(
            child: _body()
        ),
        onWillPop: () {
          return Future(() => false);
        },
      ),
    );
  }

  Widget _body() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          /// Title & Subtitle
          const SizedBox(height: 20.0),
          Text('agreement_subtitle'.tr, style: TextStyle(
                color: kColor.loginContents, fontSize: 16)),
          const SizedBox(height: 30.0),
          _agreeAll(),
          const SizedBox(height: 20.0),
          _horizontalGreyLine(),
          const SizedBox(height: 20.0),
          _checkBoxTermsOfUse(),
          const SizedBox(height: 20.0),
          _checkBoxPrivacy(),
          const SizedBox(height: 20.0),
          _horizontalGreyLine(),
          const SizedBox(height: 30.0),

          _nextButton(),
        ],
      ),
    );
  }

  Widget _agreeAll() {
    return Row(
      children: [
        RoundCheckBox(
            size: 25,
            isChecked: _service.isAllTermsAgreed.value,
            checkedColor: Colors.lightGreen[700],
            checkedWidget: const Icon(Icons.check_rounded, size: 20, color: Colors.white,),
            onTap: (value) {
              setState(() {
                if (value != null && value) {
                  _isAgreeTerms = true;
                  _isAgreePrivacy = true;
                  _service.isAllTermsAgreed = true.obs;
                } else {
                  _isAgreeTerms = false;
                  _isAgreePrivacy = false;
                  _service.isAllTermsAgreed = false.obs;
                }
              });
            }
        ),
        const SizedBox(width: 10,),   // spacer
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Agree all the terms and conditions'.tr,
                  style: const TextStyle(fontSize: 20, color: Colors.black87))),
        ),
      ],
    );
  }

  Widget _checkBoxTermsOfUse() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            RoundCheckBox(
                size: 22,
                isChecked: _isAgreeTerms,
                checkedColor: Colors.lightGreen[700],
                checkedWidget: const Icon(Icons.check_rounded, size: 18, color: Colors.white,),
                onTap: (value) {
                  setState(() {
                    _isAgreeTerms = value!;
                    if (_isAgreePrivacy && _isAgreeTerms) {
                      _service.isAllTermsAgreed = true.obs;
                    } else {
                      _service.isAllTermsAgreed = false.obs;
                    }
                  });
                }
            ),
            const SizedBox(width: 8,),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.65,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Terms of use agreement (required)'.tr, textAlign: TextAlign.left,
                  style: const TextStyle(color: Colors.black87, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
        IconButton(
            alignment: Alignment.centerRight,
            onPressed: () => Get.toNamed(kRoutes.TERMS_POLICY, arguments: 1),   // 1 - terms of use
            icon: Icon(Icons.arrow_forward_ios,  size: 15, color: Colors.grey[600])
        ),
      ],
    );
  }

  Widget _checkBoxPrivacy() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            RoundCheckBox(
                size: 22,
                isChecked: _isAgreePrivacy,
                checkedColor: Colors.lightGreen[700],
                checkedWidget: const Icon(Icons.check_rounded, size: 18, color: Colors.white,),
                onTap: (value) {
                  setState(() {
                    _isAgreePrivacy = value!;
                    if (_isAgreePrivacy && _isAgreeTerms) {
                      _service.isAllTermsAgreed = true.obs;
                    } else {
                      _service.isAllTermsAgreed = false.obs;
                    }
                  });
                }
            ),
            const SizedBox(width: 8,),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.65,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Privacy policy agreement (required)'.tr,
                  style: const TextStyle(color: Colors.black87, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
        IconButton(
            alignment: Alignment.centerRight,
            onPressed: () => Get.toNamed(kRoutes.TERMS_POLICY, arguments: 0),   // 0 - privacy policy
            icon: Icon(Icons.arrow_forward_ios,  size: 15, color: Colors.grey[600])
        ),
      ],
    );
  }

  Widget _nextButton() {
    return GestureDetector(
      onTap: () {
        if (_service.isAllTermsAgreed.value) {
          Get.offNamed(kRoutes.CREATE_ACCOUNT);
        } else {
          _showDialog(context);   // display alert dialog
        }
      },
      child: Container(
        width: double.infinity,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: kColor.buttonColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('Next'.tr,
          style: TextStyle(
            color: kColor.buttonText,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Future _showDialog(BuildContext context) {
    return showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Please agree all the terms and conditions to proceed next step'.tr,
            style: TextStyle(color: kColor.dialogText, fontSize: 18)
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Close'.tr),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  Widget _horizontalGreyLine() {
    return Container(
      height: 2,
      width: MediaQuery.of(context).size.width * 0.7,
      color: Colors.grey[300],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:walk_with_thooly/resources/kConstant.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({Key? key}) : super(key: key);

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  bool _isProgressing = false;    // used for indicator   (false -> no indicator, true - indicator)
  List<bool> _queryResult = [];   // result [userid, password]
  String? _userid;
  String? _email;
  bool _emailValidated = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text('Forgot Password'.tr, style: TextStyle(color: kColor.appbarText),
        ),
        centerTitle: true,
        backgroundColor: kColor.appbar,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
              onPressed: () => Get.back(),
              icon: Icon(CupertinoIcons.xmark, color: kColor.appbarMenu,)),
        ),
      ),
      backgroundColor: kColor.background,
      resizeToAvoidBottomInset: false,    // to avoid overflow, when keyboard comes up
      body: WillPopScope(
        child: SafeArea(child: Stack(
          children: [
            _body(),
          ],
        )),
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
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: Text('To reset your password, please fill out the following information'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: kColor.loginContents),
              ),
            ),
            const SizedBox(height: 30.0),
            /// Text field for userID
            _inputUserid(),
            const SizedBox(height: 15.0),
            /// text field for email address
            _inputEmail(),
            const SizedBox(height: 30.0),
            _confirmButton(),
            const SizedBox(height: 30.0),
          ]
      ),
    );
  }

  Widget _inputUserid() {
    return TextField(
      style: const TextStyle(fontSize: 22),
      decoration: InputDecoration(
        labelText: 'User ID'.tr,
        prefixIcon: const Icon(Icons.person_outline),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
      onChanged: (text) {
        setState(() {_userid = text;});
      },
    );
  }

  Widget _inputEmail() {
    return TextFormField(
        style: const TextStyle(fontSize: 22),
        decoration: InputDecoration(
          labelText: 'Email'.tr,
          prefixIcon: const Icon(Icons.email_outlined),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
        ),
        onChanged: (text) {
          setState(() {
            _email = text;
          });
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (val) {
          bool? validate;
          /// check email validation using EmailValidator package
          if (val != null) {
            validate = GetUtils.isEmail(val);
          } else {
            validate == null;
          }
          /// return result based on validate
          if (validate != null && validate) {
            _emailValidated = true;
            return null;
          } else {
            _emailValidated = false;
            return 'Invalid email'.tr;
          }
        }
    );
  }

  Future<void> _findUser() async {
    // await _fbService.findUserWithEmail(_userid, _email)
    //     .then((value) => setState(() {   // _value -> result[userid, password]
    //         _queryResult = value;
    //         _isProgressing = false;
    //       })
    //     ).catchError((error) {
    //         Get.snackbar('error @ find user with email', '$error');
    //     });
  }

  Widget _confirmButton() {
    return GestureDetector(
      onTap: () async {
        /// dismiss system keyboard when click
        FocusManager.instance.primaryFocus?.unfocus();  // Close system keyboard
        if (_userid !=null && _email !=null && _emailValidated) {
          setState(() => _isProgressing = true);    // set true for indicator, after loading set to false
          /// find user via firestore
          await _findUser();    // result[userid, email]

          if (_queryResult[0] & _queryResult[1]) {    // 0 - userid, 1 - email
            Get.offNamed('/resetPassword', arguments: _userid);
          } else if (_queryResult[0] && !_queryResult[1]) {   // ID found but email not matched
            String title = 'Email not matched'.tr;
            String content = 'Please check your email and try again'.tr;
            _showDialog(title, content);
          } else {
            String title = 'User ID not valid'.tr;
            String content = 'Please check your user ID and try again'.tr;
            _showDialog(title, content);
          }
        } else if (!_emailValidated) {
          String title = 'Invalid email'.tr;
          String content = 'Please check your email and try again'.tr;
          _showDialog(title, content);
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
        child: _isProgressing
            ? const CupertinoActivityIndicator(radius: 15, color: Colors.white,)
            : Text('Confirm'.tr, style: TextStyle(fontSize: 20, color: kColor.buttonText,
                fontWeight: FontWeight.bold,),
            ),
      ),
    );
  }

  Future _showDialog(String title, String content) {
    return showCupertinoDialog(
      context: context,
      builder: (context) => Theme(
        data: ThemeData.light(),
        child: CupertinoAlertDialog(
          title: Text(title,),
          content: Text(content,),
          actions: [
            CupertinoDialogAction(
              child: Text('Close'.tr),
              onPressed: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }

}

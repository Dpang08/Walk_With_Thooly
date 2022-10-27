import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';

// final FirebaseService _fbService = Get.put(FirebaseService());

class ResetPassword extends StatefulWidget {
  const ResetPassword({Key? key}) : super(key: key);

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final Color _color = Colors.blueGrey[600]!;
  bool _isProgressing = false;    // used for indicator   (false -> no indicator, true - indicator)

  bool _isObscure1 = true;    // visible/invisible in password field
  bool _isObscure2 = true;    // visible/invisible in password_confirmed field
  final String _userid = Get.arguments;
  String? _newPassword;
  String? _newPasswordConfirmed;
  bool _isPasswordValidated = false;
  bool _isPasswordMatched = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password'.tr),
        centerTitle: true,
        backgroundColor: _color,
        leading: Builder(
          builder: (context) => IconButton(
              onPressed: () => Get.offAndToNamed('/login'),
              icon: const Icon(CupertinoIcons.xmark)),
        ),
      ),
      resizeToAvoidBottomInset: false,    // to avoid overflow, when keyboard comes up
      body: WillPopScope(
        child: _body(),
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
            const SizedBox(height: 40.0),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: Text('Please enter your new password'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: _color),
              ),
            ),
            const SizedBox(height: 30.0),
            /// Text field for new password
            _inputPassword(),
            const SizedBox(height: 15.0),
            /// text field for password confirmation
            _inputPasswordConfirm(),
            const SizedBox(height: 15.0),
            _confirmButton(),
            const SizedBox(height: 30.0),
          ]
      ),
    );
  }

  Widget _inputPassword() {
    return Column(
      children: [
        Row(
          children: [
            Text('Password'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400,),
            ),
            const Text(' *', style: TextStyle(color: Colors.red),),
          ],
        ),
        TextFormField(
          obscureText: _isObscure1,
          decoration: InputDecoration(
              hintText: 'Enter Password (> 6 characters)'.tr,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _isObscure1 = !_isObscure1),
                icon: _isObscure1 ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility),
              )
          ),
          onChanged: (text) {
            setState(() {_newPassword = text;});
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (val) {
            if (val != null && val.length < 6) {
              _isPasswordValidated = false;
              return 'Too short'.tr;
            } else {
              _isPasswordValidated = true;
              return null;
            }
          },
        ),
        const SizedBox(height: 10,),
      ],
    );
  }

  Widget _inputPasswordConfirm() {

    return Column(
      children: [
        Row(
          children: [
            Text('Password confirm'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400,),
            ),
            const Text(' *', style: TextStyle(color: Colors.red),),
          ],
        ),
        TextFormField(
          obscureText: _isObscure2,
          decoration: InputDecoration(
              hintText: 'Enter Password again to confirm'.tr,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _isObscure2 = !_isObscure2),
                icon: _isObscure2 ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility),
              )
          ),
          onChanged: (text) {
            setState(() {_newPasswordConfirmed = text;});
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (val) {
            if (val != null && val.length < 6) {
              _isPasswordMatched = false;
              return 'Too short'.tr;
            } else if (_newPassword != _newPasswordConfirmed){
              _isPasswordMatched = false;
              return 'Password not matched'.tr;
            } else {
              _isPasswordMatched = true;
              return null;
            }
          },
        ),
        const SizedBox(height: 10,),
      ],
    );
  }

  Widget _confirmButton() {
    return GestureDetector(
      onTap: () async {
        /// dismiss system keyboard when click
        FocusManager.instance.primaryFocus?.unfocus();  // Close system keyboard

        if (_isPasswordValidated && _isPasswordMatched && _newPassword != null) {
          setState(() => _isProgressing = true);    // set true for indicator, after loading set to false

          // await _fbService.updatePassword(_userid, _newPassword!).then((_) {
          //   String title = 'Succeed to reset password'.tr;
          //   String content = 'Your password has been changed. Please sign in with new password'.tr;
          //   setState(() => _isProgressing = false);    // set true for indicator, after loading set to false
          //   _showDialog(title, content);
          // }).catchError((error) {
          //   setState(() => _isProgressing = false);    // set true for indicator, after loading set to false
          //   Get.snackbar('error @ update password', '$error');
          // });
        } else {
          String title = 'Password not valid'.tr;
          String content = 'Please check your password and try again'.tr;
          _showDialog(title, content);
        }
      },
      child: Container(
        width: double.infinity,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: _isProgressing
            ? const CupertinoActivityIndicator(radius: 15, color: Colors.white,)
            : Text('Confirm'.tr, style: const TextStyle(fontSize: 20, color: Colors.white,
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
              onPressed: () => title == 'Succeed to reset password'.tr
                  ? Get.offAllNamed('/login')
                  : Get.back(),
            ),
          ],
        ),
      ),
    );
  }
}

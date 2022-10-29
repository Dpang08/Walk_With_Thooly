import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:walk_with_thooly/controller/firebase_service.dart';

import 'package:walk_with_thooly/controller/state_controller.dart';
import 'package:walk_with_thooly/resources/model/user_model.dart';
import 'package:walk_with_thooly/resources/kConstant.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({Key? key}) : super(key: key);

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final StateService _service = Get.put(StateService());
  final FirebaseService _fbService = Get.put(FirebaseService());

  late ScrollController _scrollController;
  final List<String> _fieldNames = ['Username', 'User ID', 'Password', 'Password Confirm', 'Email', 'Check ID'];
  bool _isObscure1 = true;    // visible/invisible in password field
  bool _isObscure2 = true;    // visible/invisible in password_confirmed field
  bool? _isIdExisted;         // id duplicate check in userid field
  bool _isProgressing = false;    // used for indicator   (false -> no indicator, true - indicator)

  /// variables for user info
  List<bool> _gender = [true, false];   // [male, female]
  String? _username;
  String? _userid;
  String? _useridChecked;   // it's final userid after check ID duplication
  String? _password;
  String? _passwordConfirmed;
  String? _email;


  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    /// reset text field validation
    _service.isAllValidated.value = [false, false, false, false, false, false];
    _service.isAllTermsAgreed = false.obs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text('Create account'.tr, style: TextStyle(color: kColor.appbarText),
        ),
        centerTitle: true,
        backgroundColor: kColor.appbar,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
              onPressed: () => Get.offAllNamed('/'),
              icon: Icon(CupertinoIcons.back, color: kColor.appbarMenu,)),
        ),
      ),
      backgroundColor: kColor.background,
      resizeToAvoidBottomInset: true,    // to avoid overflow, when keyboard comes up
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
        controller: _scrollController,
        children: [
          const SizedBox(height: 15.0),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text('Enter User Information'.tr,
                  style: TextStyle(color: kColor.loginContents, fontSize: 22),
                ),
                const SizedBox(width: 10,),
                Text('* required'.tr, style: const TextStyle(color: Colors.red, fontSize: 15),)
              ],
            ),
          ),
          const SizedBox(height: 30.0),
          /// Request for user information (name, gender, id, password, email)
          _inputUsername(),
          _fieldTitle('Gender'.tr),
          _genderSelect(),
          const SizedBox(height: 10.0),
          _inpUserId(),
          _inputPassword(),
          _inputPasswordConfirm(),
          _inputEmail(),
          const SizedBox(height: 10.0),

          _confirmButton(),
          const SizedBox(height: 25.0),
          /// another method for sign in/ sign up
          const SizedBox(height: 20,),
        ],
      ),
    );
  }

  Widget _inputUsername() {
    return Column(
      children: [
        Row(
          children: [
            Text('Username'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400,),
            ),
            const Text(' *', style: TextStyle(color: Colors.red),),
          ],
        ),
        TextFormField(
          decoration: InputDecoration(
              hintText: 'Enter your name (or nickname)'.tr,
          ),
          onChanged: (text) {
            setState(() {_username = text;});
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (val) {
            if (val != null && val.length < 3) {
              _service.isAllValidated[0] = false;    // 0 - username
              return 'Too short'.tr;
            } else {
              _service.isAllValidated[0] = true;   // 0 - username
              return null;
            }
          },
        ),
        const SizedBox(height: 10,),
      ],
    );
  }

  Widget _inpUserId() {
    return Column(
      children: [
        Row(
          children: [
            Text('User ID'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400,),
            ),
            const Text(' *', style: TextStyle(color: Colors.red),),
          ],
        ),
        TextFormField(
          decoration: InputDecoration(
            hintText: 'Enter new user ID'.tr,
            suffixIcon: _checkID(),
          ),
          onChanged: (text) {
            setState(() {
              _userid = text;
              if (_useridChecked != _userid) {
                _isIdExisted = null;
                _service.isAllValidated[5] = false;   // 5 - useridChecked
              }
            });
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (val) {
            if (val != null && val.length < 6) {
              _service.isAllValidated[1] = false;   // 1 - userid
              return 'Too short'.tr;
            } else {
              _service.isAllValidated[1] = true;   // 1 - userid
              return null;
            }
          },
        ),
        const SizedBox(height: 10,),
      ],
    );
  }

  Widget _checkID() {
    return SizedBox(
      width: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _isIdExisted !=null
              ? _isIdExisted!
                ? Container()   // in case ID existed - no check icon
                : Icon(Icons.check_circle_outlined, color: Colors.green[600],)    // if ID not existed - show check icon
              : Container(),
          TextButton(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Check ID'.tr,
                style: TextStyle(fontSize: 14, color: Colors.green[600]),),
            ),
            onPressed: () async {
              bool isExisted;
              String? title;
              String? content;

              if (_userid != null) {
                isExisted = await _fbService.checkID(_userid!);
                if (isExisted) {   // in case, ID existed -> can't use
                  title = 'ID - Existed'.tr;
                  content = 'It is being used by another user already. Please try different user ID.'.tr;
                  _showDialog(title, content, 'back');
                  _service.isAllValidated[5] = false;   // 5 - useridChecked
                } else {      // in case, ID is not exist -> ID good to use
                  _useridChecked = _userid;     // set checked userid
                  _service.isAllValidated[5] = true;   // 5 - useridChecked
                }
                setState(() => _isIdExisted = isExisted);
              }
            },
          ),
        ],
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
              suffixIcon: IconButton(
                onPressed: () => setState(() => _isObscure1 = !_isObscure1),
                icon: _isObscure1 ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility),
              )
          ),
          onTap: () {   // scroll up to see the rest items
            _scrollController.animateTo(MediaQuery.of(context).size.height * 0.3,
                duration: const Duration(milliseconds: 500), curve: Curves.ease);
          },
          onChanged: (text) {
            setState(() {_password = text;});
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (val) {
            if (val != null && val.length < 6) {
              _service.isAllValidated[2] = false;   // 2 - password
              return 'Too short'.tr;
            } else {
              _service.isAllValidated[2] = true;   // 2 - password
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
              suffixIcon: IconButton(
                onPressed: () => setState(() => _isObscure2 = !_isObscure2),
                icon: _isObscure2 ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility),
              )
          ),
          onChanged: (text) {
            setState(() {_passwordConfirmed = text;});
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (val) {
            if (val != null && val.length < 6) {
              _service.isAllValidated[3] = true;   // 3 - passwordConfirmed
              return 'Too short'.tr;
            } else if (_password != _passwordConfirmed){
              _service.isAllValidated[3] = true;   // 3 - passwordConfirmed
              return 'Password not matched'.tr;
            } else {
              _service.isAllValidated[3] = true;   // 3 - passwordConfirmed
              return null;
            }
          },
        ),
        const SizedBox(height: 10,),
      ],
    );
  }

  Widget _inputEmail() {
    return Column(
      children: [
        Row(
          children: [
            Text('Email'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400,),
            ),
            const Text(' *', style: TextStyle(color: Colors.red),),
          ],
        ),
        TextFormField(
            decoration: InputDecoration(
              hintText: 'Email'.tr,
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
              /// store the email validate status to service controller
              if (validate != null && validate) {
                _service.isAllValidated[4] = true;   // 4 - email
                return null;
              } else {
                _service.isAllValidated[4] = false;   // 4 - email
                return 'Invalid email'.tr;
              }
            }
        ),
        const SizedBox(height: 10,),
      ],
    );
  }

  Widget _fieldTitle(String title) {
    return Column(
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),),
            const Text(' *', style: TextStyle(color: Colors.red),),
          ],
        ),
        const SizedBox(height: 5,),
      ],
    );
  }

  Widget _genderSelect() {
    double width = MediaQuery.of(context).size.width * 0.86;
    return Center(
      child: ToggleButtons(
        fillColor: kColor.buttonColor,
        selectedColor: kColor.buttonText,
        color: Colors.grey,
        borderRadius: BorderRadius.circular(10),
        isSelected: _gender,
        onPressed: (value) {
          setState(() {
            if (value == 0) {
              _gender = [true, false];
            } else {
              _gender = [false, true];
            }
          });
        },
        children: [
          Container(
            alignment: Alignment.center,
            height: 40,
            width: width / 2,
            child: Text('Male'.tr, style: const TextStyle(fontSize: 18),
            ),
          ),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(left: 20, right: 20),
            height: 40,
            width: width / 2,
            child: Text('Female'.tr, style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmButton() {
    List<bool> allValidates = _service.isAllValidated;   // list of validation

    return GestureDetector(
      onTap: () async {
        /// dismiss system keyboard when click
        FocusManager.instance.primaryFocus?.unfocus();  // Close system keyboard

        if (allValidates.reduce((t, e) {return t & e;})) {  // in case all validates are true
          setState(() => _isProgressing = true);    // set true for indicator, after adding user set false to stop indicator

          UserModel newUser = UserModel(
            type: 'general',
            userid: _useridChecked,
            password: _password,
            username: _username,
            email: _email,
            gender: _gender[0] ? 'male' : 'female',
            totalKcal: 0,
            totalDist: 0,
            totalSteps: 0,
            totalDays: 0,
            createdAt: DateTime.now(),
          );
          /// save user info to state service, local storage and upload to firestore db
          await _fbService.addNewUser(newUser).then((_) {
            String title = 'Registration completed successfully'.tr;
            String content = 'Thank you for your registration'.tr;
            _showDialog(title, content, 'home');
          }).catchError((error) {
            Get.snackbar('error@firebase', '$error');
          });
          setState(() => _isProgressing = false);    // set false to stop indicator
        } else {    // if any of text field is false
          List<String> res = _falseFields();   // results of false validation
          String title = 'Please check the followings'.tr;
          String content = '${res.map((e) => e )}';
          _showDialog(title, content, 'back');
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

  List<String> _falseFields() {
    List<String> listFalse = [];
    int i = 0;

    List<bool> validates = _service.isAllValidated;
    for (var e in validates) {
      if (!e) {
        listFalse.add(_fieldNames[i].tr);
      }
      i++;
    }
    return listFalse;
  }

  Future _showDialog(String title, String content, String toDo) {
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
                onPressed: () {
                  if (toDo == 'back') {
                    Get.back();
                  } else {
                    Get.offAndToNamed('/');
                  }
                } ,
              ),
            ],
          ),
      ),
    );
  }

  // Widget _kakaoLogin() {
  //   return ListTile(
  //     tileColor: Colors.yellowAccent,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
  //     title: _isKakaoLoginProgressing
  //         ? Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               CupertinoActivityIndicator(
  //                 color: Colors.black87,
  //                 radius: 15,
  //               ),
  //               SizedBox(width: 40,)
  //             ],
  //           )
  //         : Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               Text('kakao_login'.tr,
  //                 style: TextStyle(
  //                   color: Colors.black,
  //                   fontWeight: FontWeight.w400,
  //                   fontSize: 18,
  //                 ),
  //               ),
  //               SizedBox(width: 40,)
  //             ]
  //         ),
  //     leading: Image.asset('assets/images/kakao_icon_50px.png', height: 30, width: 30,),
  //     onTap: () async {
  //       setState(() => _isKakaoLoginProgressing = true);
  //       await Future.delayed(Duration(seconds: 3)).then((_) =>
  //           setState(() => _isKakaoLoginProgressing = false)
  //       );
  //     },
  //   );
  // }
  //
  // Widget _facebookLogin() {
  //   return ListTile(
  //     tileColor: Colors.blue[800],
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
  //     title: _isKakaoLoginProgressing
  //         ? Row(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         CupertinoActivityIndicator(
  //           color: Colors.white,
  //           radius: 15,
  //         ),
  //         SizedBox(width: 40,)
  //       ],
  //     )
  //         : Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Text('facebook_login'.tr,
  //             style: TextStyle(
  //               color: Colors.white,
  //               fontWeight: FontWeight.w400,
  //               fontSize: 18,
  //             ),
  //           ),
  //           SizedBox(width: 40,)
  //         ]
  //     ),
  //     leading: Icon(FontAwesomeIcons.facebookSquare, color: Colors.white, size: 35),
  //     onTap: () async {
  //       setState(() => _isKakaoLoginProgressing = true);
  //       print('---> confirm button: busy - $_isKakaoLoginProgressing');
  //       await Future.delayed(Duration(seconds: 3)).then((_) =>
  //           setState(() => _isKakaoLoginProgressing = false)
  //       );
  //       print('---> confirm button: busy - $_isKakaoLoginProgressing');
  //     },
  //   );
  // }
  //
  // Widget _googleLogin() {
  //   return ListTile(
  //     tileColor: Colors.blue,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
  //     title: _isKakaoLoginProgressing
  //         ? Row(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         CupertinoActivityIndicator(
  //           color: Colors.white,
  //           radius: 15,
  //         ),
  //         SizedBox(width: 40,)
  //       ],
  //     )
  //         : Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Text('google_login'.tr,
  //             style: TextStyle(
  //               color: Colors.white,
  //               fontWeight: FontWeight.w400,
  //               fontSize: 18,
  //             ),
  //           ),
  //           SizedBox(width: 40,)
  //         ]
  //     ),
  //     leading: Icon(FontAwesomeIcons.google, color: Colors.white, size: 30),
  //     onTap: () async {
  //       setState(() => _isKakaoLoginProgressing = true);
  //       print('---> confirm button: busy - $_isKakaoLoginProgressing');
  //       await Future.delayed(Duration(seconds: 3)).then((_) =>
  //           setState(() => _isKakaoLoginProgressing = false)
  //       );
  //       print('---> confirm button: busy - $_isKakaoLoginProgressing');
  //     },
  //   );
  // }

}

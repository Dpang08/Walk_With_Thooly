import 'dart:math';
import 'dart:typed_data';
import 'package:get_storage/get_storage.dart';

import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:walk_with_thooly/resources/kConstant.dart';
import 'package:walk_with_thooly/resources/model/user_model.dart';
import 'package:walk_with_thooly/resources/model/chat_model.dart';
import 'state_controller.dart';
import 'package:walk_with_thooly/resources/model/walking_model.dart';

final StateService _service = Get.put(StateService());
final GetStorage _storage = Get.put(GetStorage(kStorageKey.CONTAINER));

class FirebaseService extends GetxService {
  RxList<UserModel> top10Friends = <UserModel>[].obs;

  final CollectionReference _reference = FirebaseFirestore.instance
      .collection(FbCollection.USERS);

  /// add new user with user info
  Future<void> addNewUser(UserModel newUser) async {
    /// save to state controller and local storage
    _service.addNewUser(newUser);

    /// upload to firestore db
    final data = newUser.toFirestore();
    FirebaseFirestore.instance.enableNetwork()
        .then((_) => _reference
            .doc(newUser.userid) // user id
            .set(data)
    ).catchError((err) {
      Get.snackbar('error@firebase', '$err');
    });
  }

  /// add friend to follow
  Future<void> addFriend(String userid) async {
    Map<String, dynamic> data = {'timeStamp': DateTime.now().toIso8601String()};

    await _reference
        .doc(_service.userInfo.value.userid)
        .collection(FbCollection.FRIENDS)
        .doc(userid)
        .set(data)
        .onError((err, stackTrace) => Get.snackbar('error@firebase', 'add friend>>$err'));
  }

  /// update(change) the password
  Future<void> updatePassword(String userid, String newPassword) async {
    Map<String, String> data = {'password': newPassword};
    await _reference
        .doc(userid)
        .update(data);
  }

  /// update(change) the password
  Future<void> updateUserSettings() async {
    Map<String, int> data = {
      'height': _service.userInfo.value.height!,
      'weight': _service.userInfo.value.weight!
    };
    /// save to local storage to reuse for auto login
    _storage.write(kStorageKey.USERINFO, _service.userInfo.value.toFirestore());
    await _reference
        .doc(_service.userInfo.value.userid)
        .update(data);
  }

  /// check ID if existed already in the database
  Future<bool> checkID(String userid) async {
    bool isExisted = false;
    QuerySnapshot snapshot = await _reference.get();
    final ids = snapshot.docs.map((e) => e.id).toList();
    isExisted = ids.contains(userid);
    return isExisted;
  }

  /// Login to match userid and password -> if found get userinfo to store locally
  Future<List<bool>> findUserWithEmail(String? userid, String? email) async {
    bool isUserFound = false;
    bool isEmailMatched = false;
    final firestore = FirebaseFirestore.instance;
    final userFound = await firestore
        .collection(FbCollection.USERS)
        .where('userid', isEqualTo: userid)
        .get();
    if (userFound.docs.isNotEmpty) {
      isUserFound = true;
      final data = userFound.docs.map((e) => e.data()).toList();
      for (var e in data) {
        if (email == e['email']) {
          isEmailMatched = true;
        }
      }
    }

    ///  if userid & password matched -> get userinfo and store to local
    return [isUserFound, isEmailMatched];
  }

  /// Login to match userid and password -> if found get userinfo to store locally
  Future<List<bool>> findUserWithPassword(String userid,
      String password) async {
    bool isIdFound = false;
    bool isPasswordMatched = false;

    final firestore = FirebaseFirestore.instance;
    final userFound = await firestore
        .collection(FbCollection.USERS)
        .where('userid', isEqualTo: userid)
        .get();
    if (userFound.docs.isNotEmpty) { // userid found
      isIdFound = true;
      final data = userFound.docs.map((e) => e.data()).toList();
      for (var e in data) {
        if (password == e['password']) { // password matched
          isPasswordMatched = true;
        }
      }
    }

    ///  if userid & password matched -> get userinfo and store to local
    if (isIdFound && isPasswordMatched) {
      UserModel userInfo = UserModel.fromFirestore(userFound.docs.first);
      _service.userInfo.value = userInfo; //save to state controller
      _getProfileImageFromFb(); // get profile image from firebase storage and save to local
      _service.userInfo.value.printAll(); // print to check found user info
    }
    return [isIdFound, isPasswordMatched];
  }

  Future<List<UserModel>> getAllUsers() async {
    if (_service.userInfo.value.userid !=null && _service.userInfo.value.userid!.isNotEmpty) {
      QuerySnapshot snapshot = await _reference.get();
      List<UserModel> allData = snapshot.docs.map((e) => UserModel.fromFirestore(e)).toList();
      allData.sort((b, a) => a.totalKcal!.compareTo(b.totalKcal!));
      return allData;
    } else {
      return [];    // user가 로그아웃하거나, 로그인 하지 않은 상태에서는 읽어오지 않음
    }
  }

  Future<List<UserModel>> getAllFriends() async {
    /// user 가 로그인 되어 있는 상태에서만 친구 조회 가능
    if (_service.userInfo.value.userid !=null && _service.userInfo.value.userid!.isNotEmpty) {
      /// get list of friends
      QuerySnapshot snapshot = await _reference
          .doc(_service.userInfo.value.userid)
          .collection(FbCollection.FRIENDS)
          .get();
      List<String> friendsId = snapshot.docs.map((e) => e.id).toList();
      /// get user info of friends
      List<UserModel> friends = [];
      for (var e in friendsId) {
        DocumentSnapshot snapshot = await _reference.doc(e).get();
        friends.add(UserModel.fromFirestore(snapshot));
      }
      /// including myself in the list to compare
      friends.add(_service.userInfo.value);
      /// sorting friends by total kcal
      friends.sort((b, a) => a.totalKcal!.compareTo(b.totalKcal!));
      return friends;
    } else {
      return [];
    }
  }

  Future<List<UserModel>> getTop10Friends() async {
    /// user 가 로그인 되어 있는 상태에서만 친구 조회 가능
    if (_service.userInfo.value.userid !=null && _service.userInfo.value.userid!.isNotEmpty) {
      /// get all friends
      List<UserModel> friends = [];

      friends = await getAllFriends();

      if (friends.isNotEmpty) {
        /// include myself in friends list to calc top 10
        friends.add(_service.userInfo.value);
        /// sort top 10
        int size = friends.length;
        if (size > 10) {
          size = 10;
        }
        if (size > 1) {
          friends.sort((b, a) => a.totalKcal!.compareTo(b.totalKcal!));
          top10Friends.value = friends.sublist(0, size);
          return friends.sublist(0, size);
        } else {
          return [];
        }
      } else {
        return [];
      }
    } else {
      return [];
    }
  }

  /// send message to other user
  Future<void> sendMessage(ChatModel message) async {
    final data = message.toFirestore();

    FirebaseFirestore.instance.enableNetwork()
        .then((_) =>
        FirebaseFirestore.instance
            .collection(FbCollection.USERS)
            .doc(_service.messageBuddy.value.userid)
            .collection(FbCollection.MESSAGE)
            .doc(DateTime.now().toIso8601String())
            .set(data)
    );
  }

  /// get all messages
  Future<List<ChatModel>> getAllMessages() async {
    final snapshot = await FirebaseFirestore.instance
            .collection(FbCollection.USERS)
            .doc(_service.userInfo.value.userid)
            .collection(FbCollection.MESSAGE)
            .get();
    final data = snapshot.docs.map((e) => ChatModel.fromFirestore(e)).toList();
    return data;
  }

  Future<void> uploadProfileImageToFb() async {
    if (_service.userInfo.value.userid != null) {
      /// create a reference to the file
      Reference storageRef = FirebaseStorage.instance.ref()
          .child('profile')
          .child('${_service.userInfo.value.userid!}.jpg');

      /// upload user thumbnail image to firebase storage
      if (_service.userThumbnail.value.isNotEmpty) {
        File imageFile = File(_service.userThumbnail.value);
        UploadTask uploadTask = storageRef.putFile(imageFile);
        String url;
        /// get image url from firebase storage
        await uploadTask.whenComplete(() {
          storageRef.getDownloadURL().then((imageUrl) {
            url = imageUrl.toString();
            /// upload image url to firestore
            if (url.isNotEmpty) {
              Map<String, String> data = {'thumbnail': url};
              FirebaseFirestore.instance.enableNetwork()
                  .then((_) => _reference
                  .doc(_service.userInfo.value.userid)  // user id
                  .update(data)
              ).catchError((err) {
                Get.snackbar('error@firebase', '$err');
              });
            }
          });
        });
      }
    }
  }

  Future<bool> _getProfileImageFromFb() async {
    if (_service.userInfo.value.userid != null) {
      /// create a reference to the file
      Reference storageRef = FirebaseStorage.instance.ref()
          .child('profile')
          .child('${_service.userInfo.value.userid!}.jpg');

      /// get profile image from firebase storage
      const oneMegabyte = 1024 * 1024;
      try {
        final Uint8List? imageFile = await storageRef.getData(oneMegabyte)
            .catchError((_) {});
        /// save into local storage
        if (imageFile != null) {
          await saveImageToLocal(imageFile);
          return true;
        } else {
          return false;
        }
      } on FirebaseException catch (err) {
        Get.snackbar('Error@firebase', '$err');
        return false;
      }
    } else { // no such user id
      return false;
    }
  }

  Future<String> downloadJournal() async {
    String output = '';
    /// create a reference to the file
    Reference storageRef = FirebaseStorage.instance.ref()
        .child('journal')
        .child(kConst.fileJournal);

    Directory appDir = await getApplicationDocumentsDirectory();
    final String filePath = '${appDir.path}/${storageRef.name}';
    File file = File(filePath);

    /// get file from firebase storage and save to local as file
    try {
      await storageRef.writeToFile(file);
    } on FirebaseException catch (err) {
      Get.snackbar('error@firebase', 'journal>>$err');
    }

    bool isExisted = await file.exists();
    if (isExisted) {
      /// save to controller and GetX  storage
      _service.fileJournal.value = filePath;
      /// read file as text
      output = file.readAsStringSync();
    }

    return output;
  }

  Future<void> saveImageToLocal(Uint8List image) async {
    Directory appDir = await getApplicationDocumentsDirectory();
    String imagePath = '${appDir.path}/${kConst.thumbnailImage}';
    File file = File(imagePath);

    file.writeAsBytes(image).then((_) {
      /// save local image path to service controller
      _service.userThumbnail.value = imagePath;
      /// save thumbnail path to getx storage
      _storage.write(kStorageKey.THUMBNAIL, imagePath);
    }).catchError((err) {
      Get.snackbar('Error@filesystem', '$err');
    });
  }

  Future<bool> loadImageFromLocal() async {
    Directory appDir = await getApplicationDocumentsDirectory();
    String imagePath = '${appDir.path}/${kConst.thumbnailImage}';
    bool isExisted = await File(imagePath).exists();
    if (isExisted) {
      _service.userThumbnail.value = imagePath;
      return true;
    } else {
      return false;
    }
  }

  Future<void> deleteImageFromLocal() async {
    Directory appDir = await getApplicationDocumentsDirectory();
    String imagePath = '${appDir.path}/${kConst.thumbnailImage}';
    File file = File(imagePath);

    bool isExisted = await file.exists();
    if (isExisted) {
      file.delete();
    }
  }

  /// test only --> todo remove for release
  Future<void> generateDummyUsers() async {
    Map<String, dynamic> userinfo = {
      'type': 'admin',
      'userid': 'master',
      'username': 'master',
      'gender': 'female',
      'password': '111111',
      'thumbnail': '',
      'email': 'thoolyMaster@email.com',
      'height': 150 + Random().nextInt(40),
      'weight': 50 + Random().nextInt(50),
      'totalKcal': 600 + Random().nextInt(1000),
      'createdAt': DateTime.now().toIso8601String(),
      'totalDays': 32 + Random().nextInt(100),
      'streakDays': 1 + Random().nextInt(30),
      'totalDist': 40 + Random().nextDouble() * 50,
      'streakDist': 10 + Random().nextDouble() * 30,
      'startAt': '',
      'startStreakAt': '',
    };
    FirebaseFirestore.instance.enableNetwork()
        .then((_) =>
        FirebaseFirestore.instance
            .collection(FbCollection.USERS)
            .doc('master')
            .set(userinfo)
    );

    for (int i = 1; i <= 30; i++) {
      String id = 'user#$i';
      String name = 'username#$i';
      String gender = 'male';
      String type = 'general';

      if (i % 2 == 0) {
        gender = 'male'; // even number
      } else {
        gender = 'female';
      }

      Map<String, dynamic> userinfo = {
        'type': type,
        'userid': id,
        'username': name,
        'gender': gender,
        'password': '111111',
        'email': '$name@email.com',
        'height': 150 + Random().nextInt(40),
        'weight': 50 + Random().nextInt(50),
        'totalKcal': 600 + Random().nextInt(1000),
        'thumbnail': '',
        'createdAt': DateTime.now().toIso8601String(),
        'totalDays': 32 + Random().nextInt(100),
        'streakDays': 10 + Random().nextInt(30),
        'totalDist': 40 + Random().nextDouble() * 50,
        'streakDist': 10 + Random().nextDouble() * 30,
        'startAt': '',
        'startStreakAt': '',
      };

      FirebaseFirestore.instance.enableNetwork()
          .then((_) =>
          FirebaseFirestore.instance
              .collection(FbCollection.USERS)
              .doc(id)
              .set(userinfo)
      );
    }
  }

  void generateDummyFriends() {
    Map<String, dynamic> d = {'timeStamp':''};
    for (int i = 1; i <= 15; i++) {
      String id = 'user#$i';
      _reference
          .doc('master')
          .collection(FbCollection.FRIENDS)
          .doc(id)
          .set(d);
    }
  }

  void generateDummyMessage() {
    for (int i=1; i <=10; i++) {
      Map<String, dynamic> data = {
        'message': 'message from user#$i',
        'sender': 'user#$i',
        'timeAt': DateTime.now().toIso8601String(),
      };

      FirebaseFirestore.instance.enableNetwork()
          .then((_) =>
          FirebaseFirestore.instance
              .collection(FbCollection.USERS)
              .doc('master')
              .collection(FbCollection.MESSAGE)
              .doc(DateTime.now().toIso8601String())
              .set(data)
      );
    }

  }

  void generateDummyWalking() {
    /// sample for master id
    for (int i = 1; i <= 30; i++) {
      String id;

      id = DateTime(2022,10,i,12,1,0,0,0).toIso8601String();

      Map<String, dynamic> data = {
        'timeStartAt': DateTime(2022,10,i,12,0,0,0,0).toIso8601String(),
        'timeEndAt': DateTime(2022,10,i,12,12,0,0,0).toIso8601String(),
        'distance': Random().nextDouble() * 10,
        'steps': Random().nextInt(7000) + 1500,
        'kcal': Random().nextInt(200) + 100,
      };

      FirebaseFirestore.instance.enableNetwork()
          .then((_) =>
          FirebaseFirestore.instance
              .collection(FbCollection.USERS)
              .doc('master')
              .collection(FbCollection.WALKING)
              .doc(id).set(data)
      );
    }

    /// sample for user friends
    for (int i = 1; i <= 30; i++) {
      String userid = 'user#$i';
      for (int i = 1; i <= 30; i++) {
        String id;

        id = DateTime(2022,10,i,12,1,0,0,0).toIso8601String();

        Map<String, dynamic> data = {
          'timeStartAt': DateTime(2022,10,i,12,0,0,0,0).toIso8601String(),
          'timeEndAt': DateTime(2022,10,i,12,12,0,0,0).toIso8601String(),
          'distance': Random().nextDouble() * 10,
          'steps': Random().nextInt(7000) + 1500,
          'kcal': Random().nextInt(200) + 100,
        };

        FirebaseFirestore.instance.enableNetwork()
            .then((_) =>
            FirebaseFirestore.instance
                .collection(FbCollection.USERS)
                .doc(userid)
                .collection(FbCollection.WALKING)
                .doc(id).set(data)
        );
      }
    }

  }

}

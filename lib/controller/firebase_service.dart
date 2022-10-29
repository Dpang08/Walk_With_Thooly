import 'dart:math';
import 'dart:typed_data';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:walk_with_thooly/resources/kConstant.dart';
import 'package:walk_with_thooly/resources/model/place_model.dart';
import 'package:walk_with_thooly/resources/model/user_model.dart';
import 'package:walk_with_thooly/resources/model/chat_model.dart';
import 'package:walk_with_thooly/resources/model/walking_model.dart';
import 'state_controller.dart';

final StateService _service = Get.put(StateService());
final GetStorage _storage = Get.put(GetStorage(kStorageKey.CONTAINER));

class FirebaseService extends GetxService {
  var uuid = const Uuid();

  final CollectionReference _userReference = FirebaseFirestore.instance
      .collection(FbCollection.USERS);

  /// add new user with user info
  Future<void> addNewUser(UserModel newUser) async {
    /// save to state controller and local storage
    _service.addNewUser(newUser);

    /// upload to firestore db
    final data = newUser.toFirestore();
    FirebaseFirestore.instance.enableNetwork()
        .then((_) => _userReference
            .doc(newUser.userid) // user id
            .set(data)
    ).catchError((err) {
      Get.snackbar('error@firebase', '$err');
    });
  }

  /// add friend to follow
  Future<void> addFriend(String userid) async {
    Map<String, dynamic> data = {'timeStamp': DateTime.now().toIso8601String()};

    await _userReference
        .doc(_service.userInfo.value.userid)
        .collection(FbCollection.FRIENDS)
        .doc(userid)
        .set(data)
        .onError((err, stackTrace) => Get.snackbar('error@firebase', 'add friend>>$err'));
  }

  /// update(change) the password
  Future<void> updatePassword(String userid, String newPassword) async {
    Map<String, String> data = {'password': newPassword};
    await _userReference
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
    await _userReference
        .doc(_service.userInfo.value.userid)
        .update(data);
  }

  /// check ID if existed already in the database
  Future<bool> checkID(String userid) async {
    bool isExisted = false;
    QuerySnapshot snapshot = await _userReference.get();
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
      _getProfileImageFromFb();   // get profile image from firebase storage and save to local
    }
    return [isIdFound, isPasswordMatched];
  }

  Future<void> getMyWalkData() async {
    DateTime now = DateTime.now();
    String lastOneMonth = DateTime(now.year, now.month - 1, now.day, 0,0,0,0,0).toIso8601String();
    List<DateTime> walkingDays = [];

    if (_service.userInfo.value.userid !=null && _service.userInfo.value.userid!.isNotEmpty) {
      double sumKcal = 0;
      double sumDist = 0;
      /// get walking model for last one month
      QuerySnapshot data = await _userReference
          .doc(_service.userInfo.value.userid)
          .collection(FbCollection.WALKING)
          .where('timeStartAt', isGreaterThanOrEqualTo: lastOneMonth)
          .get();
      /// calc sum of kcal and distance for last one month
      List<WalkingModel> walkingData = data.docs.map((e) =>
          WalkingModel.fromFirestore(e)).toList();
      for (var d in walkingData) {
        sumKcal += d.kcal!;
        sumDist += d.distance!;
        walkingDays.add(d.timeStartAt!);
      }
      /// calc total days
      _service.userInfo.value.totalDays = walkingData.length;
      /// calc streak
      walkingDays.sort((b, a) => a.compareTo(b));
      List<int> streak = [];
      for (var i=0; i < walkingDays.length; i++) {    // 연속된 날짜 1, 아니면 0으로 리스트 만들기
        if (i > 0 && i < walkingDays.length) {
          if (walkingDays[i-1].day - walkingDays[i].day == 1) {
            streak.add(1);
          } else {
            streak.add(0);
          }
        }
      }
      int count = 0;
      int maxCount = 0;
      for (var i=0; i < streak.length-1; i++) {    // 연속된 날짜 구하기
        if (streak[i] == streak[i+1]) {
          count += 1;
        } else {
          if (maxCount < count) {
            maxCount = count;
            count = 0;
          }
        }
      }
      if (maxCount <= count) {
        maxCount = count;
      }
      /// set streak days
      _service.userInfo.value.streakDays = maxCount == 0 ? 0 : maxCount + 2;  // max + 1 total streak
      /// save walking model result (total kcal, total sum)
      _service.userInfo.value.totalKcal = sumKcal;
      _service.userInfo.value.totalDist = sumDist;
      /// update users to firestore
      _updateUserToFirestore();
    }
  }

  Future<void> _updateUserToFirestore() async {
    await _userReference
        .doc(_service.userInfo.value.userid)
        .update(_service.userInfo.value.toFirestore())
        .catchError((err) => Get.snackbar('error@firestore', 'update: $err'));
  }

  Future<List<UserModel>> getAllUsers() async {
    List<UserModel> allUsers = [];

    if (_service.userInfo.value.userid !=null && _service.userInfo.value.userid!.isNotEmpty) {
      if (_service.allUsers.isEmpty) {
        QuerySnapshot snapshot = await _userReference.get();
        List<UserModel> users = snapshot.docs.map((e) => UserModel.fromFirestore(e)).toList();
        // allUsers = snapshot.docs.map((e) => UserModel.fromFirestore(e)).toList();
        /// sorting users by total kcal
        // users.sort((b, a) => a.totalKcal!.compareTo(b.totalKcal!));
        /// save to service controller
        // _service.allUsers.value = users;

        if (users.isNotEmpty) {
          for (var e in users) {
            UserModel userUpdated = await _getWalkingModel(e);
            allUsers.add(userUpdated);
          }
          /// sorting users by total kcal
          allUsers.sort((b, a) => a.totalKcal!.compareTo(b.totalKcal!));
          /// save to service controller
          _service.allUsers.value = allUsers;
        }

      } else {
        allUsers = _service.allUsers;
      }
    }
    return allUsers;
  }

  Future<UserModel> _getWalkingModel(UserModel userModel) async {
    DateTime now = DateTime.now();
    String lastOneMonth = DateTime(now.year, now.month - 1, now.day, 0,0,0,0,0).toIso8601String();

    double sumKcal = 0;
    double sumDist = 0;
    /// get walking model for last one month
    QuerySnapshot data = await _userReference
        .doc(userModel.userid)
        .collection(FbCollection.WALKING)
        .where('timeStartAt', isGreaterThanOrEqualTo: lastOneMonth)
        .get();
    /// calc sum of kcal and distance for last one month
    List<WalkingModel> walkingData = data.docs.map((e) =>
        WalkingModel.fromFirestore(e)).toList();
    for (var d in walkingData) {
      sumKcal += d.kcal!;
      sumDist += d.distance!;
    }
    /// save walking model result (total kcal, total sum)
    userModel.totalKcal = sumKcal;
    userModel.totalDist = sumDist;
    return userModel;
  }

  Future<List<UserModel>> getAllFriends() async {
    List<UserModel> friends = [];
    /// user 가 로그인 되어 있는 상태에서만 친구 조회 가능
    if (_service.userInfo.value.userid !=null && _service.userInfo.value.userid!.isNotEmpty) {
      if (_service.allFriends.isEmpty) {
        /// get list of friends
        QuerySnapshot snapshot = await _userReference
            .doc(_service.userInfo.value.userid)
            .collection(FbCollection.FRIENDS)
            .get();
        List<String> friendsId = snapshot.docs.map((e) => e.id).toList();
        /// get user info of friends
        if (friendsId.isNotEmpty) {
          for (var e in friendsId) {    // user model 읽어오기
            /// get user Model
            DocumentSnapshot snapshot = await _userReference.doc(e).get();
            UserModel user = UserModel.fromFirestore(snapshot);
            /// get walking model of friends
            UserModel userUpdated = await _getWalkingModel(user);
            /// 친구 추가
            friends.add(userUpdated);
            // friends.add(user);
          }
          /// including myself in the list to compare
          UserModel myModelUpdated = await _getWalkingModel(_service.userInfo.value);
          /// 친구 추가 리스트에 '나' 추가
          friends.add(myModelUpdated);
          /// sorting friends by total kcal
          friends.sort((b, a) => a.totalKcal!.compareTo(b.totalKcal!));
          // friends.sort((b, a) => a.totalKcal!.compareTo(b.totalKcal!));
          /// save to service controller
          _service.allFriends.value = friends;
        }
      } else {
        friends = _service.allFriends;
      }
    }
    return friends;
  }

  Future<List<UserModel>> getTop10Friends() async {
    List<UserModel> friends = [];
    /// user 가 로그인 되어 있는 상태에서만 친구 조회 가능
    if (_service.userInfo.value.userid !=null && _service.userInfo.value.userid!.isNotEmpty) {
      if (_service.top10Friends.isEmpty) {
        if (_service.allFriends.isEmpty) {
          friends = await getAllFriends();
        } else {
          friends = _service.allFriends;
        }

        /// sort top 10
        int size = friends.length;
        if (size > 10) {
          size = 10;
        }
        if (size > 1) {
          friends.sort((b, a) => a.totalKcal!.compareTo(b.totalKcal!));
          friends = friends.sublist(0, size);
          /// save to service controller
          _service.top10Friends.value = friends;
        }
      } else {
        friends = _service.top10Friends;
      }
    }
    return friends;
  }

  Future<void> updateWalkingModel(WalkingModel walk) async {
    if (_service.userInfo.value.userid != null) {
      String id = DateTime.now().toIso8601String();

      FirebaseFirestore.instance.enableNetwork()
          .then((_) => FirebaseFirestore.instance
          .collection(FbCollection.USERS)
          .doc(_service.userInfo.value.userid)
          .collection(FbCollection.WALKING)
          .doc(id).set(walk.toFirestore())
          .catchError((err) {
        Get.snackbar('error@firebase', 'walking: $err');
      })
      );
    }
  }

  Future<void> uploadPlace() async {
    if (_service.userInfo.value.userid != null) {
      PlaceModel place = _service.placeMarked.value;
      /// create a reference to the file
      Reference storageRef = FirebaseStorage.instance.ref()
          .child('places')
          .child('${uuid.v4()}.jpg');

      if (_service.imagePlace.value.isNotEmpty) {
        File imageFile = File(_service.imagePlace.value);

        /// upload image to firebase storage
        UploadTask uploadTask = storageRef.putFile(imageFile);
        String url;

        /// get image url from firebase storage
        await uploadTask.whenComplete(() {
          storageRef.getDownloadURL().then((imageUrl) {
            url = imageUrl.toString();
            /// upload image url to firestore
            if (url.isNotEmpty) {
              place.imageUrl = url;
              FirebaseFirestore.instance.enableNetwork()
                  .then((_) =>
                  FirebaseFirestore.instance
                      .collection(FbCollection.PLACES)
                      .doc()
                      .set(place.toFirestore())
              ).catchError((err) {
                Get.snackbar('error@firebase', 'places: $err');
              });
            }
          });
        });
      }
    }
  }

  Future<void> getPlaces() async {
    if (_service.userInfo.value.userid !=null && _service.userInfo.value.userid!.isNotEmpty) {
      if (_service.places.isEmpty) {
        QuerySnapshot snapshot = await FirebaseFirestore.instance.collection(FbCollection.PLACES).get();
        List<PlaceModel> places = snapshot.docs.map((e) => PlaceModel.fromFirestore(e)).toList();
        /// make list of markers to show
        for (var e in places) {
          Marker marker = Marker(
            markerId: MarkerId('${e.lat}'),
            position: LatLng(e.lat!, e.lng!),
          );
          _service.markers.add(marker);
        }
      }
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
                  .then((_) => _userReference
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
    UserModel masterUser = UserModel(
        type: 'admin',
        userid: 'master',
        username: 'master',
        gender: 'female',
        password: '111111',
        thumbnail: '',
        email: 'thoolyMaster@email.com',
        createdAt: DateTime.now(),
    );
    FirebaseFirestore.instance.enableNetwork()
        .then((_) =>
        FirebaseFirestore.instance
            .collection(FbCollection.USERS)
            .doc('master')
            .set(masterUser.toFirestore())
    );

    for (int i = 1; i <= 20; i++) {
      String id = 'user#$i';
      String name = 'username#$i';
      String gender = 'male';
      String type = 'general';

      if (i % 2 == 0) {
        gender = 'male'; // even number
      } else {
        gender = 'female';
      }

      UserModel userinfo = UserModel(
        type: type,
        userid: id,
        username: name,
        gender: gender,
        password: '111111',
        thumbnail: '',
        email: '$name@email.com',
        createdAt: DateTime.now(),
      );

      FirebaseFirestore.instance.enableNetwork()
          .then((_) =>
          FirebaseFirestore.instance
              .collection(FbCollection.USERS)
              .doc(id)
              .set(userinfo.toFirestore())
      );
    }
  }

  void generateDummyFriends() {
    Map<String, dynamic> d = {'timeStamp':DateTime.now().toIso8601String()};
    for (int i = 1; i <= 15; i++) {
      String id = 'user#$i';
      _userReference
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
    for (int i = 1; i <= 20; i++) {
      String id;
      int day;

      if (i % 8 == 0) {
        id = DateTime(2022,09,i,12,1,0,0,0).toIso8601String();
        day = 9;
      } else {
        id = DateTime(2022,10,i,12,1,0,0,0).toIso8601String();
        day = 10;
      }

      Map<String, dynamic> data = {
        'timeStartAt': DateTime(2022,day,i,12,0,0,0,0).toIso8601String(),
        'timeEndAt': DateTime(2022,day,i,12,12,0,0,0).toIso8601String(),
        'distance': Random().nextDouble() * 10,
        'steps': Random().nextInt(7000) + 1500,
        'kcal': 100 + Random().nextDouble() * 500,
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
    // for (int i = 1; i <= 10; i++) {
    //   String userid = 'user#$i';
    //   for (int i = 1; i <= 20; i++) {
    //     String id;
    //
    //     id = DateTime(2022,10,i,12,1,0,0,0).toIso8601String();
    //
    //     Map<String, dynamic> data = {
    //       'timeStartAt': DateTime(2022,10,i,12,0,0,0,0).toIso8601String(),
    //       'timeEndAt': DateTime(2022,10,i,12,12,0,0,0).toIso8601String(),
    //       'distance': Random().nextDouble() * 10,
    //       'steps': Random().nextInt(7000) + 1500,
    //       'kcal': 100 + Random().nextDouble() * 500,
    //     };
    //
    //     FirebaseFirestore.instance.enableNetwork()
    //         .then((_) =>
    //         FirebaseFirestore.instance
    //             .collection(FbCollection.USERS)
    //             .doc(userid)
    //             .collection(FbCollection.WALKING)
    //             .doc(id).set(data)
    //     );
    //   }
    // }
  }

}

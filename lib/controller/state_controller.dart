import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:walk_with_thooly/controller/firebase_service.dart';
import 'package:walk_with_thooly/resources/model/user_model.dart';
import 'package:walk_with_thooly/resources/model/chat_model.dart';
import 'package:walk_with_thooly/resources/kConstant.dart';
import 'package:walk_with_thooly/resources/model/walking_model.dart';
import 'package:walk_with_thooly/resources/model/place_model.dart';

final GetStorage _storage = Get.put(GetStorage());
final FirebaseService _fbService = Get.put(FirebaseService());

class StateService extends GetxService {
  /// control variables
  RxInt navIndex = 0.obs;   // navigation index
  Rx<ElapsedTime> elapsedTime = ElapsedTime(seconds: 0).obs;
  RxDouble walkingDistance = (0.0).obs;
  /// messaging with friends
  Rx<UserModel> messageBuddy = UserModel().obs;
  /// userinfo and login
  RxString userThumbnail = ''.obs;    // 사용자 thumbnail 이미지 (로컬 경로 저장)
  RxBool isAllTermsAgreed = false.obs;
  Rx<UserModel> userInfo = UserModel().obs;
  Rx<WalkingModel> myWalk = WalkingModel().obs;
  Rx<ChatModel> chatMessage = ChatModel().obs;
  RxList<UserModel> top10Friends = <UserModel>[].obs;
  RxList<UserModel> allFriends = <UserModel>[].obs;
  RxList<UserModel> allUsers = <UserModel>[].obs;
  RxString fileJournal = ''.obs;    // journal local file path
  // [0-username, 1-userid, 2-password, 3-passwordConfirmed, 4-email, 5-check ID]
  RxList<bool> isAllValidated = [false, false, false, false, false, false].obs;
  /// pedometer
  RxInt myHeight = 175.obs;
  RxInt myWeight = 65.obs;
  RxString journal = ''.obs;    // save downloaded journal text
  RxBool isPedometerStarted = false.obs;    // 걷기 시작 했는지 확인 true -> pedometer 초기값 한 번만 설정하도록 -> false
  RxInt initStep = 0.obs;   // pedometer의 초기값 -> 이후 이 값을 offset으로 사용해서 현제 값 계산
  RxInt steps = 0.obs;
  RxDouble distance = (0.0).obs;    // in km
  RxInt stepsResult = 0.obs;    // 최종 걸음수 저장
  RxDouble kcal = (0.0).obs;
  RxInt stepsFromOS = 0.obs;    // OS 에서 읽어오는 걸음수 (초기화 되지 않음)
  RxString imagePlace = ''.obs;   // 장소 사진 저장
  Rx<PlaceModel> placeMarked = PlaceModel().obs;
  RxList<PlaceModel> places = <PlaceModel>[].obs;
  RxSet<Marker> markers = <Marker>{}.obs;

  void addPlace() {
    places.add(placeMarked.value);
    markers.add(_createMarker());
  }

  Marker _createMarker() {
    return Marker(
      markerId: MarkerId('${placeMarked.value.lat}'),
      position: LatLng(placeMarked.value.lat!, placeMarked.value.lng!),
    );
  }

  void addNewUser(UserModel newUser) {
    userInfo.value = newUser;
    _storage.write(kStorageKey.USERINFO, newUser.toFirestore());   // save userinfo in getStorage
  }

  void resetLogout() async {
    /// reset service variables
    _reset();
    /// delete userinfo from local storage
    _storage.remove(kStorageKey.USERINFO);
    _storage.remove(kStorageKey.THUMBNAIL);
    /// delete thumbnail image from local storage
    await _fbService.deleteImageFromLocal();
  }

  void _reset() {
    userInfo.value.reset();       // reset user
    userThumbnail.value = '';   // thumbnail
    isAllTermsAgreed.value = false;
    isAllValidated.value = [false, false, false, false, false, false];
    top10Friends.value = [];
  }

  void resetWalking() {
    steps.value = 0;
    distance.value = 0;
    stepsResult.value = 0;
    kcal.value = 0;
  }

  void printAll() {
    userInfo.value.printAll();
    String thumb = '';
    if (_storage.read(kStorageKey.THUMBNAIL) != null) {
      thumb = _storage.read(kStorageKey.THUMBNAIL);
    }
    debugPrint('\t\t* thumbnail storage: \t$thumb');
    debugPrint('------------------- end ------------------');
  }

}

class ElapsedTime {
  int seconds;

  ElapsedTime({
    required this.seconds,
  });

  @override
  String toString() {
    String hh;
    String mm;
    String ss;
    /// convert in seconds to hh:mm:ss
    int hour = seconds ~/ 3600;
    int min = (seconds % 3600) ~/ 60;
    int sec = seconds % 60;
    /// hour format '00'
    if (hour < 10) {
      hh = '0$hour';
    } else {
      hh = '$hour';
    }
    /// minute format '00'
    if (min < 10) {
      mm = '0$min';
    } else {
      mm = '$min';
    }
    /// second format '00'
    if (sec < 10) {
      ss = '0$sec';
    } else {
      ss = '$sec';
    }
    return ('$hh:$mm:$ss');
  }
}

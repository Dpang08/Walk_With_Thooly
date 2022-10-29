import 'package:get/get.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:walk_with_thooly/controller/firebase_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:walk_with_thooly/controller/state_controller.dart';

final StateService _service = Get.put(StateService());


class GpsService extends GetxService {

  /// current location related dataset for shot
  Rx<LatLng> currentLocation = const LatLng(37.5666805, 126.9784147).obs;
  Rx<LatLng> initLocation = const LatLng(37.5666805, 126.9784147).obs;    // init location for gmap, 시청
  Rx<DateTime> currentTime = DateTime.now().obs;

}

Future<bool> checkGranted() async {
  var status = await Permission.location.status;
  if (status.isGranted) {
    return true;
  } else {
    return false;
  }
}
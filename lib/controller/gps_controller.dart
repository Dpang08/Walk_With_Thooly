import 'package:get/get.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'state_controller.dart';

final StateService _service = Get.put(StateService());

class GpsService extends GetxService {

  RxList<LatLng> markers = <LatLng>[].obs;
  RxList<double> altitudes = <double>[].obs;
  /// current location related dataset for shot
  Rx<LatLng> currentLocation = const LatLng(37.5666805, 126.9784147).obs;
  Rx<LatLng> initLocation = const LatLng(37.5666805, 126.9784147).obs;    // init location for gmap, 시청
  Rx<double> currentAltitude = 0.0.obs;
  Rx<double> currentAccuracy = 0.0.obs;
  Rx<double> currentHeading = 0.0.obs;
  Rx<DateTime> currentTime = DateTime.now().obs;

}


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:walk_with_thooly/controller/state_controller.dart';
import 'package:walk_with_thooly/controller/gps_controller.dart';
import 'package:walk_with_thooly/resources/kConstant.dart';

final StateService _service = Get.put(StateService());
final GpsService _gpsService = Get.put(GpsService());

class MyGoogleMap extends StatefulWidget {
  const MyGoogleMap({Key? key}) : super(key: key);

  @override
  State<MyGoogleMap> createState() => _MyGoogleMapState();
}

class _MyGoogleMapState extends State<MyGoogleMap> {
  /// for gps live stream
  late StreamSubscription<LocationData> _locationSubscription;
  late GoogleMapController _gmapController;
  final Location _location = Location();
  LatLng? myLocation;
  double? liveGpsAccuracy;    // check for gps accuracy lively
  bool isInitLocation = false;    // if init gps location updated -> true -> update mapview to this init location

  /// for pedometer live stream
  // late Stream<StepCount> _stepCountStream;
  late StreamSubscription _stepStreamSubscription;
  final Stopwatch _stopwatch = Stopwatch();   // for elapsed time (hh:mm:ss)
  String status = 'stop';

  @override
  void initState() {
    super.initState();
    _initLiveLocation();
    _initCurrentLocation();    // init location to set map initPosition
    _initPlatformState();
  }

  @override
  void dispose() {
    super.dispose();
    _locationSubscription.cancel();
    _gmapController.dispose();
    _stopwatch.reset();
  }

  void _initLiveLocation() {
    _locationSubscription = _location.onLocationChanged.listen((event) {
      setState(() {
        myLocation = LatLng(event.latitude!, event.longitude!);
        liveGpsAccuracy = event.accuracy!;
      });
    });
  }

  void _initCurrentLocation() async {
    final loc = await _location.getLocation().catchError((err) {
      Get.snackbar('error@getLocation', '$err');
    });
    _gpsService.currentLocation = LatLng(loc.latitude!, loc.longitude!).obs;
    setState(() => isInitLocation = true);
  }

  void _initPlatformState() async {
    print('---> _initPlatformState()');
    // _stepCountStream = Pedometer.stepCountStream;

    /// activity recognition permission
    if (await Permission.activityRecognition.isGranted) {
      // _stepStreamSubscription = _stepCountStream.listen((event) {});
      _stepStreamSubscription = Pedometer.stepCountStream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: true,
      );
    } else {
      await Permission.activityRecognition.request().then((value) {
        // _stepStreamSubscription = _stepCountStream.listen((event) {});
        _stepStreamSubscription = Pedometer.stepCountStream.listen(
          _onData,
          onError: _onError,
          onDone: _onDone,
          cancelOnError: true,
        );
      });
    }
    if (!mounted) return;
  }

  void _onData(StepCount step) {
    if (_service.isPedometerStarted.value) {
      _service.steps.value = step.steps - _service.initStep.value;      // 현재 걸음수 계산
    } else {
      _service.initStep.value = step.steps;   // 초기 걸음수 저장
    }
    print('---> onData: $step');
  }

  void _onError(err) {
    print('---> onError: $err');
  }

  void _onDone() {
    print('---> onDone');
  }

  void _onMapCreated(GoogleMapController controller) {
    _gmapController = controller;
  }

  void _onCameraMove(CameraPosition position) {
    _gpsService.currentLocation = position.target.obs;
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double mapHeight = height * 0.5;
    return Obx (() => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _mapWidget(mapHeight),
        Expanded(child: _workoutPanel()),
      ],
    ));
  }

  Widget _mapWidget(double height) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(1.0),
      child: GoogleMap(
        scrollGesturesEnabled: true,
        zoomControlsEnabled: true,
        // minMaxZoomPreference: const MinMaxZoomPreference(16.5, 18),
        mapType: MapType.normal,
        onMapCreated: _onMapCreated,
        onCameraMove: _onCameraMove,
        initialCameraPosition: CameraPosition(
          target: _gpsService.initLocation.value,
          zoom: 15,   // 16
        ),
        myLocationEnabled: true,
        compassEnabled: true,
        mapToolbarEnabled: true,
        // trafficEnabled: true,
        // myLocationButtonEnabled: true,
      ),
    );
  }

  Widget _workoutPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 10, right: 10),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: kColor.decorationBox,
          borderRadius: BorderRadius.circular(15)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buttons(),
          _calories(),
          _bottom(),
        ],
          ),
    );
  }

  Widget _bottom() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _showDistance(),
        // _showElapsedTime(),
        _showPedometer()
      ],
    );
  }

  Widget _showDistance() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text('2.4', style: TextStyle(fontSize: 25)),
        Text('distance(km)', style: TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buttons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(onPressed: () {
          setState(() {
            status = 'START';
          });
          _startWalking();
        }, child: const Text('Start')),
        SizedBox(
            width: 80,
            child: Center(child: Text(status, style: const TextStyle(fontSize: 20),))),
        ElevatedButton(onPressed: () {
          setState(() {
            status = 'STOP';
          });
          _stopWalking();
        }, child: const Text('Stop')),
      ],
    );
  }

  // Widget _showElapsedTime() {
  //   return Column(
  //     children: [
  //       const Text('Elapsed time', style: TextStyle(fontSize: 18)),
  //       Text(_service.elapsedTime.value.toString(), style: const TextStyle(fontSize: 18))
  //     ],
  //   );
  // }

  Widget _calories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(_service.kcal.value.toStringAsFixed(1), style: const TextStyle(fontSize: 35)),
        const Text('kcal', style: TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _showPedometer() {
    return Column(
      children: [
        Text('${_service.steps.value}', style: const TextStyle(fontSize: 25)),
        const Text('steps', style: TextStyle(fontSize: 16),),
      ],
    );
  }

  void _calcCalories() {
    double caloriesBurnedPerMile = kConst.walkingFactor * (kConst.weight * 2.2);
    double strip = kConst.height * 0.415;
    double stepCountMile = 160934.4 / strip;
    double conversationFactor = caloriesBurnedPerMile / stepCountMile;
    _service.kcal.value = _service.steps.value * conversationFactor;
  }

  void _startWalking() {
    _stopwatch.start();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      _service.elapsedTime.value = ElapsedTime(seconds: _stopwatch.elapsed.inSeconds);
    });
    /// set pedometer
    _service.isPedometerStarted.value = true;
  }

  void _stopWalking() {
    _stopwatch.stop();
    _service.isPedometerStarted.value = false;
    _service.stepsResult.value = _service.steps.value;  // 최종 걸음수 저장
    _stepStreamSubscription.cancel().then((value) {
      _service.steps.value = 0;
    });
    _calcCalories();
  }

  /// get gps current location manually by request
  // Future _getLocation() async {
  //   final loc = await _location.getLocation();
  //   setState(() {
  //     _gpsService.currentLocation = LatLng(loc.latitude!, loc.longitude!).obs;
  //     _gpsService.currentAltitude = loc.altitude!.obs;
  //     _gpsService.currentAccuracy = loc.accuracy!.obs;
  //     _gpsService.currentHeading = loc.heading!.obs;
  //     _gpsService.currentTime = DateTime.now().obs;
  //   });
  //   _moveCameraToLocation();
  // }

  // void _moveCameraToLocation() {
  //   LatLng target = _gpsService.currentLocation.value;
  //   List<double> latitudes = [];
  //   List<double> longitudes = [];
  //
  //   if (_service.holesPlayed[_service.currentHole.value -1]) {   // if played hole
  //     Set<Marker> markers = _service.shotTotal.value
  //         .getHoleMarkersGmap(_service.currentHole.value);    // get previous hole makers
  //     if (markers.isNotEmpty) {   // in case, position entry more than 1
  //       latitudes = markers.map((e) => e.position.latitude).toList();
  //       longitudes = markers.map((e) => e.position.longitude).toList();
  //       var s = latitudes.min,
  //           n = latitudes.max,
  //           w = longitudes.min,
  //           e = longitudes.max;
  //       _gmapController.moveCamera(CameraUpdate.newLatLngBounds(
  //           LatLngBounds(southwest: LatLng(s, w), northeast: LatLng(n, e)), 30));
  //     } else {    // in case, no entry
  //       _myCurrentLocation();
  //       // _gmapController.moveCamera(CameraUpdate.newLatLngZoom(target, 16.5));
  //     }
  //   } else {    // in case, hole is not played (new hole)
  //     _myCurrentLocation();
  //     // _gmapController.moveCamera(CameraUpdate.newLatLngZoom(target, 16.5));
  //   }
  // }

}

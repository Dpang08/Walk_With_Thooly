import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class WalkingModel {
  String? timeStartAt;
  String? timeEndAt;
  double? distance;
  double? steps;
  double? kcal;

  WalkingModel({
    this.timeStartAt,
    this.timeEndAt,
    this.distance,
    this.steps,
    this.kcal,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'timeStartAt': timeStartAt!,
      'timeEndAt': timeEndAt!,
      'distance': distance!,
      'steps': steps!,
      'kcal': kcal!,
    };
  }

  factory WalkingModel.fromMap(Map<String, dynamic> data) {
    return WalkingModel(
      timeStartAt: data['timeStartAt'],
      timeEndAt: data['timeEndAt'],
      distance: data['distance'],
      steps: data['steps'],
      kcal: data['kcal'],
    );
  }

  factory WalkingModel.fromFirestore(DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data() as Map;
    return WalkingModel(
      timeStartAt: data['timeStartAt'],
      timeEndAt: data['timeEndAt'],
      distance: data['distance'],
      steps: data['steps'],
      kcal: data['kcal'],
    );
  }

  void reset() {
    timeStartAt = null;
    timeEndAt = null;
    distance = null;
    steps = null;
    kcal = null;
  }

  void printAllBy(String caller) {
    debugPrint('-------------- user info -----------------');
    debugPrint('\t\t* timeStartAt : $timeStartAt');
    debugPrint('\t\t* timeEndAt : $timeEndAt');
    debugPrint('\t\t* distance : $distance');
    debugPrint('\t\t* steps : $steps');
    debugPrint('\t\t* kcal : $kcal');
    debugPrint('---------- called from $caller -----------');
  }
}

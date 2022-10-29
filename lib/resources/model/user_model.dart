import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class UserModel {
  String? type;   // admin, general
  String? userid;
  String? username;
  String? password;
  String? gender;
  String? email;
  String? thumbnail;
  int? totalDays;
  int? streakDays;
  int? height;     // 키
  int? weight;     // 몸무개
  int? totalSteps;
  double? totalKcal;   // total kcal
  double? totalDist;    // distance in km
  double? streakDist;   // distance in km
  DateTime? createdAt;
  DateTime? startAt;    // day to begin walking
  DateTime? startStreakAt;    // day to be counted for streak

  UserModel({
    this.type,
    this.userid,
    this.username,
    this.password,
    this.gender,
    this.email,
    this.height,
    this.weight,
    this.totalSteps,
    this.totalKcal,
    this.createdAt,
    this.thumbnail,
    this.totalDays,
    this.streakDays,
    this.totalDist,
    this.streakDist,
    this.startAt,
    this.startStreakAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'type': type!,
      'userid': userid!,
      'username': username!,
      'password': password!,
      'email': email!,
      'height': height != null ? height! : 0,
      'weight': weight != null ? weight! : 0,
      'totalKcal': totalKcal != null ? totalKcal! : 0,
      'totalSteps': totalSteps  != null ? totalSteps! : 0,
      'gender': gender != null ? gender! : '',
      'thumbnail': thumbnail != null ? thumbnail! : '',
      'totalDays': totalDays != null ? totalDays! : 0,
      'streakDays': streakDays != null ? streakDays! : 0,
      'totalDist': totalDist != null ? totalDist! : 0,
      'streakDist': streakDist != null ? streakDist! : 0,
      'createdAt': createdAt!.toIso8601String(),
      'startAt': startAt != null ? startAt!.toIso8601String() : '',
      'startStreakAt': startStreakAt != null ? startStreakAt!.toIso8601String() : '',
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      type: data['type'],
      userid: data['userid'],
      username: data['username'],
      password: data['password'],
      email: data['email'],
      height: data['height'],
      weight: data['weight'],
      totalKcal: data['totalKcal'].toDouble(),
      totalSteps: data['totalSteps'],
      gender: data['gender'],
      thumbnail: data['thumbnail'],
      totalDays: data['totalDays'],
      streakDays: data['streakDays'],
      totalDist: data['totalDist'].toDouble(),
      streakDist: data['streakDist'].toDouble(),
      createdAt: DateTime.parse(data['createdAt']),
      startAt: data['startAt'] == '' ? null : DateTime.parse(data['startAt']),
      startStreakAt: data['startStreakAt'] == '' ? null : DateTime.parse(data['startStreakAt']),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data() as Map;
    return UserModel(
      type: data['type'],
      userid: data['userid'],
      username: data['username'],
      password: data['password'],
      email: data['email'],
      height: data['height'],
      weight: data['weight'],
      totalKcal: data['totalKcal'].toDouble(),
      totalSteps: data['totalSteps'],
      gender: data['gender'],
      thumbnail: data['thumbnail'],
      totalDays: data['totalDays'],
      streakDays: data['streakDays'],
      totalDist: data['totalDist'].toDouble(),
      streakDist: data['streakDist'].toDouble(),
      createdAt: DateTime.parse(data['createdAt']),
      startAt: data['startAt'] == '' ? null : DateTime.parse(data['startAt']),
      startStreakAt: data['startStreakAt'] == '' ? null : DateTime.parse(data['startStreakAt']),
    );
  }

  void reset() {
    type = null;
    userid = null;
    username = null;
    password = null;
    gender = null;
    email = null;
    height = null;
    weight = null;
    totalKcal = null;
    totalSteps = null;
    createdAt = null;
    thumbnail = null;
    totalDays = null;
    streakDays = null;
    totalDist = null;
    streakDist = null;
    startAt = null;
    startStreakAt = null;
  }

  void printAll() {
    debugPrint('-------------- user info -----------------');
    debugPrint('\t\t* user id : $userid');
    debugPrint('\t\t* user name : $username');
    debugPrint('\t\t* user type : $type');
    debugPrint('\t\t* password : $password');
    debugPrint('\t\t* email : $email');
    debugPrint('\t\t* height : $height');
    debugPrint('\t\t* weight : $weight');
    debugPrint('\t\t* totalKcal : $totalKcal');
    debugPrint('\t\t* gender : $gender');
    debugPrint('\t\t* createdAt : $createdAt');
    debugPrint('\t\t* thumbnail : $thumbnail');
    debugPrint('\t\t* totalSteps : $totalSteps');
    debugPrint('\t\t* total Days : $totalDays');
    debugPrint('\t\t* streak Days : $streakDays');
    debugPrint('\t\t* total Dist : $totalDist');
    debugPrint('\t\t* streak Dist : $streakDist');
    debugPrint('\t\t* start At : $startAt');
    debugPrint('\t\t* start Streak At : $startStreakAt');
    debugPrint('---------- end -----------');
  }
}

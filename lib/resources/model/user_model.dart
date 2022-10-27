import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserModel {
  String? type;   // admin, general
  String? userid;
  String? username;
  String? password;
  String? gender;
  String? email;
  String? createdAt;
  String? thumbnail;
  int? totalDays;
  int? streakDays;
  int? height;     // 키
  int? weight;     // 몸무개
  int? totalKcal;   // total kcal
  double? totalDist;    // distance in km
  double? streakDist;   // distance in km
  String? startAt;    // day to begin walking
  String? startStreakAt;    // day to be counted for streak

  UserModel({
    this.type,
    this.userid,
    this.username,
    this.password,
    this.gender,
    this.email,
    this.height,
    this.weight,
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
      'height': height!,
      'weight': weight!,
      'totalKcal': totalKcal!,
      'gender': gender!,
      'createdAt': createdAt!,
      'thumbnail': thumbnail!,
      'totalDays': totalDays!,
      'streakDays': streakDays!,
      'totalDist': totalDist!,
      'streakDist': streakDist!,
      'startAt': startAt!,
      'startStreakAt': startStreakAt!,
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
      totalKcal: data['totalKcal'],
      gender: data['gender'],
      createdAt: data['createdAt'],
      thumbnail: data['thumbnail'],
      totalDays: data['totalDays'],
      streakDays: data['streakDays'],
      totalDist: data['totalDist'],
      streakDist: data['streakDist'],
      startAt: data['startAt'],
      startStreakAt: data['startStreakAt'],
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
      totalKcal: data['totalKcal'],
      gender: data['gender'],
      createdAt: data['createdAt'],
      thumbnail: data['thumbnail'],
      totalDays: data['totalDays'],
      streakDays: data['streakDays'],
      totalDist: data['totalDist'],
      streakDist: data['streakDist'],
      startAt: data['startAt'],
      startStreakAt: data['startStreakAt'],
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
    debugPrint('\t\t* total Days : $totalDays');
    debugPrint('\t\t* streak Days : $streakDays');
    debugPrint('\t\t* total Dist : $totalDist');
    debugPrint('\t\t* streak Dist : $streakDist');
    debugPrint('\t\t* start At : $startAt');
    debugPrint('\t\t* start Streak At : $startStreakAt');
    debugPrint('---------- end -----------');
  }
}

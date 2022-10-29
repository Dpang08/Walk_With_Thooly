import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceModel{
  String? imageUrl;  // save image url from storage
  double? lat;
  double? lng;
  String? creator;
  DateTime? timeAt;

  PlaceModel({
    this.imageUrl,
    this.lat,
    this.lng,
    this.creator,
    this.timeAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl!,
      'lat': lat!,
      'lon': lng!,
      'creator': creator!,
      'timeAt': timeAt!.toIso8601String(),    // DateTime to String
    };
  }

  factory PlaceModel.fromMap(Map<String, dynamic> data) {
    return PlaceModel(
      imageUrl: data['imageUrl'],
      lat: data['lat'],
      lng: data['lon'],
      creator: data['creator'],
      timeAt: DateTime.parse(data['timeAt']),   // String ISO8601 to DateTime
    );
  }

  factory PlaceModel.fromFirestore(DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data() as Map;
    return PlaceModel(
      imageUrl: data['imageUrl'],
      lat: data['lat'],
      lng: data['lon'],
      creator: data['creator'],
      timeAt: DateTime.parse(data['timeAt']),   // String ISO8601 to DateTime
    );
  }

  void reset() {
    imageUrl = null;
    lat = null;
    lng = null;
    creator = null;
    timeAt = null;
  }

  void printAll() {
    print('--> imageUrl: $imageUrl');
    print('--> imageUrl: $lat');
    print('--> imageUrl: $lng');
    print('--> imageUrl: $creator');
    print('--> imageUrl: $timeAt');
  }
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zapcall/src/types.dart';

part 'room.freezed.dart';
part 'room.g.dart';

@freezed
abstract class RoomModel with _$RoomModel {
  const factory RoomModel({
    // required String id,
    required RoomInfoModel info,
    Json? offer,
    Json? answer,
  }) = _RoomModel;

  factory RoomModel.fromJson(Map<String, dynamic> json) =>
      _$RoomModelFromJson(json);
}

@freezed
abstract class RoomInfoModel with _$RoomInfoModel {
  const factory RoomInfoModel({
    // required String name,
    required String fromId,
    required String toId,
  }) = _RoomInfoModel;

  factory RoomInfoModel.fromJson(Map<String, dynamic> json) =>
      _$RoomInfoModelFromJson(json);
}

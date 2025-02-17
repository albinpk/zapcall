import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class ZapUser with _$ZapUser {
  const factory ZapUser({
    required String id,
    required String name,
  }) = _ZapUser;

  factory ZapUser.fromJson(Map<String, dynamic> json) =>
      _$ZapUserFromJson(json);
}

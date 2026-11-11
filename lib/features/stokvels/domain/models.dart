// NEW: freezed models for Home + stokvel detail. Role lives on Membership/entries, never on a user (Part 3 twist)
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ronditrack/core/money/cents.dart';
import 'package:ronditrack/features/stokvels/domain/enums.dart';

part 'models.freezed.dart';

@freezed
abstract class Membership with _$Membership {
  const factory({required String stokvelId, required StokvelRole role}) =
      _Membership;
}

@freezed
abstract class HomeEntry with _$HomeEntry {
  const factory({
    required String stokvelId,
    required String name,
    required StokvelRole role,
    required Cents paid,
    required Cents owed,
    required Cents arrears,
    DateTime? nextPayout,
  }) = _HomeEntry;
}

@freezed
abstract class CycleInfo with _$CycleInfo {
  const factory({
    @Default('') String id,
    required int number,
    required CycleStatus status,
    required DateTime dueDate,
  }) = _CycleInfo;
}

@freezed
abstract class ContributionItem with _$ContributionItem {
  const factory({
    required String id,
    required String memberName,
    required Cents amount,
    required ContributionStatus status,
    required bool isMine,
  }) = _ContributionItem;
}

@freezed
abstract class StokvelDetail with _$StokvelDetail {
  const factory({
    required String stokvelId,
    required String name,
    required StokvelRole role,
    CycleInfo? cycle,
    @Default(<ContributionItem>[]) List<ContributionItem> contributions,
  }) = _StokvelDetail;
}

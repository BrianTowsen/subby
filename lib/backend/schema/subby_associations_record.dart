import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SubbyAssociationsRecord extends FirestoreRecord {
  SubbyAssociationsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "slug" field.
  String? _slug;
  String get slug => _slug ?? '';
  bool hasSlug() => _slug != null;

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "fullName" field.
  String? _fullName;
  String get fullName => _fullName ?? '';
  bool hasFullName() => _fullName != null;

  // "icon" field.
  String? _icon;
  String get icon => _icon ?? '';
  bool hasIcon() => _icon != null;

  // "website" field.
  String? _website;
  String get website => _website ?? '';
  bool hasWebsite() => _website != null;

  // "isActive" field.
  bool? _isActive;
  bool get isActive => _isActive ?? false;
  bool hasIsActive() => _isActive != null;

  // "isVerifiable" field.
  bool? _isVerifiable;
  bool get isVerifiable => _isVerifiable ?? false;
  bool hasIsVerifiable() => _isVerifiable != null;

  // "sortOrder" field.
  int? _sortOrder;
  int get sortOrder => _sortOrder ?? 0;
  bool hasSortOrder() => _sortOrder != null;

  // "category" field.
  String? _category;
  String get category => _category ?? '';
  bool hasCategory() => _category != null;

  // "created_time" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  void _initializeFields() {
    _slug = snapshotData['slug'] as String?;
    _name = snapshotData['name'] as String?;
    _fullName = snapshotData['fullName'] as String?;
    _icon = snapshotData['icon'] as String?;
    _website = snapshotData['website'] as String?;
    _isActive = snapshotData['isActive'] as bool?;
    _isVerifiable = snapshotData['isVerifiable'] as bool?;
    _sortOrder = castToType<int>(snapshotData['sortOrder']);
    _category = snapshotData['category'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('subby_associations');

  static Stream<SubbyAssociationsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => SubbyAssociationsRecord.fromSnapshot(s));

  static Future<SubbyAssociationsRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => SubbyAssociationsRecord.fromSnapshot(s));

  static SubbyAssociationsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      SubbyAssociationsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static SubbyAssociationsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      SubbyAssociationsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'SubbyAssociationsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is SubbyAssociationsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createSubbyAssociationsRecordData({
  String? slug,
  String? name,
  String? fullName,
  String? icon,
  String? website,
  bool? isActive,
  bool? isVerifiable,
  int? sortOrder,
  String? category,
  DateTime? createdTime,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'slug': slug,
      'name': name,
      'fullName': fullName,
      'icon': icon,
      'website': website,
      'isActive': isActive,
      'isVerifiable': isVerifiable,
      'sortOrder': sortOrder,
      'category': category,
      'created_time': createdTime,
    }.withoutNulls,
  );

  return firestoreData;
}

class SubbyAssociationsRecordDocumentEquality
    implements Equality<SubbyAssociationsRecord> {
  const SubbyAssociationsRecordDocumentEquality();

  @override
  bool equals(SubbyAssociationsRecord? e1, SubbyAssociationsRecord? e2) {
    return e1?.slug == e2?.slug &&
        e1?.name == e2?.name &&
        e1?.fullName == e2?.fullName &&
        e1?.icon == e2?.icon &&
        e1?.website == e2?.website &&
        e1?.isActive == e2?.isActive &&
        e1?.isVerifiable == e2?.isVerifiable &&
        e1?.sortOrder == e2?.sortOrder &&
        e1?.category == e2?.category &&
        e1?.createdTime == e2?.createdTime;
  }

  @override
  int hash(SubbyAssociationsRecord? e) => const ListEquality().hash([
        e?.slug,
        e?.name,
        e?.fullName,
        e?.icon,
        e?.website,
        e?.isActive,
        e?.isVerifiable,
        e?.sortOrder,
        e?.category,
        e?.createdTime
      ]);

  @override
  bool isValidKey(Object? o) => o is SubbyAssociationsRecord;
}

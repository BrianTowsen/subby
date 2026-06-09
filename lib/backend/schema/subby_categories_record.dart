import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SubbyCategoriesRecord extends FirestoreRecord {
  SubbyCategoriesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "slug" field.
  String? _slug;
  String get slug => _slug ?? '';
  bool hasSlug() => _slug != null;

  // "level" field.
  int? _level;
  int get level => _level ?? 0;
  bool hasLevel() => _level != null;

  // "parentSlug" field.
  String? _parentSlug;
  String get parentSlug => _parentSlug ?? '';
  bool hasParentSlug() => _parentSlug != null;

  // "sortOrder" field.
  int? _sortOrder;
  int get sortOrder => _sortOrder ?? 0;
  bool hasSortOrder() => _sortOrder != null;

  // "icon" field.
  String? _icon;
  String get icon => _icon ?? '';
  bool hasIcon() => _icon != null;

  // "isActive" field.
  bool? _isActive;
  bool get isActive => _isActive ?? false;
  bool hasIsActive() => _isActive != null;

  // "type" field.
  String? _type;
  String get type => _type ?? '';
  bool hasType() => _type != null;

  // "docId" field.
  String? _docId;
  String get docId => _docId ?? '';
  bool hasDocId() => _docId != null;

  void _initializeFields() {
    _name = snapshotData['name'] as String?;
    _slug = snapshotData['slug'] as String?;
    _level = castToType<int>(snapshotData['level']);
    _parentSlug = snapshotData['parentSlug'] as String?;
    _sortOrder = castToType<int>(snapshotData['sortOrder']);
    _icon = snapshotData['icon'] as String?;
    _isActive = snapshotData['isActive'] as bool?;
    _type = snapshotData['type'] as String?;
    _docId = snapshotData['docId'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('subby_categories');

  static Stream<SubbyCategoriesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => SubbyCategoriesRecord.fromSnapshot(s));

  static Future<SubbyCategoriesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => SubbyCategoriesRecord.fromSnapshot(s));

  static SubbyCategoriesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      SubbyCategoriesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static SubbyCategoriesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      SubbyCategoriesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'SubbyCategoriesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is SubbyCategoriesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createSubbyCategoriesRecordData({
  String? name,
  String? slug,
  int? level,
  String? parentSlug,
  int? sortOrder,
  String? icon,
  bool? isActive,
  String? type,
  String? docId,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'name': name,
      'slug': slug,
      'level': level,
      'parentSlug': parentSlug,
      'sortOrder': sortOrder,
      'icon': icon,
      'isActive': isActive,
      'type': type,
      'docId': docId,
    }.withoutNulls,
  );

  return firestoreData;
}

class SubbyCategoriesRecordDocumentEquality
    implements Equality<SubbyCategoriesRecord> {
  const SubbyCategoriesRecordDocumentEquality();

  @override
  bool equals(SubbyCategoriesRecord? e1, SubbyCategoriesRecord? e2) {
    return e1?.name == e2?.name &&
        e1?.slug == e2?.slug &&
        e1?.level == e2?.level &&
        e1?.parentSlug == e2?.parentSlug &&
        e1?.sortOrder == e2?.sortOrder &&
        e1?.icon == e2?.icon &&
        e1?.isActive == e2?.isActive &&
        e1?.type == e2?.type &&
        e1?.docId == e2?.docId;
  }

  @override
  int hash(SubbyCategoriesRecord? e) => const ListEquality().hash([
        e?.name,
        e?.slug,
        e?.level,
        e?.parentSlug,
        e?.sortOrder,
        e?.icon,
        e?.isActive,
        e?.type,
        e?.docId
      ]);

  @override
  bool isValidKey(Object? o) => o is SubbyCategoriesRecord;
}

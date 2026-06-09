import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ProjectListingsRecord extends FirestoreRecord {
  ProjectListingsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "projectRef" field.
  DocumentReference? _projectRef;
  DocumentReference? get projectRef => _projectRef;
  bool hasProjectRef() => _projectRef != null;

  // "listingRef" field.
  DocumentReference? _listingRef;
  DocumentReference? get listingRef => _listingRef;
  bool hasListingRef() => _listingRef != null;

  // "addedAt" field.
  DateTime? _addedAt;
  DateTime? get addedAt => _addedAt;
  bool hasAddedAt() => _addedAt != null;

  // "addedBy" field.
  DocumentReference? _addedBy;
  DocumentReference? get addedBy => _addedBy;
  bool hasAddedBy() => _addedBy != null;

  // "title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "subtitle" field.
  String? _subtitle;
  String get subtitle => _subtitle ?? '';
  bool hasSubtitle() => _subtitle != null;

  // "ratingText" field.
  String? _ratingText;
  String get ratingText => _ratingText ?? '';
  bool hasRatingText() => _ratingText != null;

  // "photoUrl" field.
  String? _photoUrl;
  String get photoUrl => _photoUrl ?? '';
  bool hasPhotoUrl() => _photoUrl != null;

  void _initializeFields() {
    _projectRef = snapshotData['projectRef'] as DocumentReference?;
    _listingRef = snapshotData['listingRef'] as DocumentReference?;
    _addedAt = snapshotData['addedAt'] as DateTime?;
    _addedBy = snapshotData['addedBy'] as DocumentReference?;
    _title = snapshotData['title'] as String?;
    _subtitle = snapshotData['subtitle'] as String?;
    _ratingText = snapshotData['ratingText'] as String?;
    _photoUrl = snapshotData['photoUrl'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('project_listings');

  static Stream<ProjectListingsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ProjectListingsRecord.fromSnapshot(s));

  static Future<ProjectListingsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ProjectListingsRecord.fromSnapshot(s));

  static ProjectListingsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ProjectListingsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ProjectListingsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ProjectListingsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ProjectListingsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ProjectListingsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createProjectListingsRecordData({
  DocumentReference? projectRef,
  DocumentReference? listingRef,
  DateTime? addedAt,
  DocumentReference? addedBy,
  String? title,
  String? subtitle,
  String? ratingText,
  String? photoUrl,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'projectRef': projectRef,
      'listingRef': listingRef,
      'addedAt': addedAt,
      'addedBy': addedBy,
      'title': title,
      'subtitle': subtitle,
      'ratingText': ratingText,
      'photoUrl': photoUrl,
    }.withoutNulls,
  );

  return firestoreData;
}

class ProjectListingsRecordDocumentEquality
    implements Equality<ProjectListingsRecord> {
  const ProjectListingsRecordDocumentEquality();

  @override
  bool equals(ProjectListingsRecord? e1, ProjectListingsRecord? e2) {
    return e1?.projectRef == e2?.projectRef &&
        e1?.listingRef == e2?.listingRef &&
        e1?.addedAt == e2?.addedAt &&
        e1?.addedBy == e2?.addedBy &&
        e1?.title == e2?.title &&
        e1?.subtitle == e2?.subtitle &&
        e1?.ratingText == e2?.ratingText &&
        e1?.photoUrl == e2?.photoUrl;
  }

  @override
  int hash(ProjectListingsRecord? e) => const ListEquality().hash([
        e?.projectRef,
        e?.listingRef,
        e?.addedAt,
        e?.addedBy,
        e?.title,
        e?.subtitle,
        e?.ratingText,
        e?.photoUrl
      ]);

  @override
  bool isValidKey(Object? o) => o is ProjectListingsRecord;
}

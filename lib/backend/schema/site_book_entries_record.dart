import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SiteBookEntriesRecord extends FirestoreRecord {
  SiteBookEntriesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "projectRef" field.
  DocumentReference? _projectRef;
  DocumentReference? get projectRef => _projectRef;
  bool hasProjectRef() => _projectRef != null;

  // "authorRef" field.
  DocumentReference? _authorRef;
  DocumentReference? get authorRef => _authorRef;
  bool hasAuthorRef() => _authorRef != null;

  // "authorName" field.
  String? _authorName;
  String get authorName => _authorName ?? '';
  bool hasAuthorName() => _authorName != null;

  // "note" field.
  String? _note;
  String get note => _note ?? '';
  bool hasNote() => _note != null;

  // "weather" field.
  String? _weather;
  String get weather => _weather ?? '';
  bool hasWeather() => _weather != null;

  // "tags" field.
  List<String>? _tags;
  List<String> get tags => _tags ?? const [];
  bool hasTags() => _tags != null;

  // "photoUrls" field.
  List<String>? _photoUrls;
  List<String> get photoUrls => _photoUrls ?? const [];
  bool hasPhotoUrls() => _photoUrls != null;

  // "visibility" field.
  String? _visibility;
  String get visibility => _visibility ?? '';
  bool hasVisibility() => _visibility != null;

  // "createdAt" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  void _initializeFields() {
    _projectRef = snapshotData['projectRef'] as DocumentReference?;
    _authorRef = snapshotData['authorRef'] as DocumentReference?;
    _authorName = snapshotData['authorName'] as String?;
    _note = snapshotData['note'] as String?;
    _weather = snapshotData['weather'] as String?;
    _tags = getDataList(snapshotData['tags']);
    _photoUrls = getDataList(snapshotData['photoUrls']);
    _visibility = snapshotData['visibility'] as String?;
    _createdAt = snapshotData['createdAt'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('site_book_entries');

  static Stream<SiteBookEntriesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => SiteBookEntriesRecord.fromSnapshot(s));

  static Future<SiteBookEntriesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => SiteBookEntriesRecord.fromSnapshot(s));

  static SiteBookEntriesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      SiteBookEntriesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static SiteBookEntriesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      SiteBookEntriesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'SiteBookEntriesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is SiteBookEntriesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createSiteBookEntriesRecordData({
  DocumentReference? projectRef,
  DocumentReference? authorRef,
  String? authorName,
  String? note,
  String? weather,
  String? visibility,
  DateTime? createdAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'projectRef': projectRef,
      'authorRef': authorRef,
      'authorName': authorName,
      'note': note,
      'weather': weather,
      'visibility': visibility,
      'createdAt': createdAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class SiteBookEntriesRecordDocumentEquality
    implements Equality<SiteBookEntriesRecord> {
  const SiteBookEntriesRecordDocumentEquality();

  @override
  bool equals(SiteBookEntriesRecord? e1, SiteBookEntriesRecord? e2) {
    const listEquality = ListEquality();
    return e1?.projectRef == e2?.projectRef &&
        e1?.authorRef == e2?.authorRef &&
        e1?.authorName == e2?.authorName &&
        e1?.note == e2?.note &&
        e1?.weather == e2?.weather &&
        listEquality.equals(e1?.tags, e2?.tags) &&
        listEquality.equals(e1?.photoUrls, e2?.photoUrls) &&
        e1?.visibility == e2?.visibility &&
        e1?.createdAt == e2?.createdAt;
  }

  @override
  int hash(SiteBookEntriesRecord? e) => const ListEquality().hash([
        e?.projectRef,
        e?.authorRef,
        e?.authorName,
        e?.note,
        e?.weather,
        e?.tags,
        e?.photoUrls,
        e?.visibility,
        e?.createdAt
      ]);

  @override
  bool isValidKey(Object? o) => o is SiteBookEntriesRecord;
}

import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UiRecord extends FirestoreRecord {
  UiRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "createNewProjectUrl" field.
  String? _createNewProjectUrl;
  String get createNewProjectUrl => _createNewProjectUrl ?? '';
  bool hasCreateNewProjectUrl() => _createNewProjectUrl != null;

  // "timelineVideoUrl" field.
  String? _timelineVideoUrl;
  String get timelineVideoUrl => _timelineVideoUrl ?? '';
  bool hasTimelineVideoUrl() => _timelineVideoUrl != null;

  void _initializeFields() {
    _createNewProjectUrl = snapshotData['createNewProjectUrl'] as String?;
    _timelineVideoUrl = snapshotData['timelineVideoUrl'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('ui');

  static Stream<UiRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UiRecord.fromSnapshot(s));

  static Future<UiRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UiRecord.fromSnapshot(s));

  static UiRecord fromSnapshot(DocumentSnapshot snapshot) => UiRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UiRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UiRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UiRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UiRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createUiRecordData({
  String? createNewProjectUrl,
  String? timelineVideoUrl,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'createNewProjectUrl': createNewProjectUrl,
      'timelineVideoUrl': timelineVideoUrl,
    }.withoutNulls,
  );

  return firestoreData;
}

class UiRecordDocumentEquality implements Equality<UiRecord> {
  const UiRecordDocumentEquality();

  @override
  bool equals(UiRecord? e1, UiRecord? e2) {
    return e1?.createNewProjectUrl == e2?.createNewProjectUrl &&
        e1?.timelineVideoUrl == e2?.timelineVideoUrl;
  }

  @override
  int hash(UiRecord? e) =>
      const ListEquality().hash([e?.createNewProjectUrl, e?.timelineVideoUrl]);

  @override
  bool isValidKey(Object? o) => o is UiRecord;
}

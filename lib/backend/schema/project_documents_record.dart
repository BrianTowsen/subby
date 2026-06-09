import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ProjectDocumentsRecord extends FirestoreRecord {
  ProjectDocumentsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "projectRef" field.
  DocumentReference? _projectRef;
  DocumentReference? get projectRef => _projectRef;
  bool hasProjectRef() => _projectRef != null;

  // "title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "type" field.
  String? _type;
  String get type => _type ?? '';
  bool hasType() => _type != null;

  // "fileUrl" field.
  String? _fileUrl;
  String get fileUrl => _fileUrl ?? '';
  bool hasFileUrl() => _fileUrl != null;

  // "updatedAt" field.
  DateTime? _updatedAt;
  DateTime? get updatedAt => _updatedAt;
  bool hasUpdatedAt() => _updatedAt != null;

  // "createdAt" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "uploadedBy" field.
  DocumentReference? _uploadedBy;
  DocumentReference? get uploadedBy => _uploadedBy;
  bool hasUploadedBy() => _uploadedBy != null;

  // "storagePath" field.
  String? _storagePath;
  String get storagePath => _storagePath ?? '';
  bool hasStoragePath() => _storagePath != null;

  // "fileName" field.
  String? _fileName;
  String get fileName => _fileName ?? '';
  bool hasFileName() => _fileName != null;

  // "contentType" field.
  String? _contentType;
  String get contentType => _contentType ?? '';
  bool hasContentType() => _contentType != null;

  // "sizeBytes" field.
  int? _sizeBytes;
  int get sizeBytes => _sizeBytes ?? 0;
  bool hasSizeBytes() => _sizeBytes != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "sourceListingRef" field.
  DocumentReference? _sourceListingRef;
  DocumentReference? get sourceListingRef => _sourceListingRef;
  bool hasSourceListingRef() => _sourceListingRef != null;

  void _initializeFields() {
    _projectRef = snapshotData['projectRef'] as DocumentReference?;
    _title = snapshotData['title'] as String?;
    _type = snapshotData['type'] as String?;
    _fileUrl = snapshotData['fileUrl'] as String?;
    _updatedAt = snapshotData['updatedAt'] as DateTime?;
    _createdAt = snapshotData['createdAt'] as DateTime?;
    _uploadedBy = snapshotData['uploadedBy'] as DocumentReference?;
    _storagePath = snapshotData['storagePath'] as String?;
    _fileName = snapshotData['fileName'] as String?;
    _contentType = snapshotData['contentType'] as String?;
    _sizeBytes = castToType<int>(snapshotData['sizeBytes']);
    _status = snapshotData['status'] as String?;
    _sourceListingRef = snapshotData['sourceListingRef'] as DocumentReference?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('project_documents');

  static Stream<ProjectDocumentsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ProjectDocumentsRecord.fromSnapshot(s));

  static Future<ProjectDocumentsRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => ProjectDocumentsRecord.fromSnapshot(s));

  static ProjectDocumentsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ProjectDocumentsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ProjectDocumentsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ProjectDocumentsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ProjectDocumentsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ProjectDocumentsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createProjectDocumentsRecordData({
  DocumentReference? projectRef,
  String? title,
  String? type,
  String? fileUrl,
  DateTime? updatedAt,
  DateTime? createdAt,
  DocumentReference? uploadedBy,
  String? storagePath,
  String? fileName,
  String? contentType,
  int? sizeBytes,
  String? status,
  DocumentReference? sourceListingRef,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'projectRef': projectRef,
      'title': title,
      'type': type,
      'fileUrl': fileUrl,
      'updatedAt': updatedAt,
      'createdAt': createdAt,
      'uploadedBy': uploadedBy,
      'storagePath': storagePath,
      'fileName': fileName,
      'contentType': contentType,
      'sizeBytes': sizeBytes,
      'status': status,
      'sourceListingRef': sourceListingRef,
    }.withoutNulls,
  );

  return firestoreData;
}

class ProjectDocumentsRecordDocumentEquality
    implements Equality<ProjectDocumentsRecord> {
  const ProjectDocumentsRecordDocumentEquality();

  @override
  bool equals(ProjectDocumentsRecord? e1, ProjectDocumentsRecord? e2) {
    return e1?.projectRef == e2?.projectRef &&
        e1?.title == e2?.title &&
        e1?.type == e2?.type &&
        e1?.fileUrl == e2?.fileUrl &&
        e1?.updatedAt == e2?.updatedAt &&
        e1?.createdAt == e2?.createdAt &&
        e1?.uploadedBy == e2?.uploadedBy &&
        e1?.storagePath == e2?.storagePath &&
        e1?.fileName == e2?.fileName &&
        e1?.contentType == e2?.contentType &&
        e1?.sizeBytes == e2?.sizeBytes &&
        e1?.status == e2?.status &&
        e1?.sourceListingRef == e2?.sourceListingRef;
  }

  @override
  int hash(ProjectDocumentsRecord? e) => const ListEquality().hash([
        e?.projectRef,
        e?.title,
        e?.type,
        e?.fileUrl,
        e?.updatedAt,
        e?.createdAt,
        e?.uploadedBy,
        e?.storagePath,
        e?.fileName,
        e?.contentType,
        e?.sizeBytes,
        e?.status,
        e?.sourceListingRef
      ]);

  @override
  bool isValidKey(Object? o) => o is ProjectDocumentsRecord;
}

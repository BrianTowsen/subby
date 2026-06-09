import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ProjectMembersRecord extends FirestoreRecord {
  ProjectMembersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "projectRef" field.
  DocumentReference? _projectRef;
  DocumentReference? get projectRef => _projectRef;
  bool hasProjectRef() => _projectRef != null;

  // "userRef" field.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "role" field.
  String? _role;
  String get role => _role ?? '';
  bool hasRole() => _role != null;

  // "canViewCost" field.
  bool? _canViewCost;
  bool get canViewCost => _canViewCost ?? false;
  bool hasCanViewCost() => _canViewCost != null;

  // "createdAt" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  void _initializeFields() {
    _projectRef = snapshotData['projectRef'] as DocumentReference?;
    _userRef = snapshotData['userRef'] as DocumentReference?;
    _role = snapshotData['role'] as String?;
    _canViewCost = snapshotData['canViewCost'] as bool?;
    _createdAt = snapshotData['createdAt'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('project_members');

  static Stream<ProjectMembersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ProjectMembersRecord.fromSnapshot(s));

  static Future<ProjectMembersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ProjectMembersRecord.fromSnapshot(s));

  static ProjectMembersRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ProjectMembersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ProjectMembersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ProjectMembersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ProjectMembersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ProjectMembersRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createProjectMembersRecordData({
  DocumentReference? projectRef,
  DocumentReference? userRef,
  String? role,
  bool? canViewCost,
  DateTime? createdAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'projectRef': projectRef,
      'userRef': userRef,
      'role': role,
      'canViewCost': canViewCost,
      'createdAt': createdAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class ProjectMembersRecordDocumentEquality
    implements Equality<ProjectMembersRecord> {
  const ProjectMembersRecordDocumentEquality();

  @override
  bool equals(ProjectMembersRecord? e1, ProjectMembersRecord? e2) {
    return e1?.projectRef == e2?.projectRef &&
        e1?.userRef == e2?.userRef &&
        e1?.role == e2?.role &&
        e1?.canViewCost == e2?.canViewCost &&
        e1?.createdAt == e2?.createdAt;
  }

  @override
  int hash(ProjectMembersRecord? e) => const ListEquality()
      .hash([e?.projectRef, e?.userRef, e?.role, e?.canViewCost, e?.createdAt]);

  @override
  bool isValidKey(Object? o) => o is ProjectMembersRecord;
}

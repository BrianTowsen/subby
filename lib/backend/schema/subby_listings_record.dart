import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SubbyListingsRecord extends FirestoreRecord {
  SubbyListingsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "category" field.
  String? _category;
  String get category => _category ?? '';
  bool hasCategory() => _category != null;

  // "speciality" field.
  String? _speciality;
  String get speciality => _speciality ?? '';
  bool hasSpeciality() => _speciality != null;

  // "province" field.
  String? _province;
  String get province => _province ?? '';
  bool hasProvince() => _province != null;

  // "city" field.
  String? _city;
  String get city => _city ?? '';
  bool hasCity() => _city != null;

  // "suburb" field.
  String? _suburb;
  String get suburb => _suburb ?? '';
  bool hasSuburb() => _suburb != null;

  // "rating" field.
  double? _rating;
  double get rating => _rating ?? 0.0;
  bool hasRating() => _rating != null;

  // "reviewCount" field.
  int? _reviewCount;
  int get reviewCount => _reviewCount ?? 0;
  bool hasReviewCount() => _reviewCount != null;

  // "jobsCompleted" field.
  int? _jobsCompleted;
  int get jobsCompleted => _jobsCompleted ?? 0;
  bool hasJobsCompleted() => _jobsCompleted != null;

  // "experienceYears" field.
  int? _experienceYears;
  int get experienceYears => _experienceYears ?? 0;
  bool hasExperienceYears() => _experienceYears != null;

  // "isVerified" field.
  bool? _isVerified;
  bool get isVerified => _isVerified ?? false;
  bool hasIsVerified() => _isVerified != null;

  // "isTopRated" field.
  bool? _isTopRated;
  bool get isTopRated => _isTopRated ?? false;
  bool hasIsTopRated() => _isTopRated != null;

  // "openNow" field.
  bool? _openNow;
  bool get openNow => _openNow ?? false;
  bool hasOpenNow() => _openNow != null;

  // "whatsappNumber" field.
  String? _whatsappNumber;
  String get whatsappNumber => _whatsappNumber ?? '';
  bool hasWhatsappNumber() => _whatsappNumber != null;

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  // "heroPhotoUrl" field.
  String? _heroPhotoUrl;
  String get heroPhotoUrl => _heroPhotoUrl ?? '';
  bool hasHeroPhotoUrl() => _heroPhotoUrl != null;

  // "photoUrls" field.
  List<String>? _photoUrls;
  List<String> get photoUrls => _photoUrls ?? const [];
  bool hasPhotoUrls() => _photoUrls != null;

  // "services" field.
  List<String>? _services;
  List<String> get services => _services ?? const [];
  bool hasServices() => _services != null;

  // "tags" field.
  List<String>? _tags;
  List<String> get tags => _tags ?? const [];
  bool hasTags() => _tags != null;

  // "searchKeywords" field.
  List<String>? _searchKeywords;
  List<String> get searchKeywords => _searchKeywords ?? const [];
  bool hasSearchKeywords() => _searchKeywords != null;

  // "createdAt" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "updatedAt" field.
  DateTime? _updatedAt;
  DateTime? get updatedAt => _updatedAt;
  bool hasUpdatedAt() => _updatedAt != null;

  // "about" field.
  String? _about;
  String get about => _about ?? '';
  bool hasAbout() => _about != null;

  // "phoneNumber" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  // "openingHours" field.
  String? _openingHours;
  String get openingHours => _openingHours ?? '';
  bool hasOpeningHours() => _openingHours != null;

  // "associations" field.
  List<String>? _associations;
  List<String> get associations => _associations ?? const [];
  bool hasAssociations() => _associations != null;

  // "providerRef" field.
  DocumentReference? _providerRef;
  DocumentReference? get providerRef => _providerRef;
  bool hasProviderRef() => _providerRef != null;

  // "claimedAt" field.
  DateTime? _claimedAt;
  DateTime? get claimedAt => _claimedAt;
  bool hasClaimedAt() => _claimedAt != null;

  // "categorySlug" field.
  String? _categorySlug;
  String get categorySlug => _categorySlug ?? '';
  bool hasCategorySlug() => _categorySlug != null;

  // "provinceSlug" field.
  String? _provinceSlug;
  String get provinceSlug => _provinceSlug ?? '';
  bool hasProvinceSlug() => _provinceSlug != null;

  // "specialitySlug" field.
  String? _specialitySlug;
  String get specialitySlug => _specialitySlug ?? '';
  bool hasSpecialitySlug() => _specialitySlug != null;

  void _initializeFields() {
    _name = snapshotData['name'] as String?;
    _category = snapshotData['category'] as String?;
    _speciality = snapshotData['speciality'] as String?;
    _province = snapshotData['province'] as String?;
    _city = snapshotData['city'] as String?;
    _suburb = snapshotData['suburb'] as String?;
    _rating = castToType<double>(snapshotData['rating']);
    _reviewCount = castToType<int>(snapshotData['reviewCount']);
    _jobsCompleted = castToType<int>(snapshotData['jobsCompleted']);
    _experienceYears = castToType<int>(snapshotData['experienceYears']);
    _isVerified = snapshotData['isVerified'] as bool?;
    _isTopRated = snapshotData['isTopRated'] as bool?;
    _openNow = snapshotData['openNow'] as bool?;
    _whatsappNumber = snapshotData['whatsappNumber'] as String?;
    _email = snapshotData['email'] as String?;
    _heroPhotoUrl = snapshotData['heroPhotoUrl'] as String?;
    _photoUrls = getDataList(snapshotData['photoUrls']);
    _services = getDataList(snapshotData['services']);
    _tags = getDataList(snapshotData['tags']);
    _searchKeywords = getDataList(snapshotData['searchKeywords']);
    _createdAt = snapshotData['createdAt'] as DateTime?;
    _updatedAt = snapshotData['updatedAt'] as DateTime?;
    _about = snapshotData['about'] as String?;
    _phoneNumber = snapshotData['phoneNumber'] as String?;
    _openingHours = snapshotData['openingHours'] as String?;
    _associations = getDataList(snapshotData['associations']);
    _providerRef = snapshotData['providerRef'] as DocumentReference?;
    _claimedAt = snapshotData['claimedAt'] as DateTime?;
    _categorySlug = snapshotData['categorySlug'] as String?;
    _provinceSlug = snapshotData['provinceSlug'] as String?;
    _specialitySlug = snapshotData['specialitySlug'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('subby_listings');

  static Stream<SubbyListingsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => SubbyListingsRecord.fromSnapshot(s));

  static Future<SubbyListingsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => SubbyListingsRecord.fromSnapshot(s));

  static SubbyListingsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      SubbyListingsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static SubbyListingsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      SubbyListingsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'SubbyListingsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is SubbyListingsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createSubbyListingsRecordData({
  String? name,
  String? category,
  String? speciality,
  String? province,
  String? city,
  String? suburb,
  double? rating,
  int? reviewCount,
  int? jobsCompleted,
  int? experienceYears,
  bool? isVerified,
  bool? isTopRated,
  bool? openNow,
  String? whatsappNumber,
  String? email,
  String? heroPhotoUrl,
  DateTime? createdAt,
  DateTime? updatedAt,
  String? about,
  String? phoneNumber,
  String? openingHours,
  DocumentReference? providerRef,
  DateTime? claimedAt,
  String? categorySlug,
  String? provinceSlug,
  String? specialitySlug,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'name': name,
      'category': category,
      'speciality': speciality,
      'province': province,
      'city': city,
      'suburb': suburb,
      'rating': rating,
      'reviewCount': reviewCount,
      'jobsCompleted': jobsCompleted,
      'experienceYears': experienceYears,
      'isVerified': isVerified,
      'isTopRated': isTopRated,
      'openNow': openNow,
      'whatsappNumber': whatsappNumber,
      'email': email,
      'heroPhotoUrl': heroPhotoUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'about': about,
      'phoneNumber': phoneNumber,
      'openingHours': openingHours,
      'providerRef': providerRef,
      'claimedAt': claimedAt,
      'categorySlug': categorySlug,
      'provinceSlug': provinceSlug,
      'specialitySlug': specialitySlug,
    }.withoutNulls,
  );

  return firestoreData;
}

class SubbyListingsRecordDocumentEquality
    implements Equality<SubbyListingsRecord> {
  const SubbyListingsRecordDocumentEquality();

  @override
  bool equals(SubbyListingsRecord? e1, SubbyListingsRecord? e2) {
    const listEquality = ListEquality();
    return e1?.name == e2?.name &&
        e1?.category == e2?.category &&
        e1?.speciality == e2?.speciality &&
        e1?.province == e2?.province &&
        e1?.city == e2?.city &&
        e1?.suburb == e2?.suburb &&
        e1?.rating == e2?.rating &&
        e1?.reviewCount == e2?.reviewCount &&
        e1?.jobsCompleted == e2?.jobsCompleted &&
        e1?.experienceYears == e2?.experienceYears &&
        e1?.isVerified == e2?.isVerified &&
        e1?.isTopRated == e2?.isTopRated &&
        e1?.openNow == e2?.openNow &&
        e1?.whatsappNumber == e2?.whatsappNumber &&
        e1?.email == e2?.email &&
        e1?.heroPhotoUrl == e2?.heroPhotoUrl &&
        listEquality.equals(e1?.photoUrls, e2?.photoUrls) &&
        listEquality.equals(e1?.services, e2?.services) &&
        listEquality.equals(e1?.tags, e2?.tags) &&
        listEquality.equals(e1?.searchKeywords, e2?.searchKeywords) &&
        e1?.createdAt == e2?.createdAt &&
        e1?.updatedAt == e2?.updatedAt &&
        e1?.about == e2?.about &&
        e1?.phoneNumber == e2?.phoneNumber &&
        e1?.openingHours == e2?.openingHours &&
        listEquality.equals(e1?.associations, e2?.associations) &&
        e1?.providerRef == e2?.providerRef &&
        e1?.claimedAt == e2?.claimedAt &&
        e1?.categorySlug == e2?.categorySlug &&
        e1?.provinceSlug == e2?.provinceSlug &&
        e1?.specialitySlug == e2?.specialitySlug;
  }

  @override
  int hash(SubbyListingsRecord? e) => const ListEquality().hash([
        e?.name,
        e?.category,
        e?.speciality,
        e?.province,
        e?.city,
        e?.suburb,
        e?.rating,
        e?.reviewCount,
        e?.jobsCompleted,
        e?.experienceYears,
        e?.isVerified,
        e?.isTopRated,
        e?.openNow,
        e?.whatsappNumber,
        e?.email,
        e?.heroPhotoUrl,
        e?.photoUrls,
        e?.services,
        e?.tags,
        e?.searchKeywords,
        e?.createdAt,
        e?.updatedAt,
        e?.about,
        e?.phoneNumber,
        e?.openingHours,
        e?.associations,
        e?.providerRef,
        e?.claimedAt,
        e?.categorySlug,
        e?.provinceSlug,
        e?.specialitySlug
      ]);

  @override
  bool isValidKey(Object? o) => o is SubbyListingsRecord;
}

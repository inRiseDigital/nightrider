import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrivacySettings {
  final bool publicProfile;
  final bool showLocation;
  final bool showActivity;
  final bool twoFactor;

  const PrivacySettings({
    this.publicProfile = true,
    this.showLocation = false,
    this.showActivity = true,
    this.twoFactor = false,
  });

  factory PrivacySettings.fromMap(Map<String, dynamic> map) => PrivacySettings(
        publicProfile: map['publicProfile'] as bool? ?? true,
        showLocation:  map['showLocation']  as bool? ?? false,
        showActivity:  map['showActivity']  as bool? ?? true,
        twoFactor:     map['twoFactor']     as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'publicProfile': publicProfile,
        'showLocation':  showLocation,
        'showActivity':  showActivity,
        'twoFactor':     twoFactor,
      };

  PrivacySettings copyWith({
    bool? publicProfile,
    bool? showLocation,
    bool? showActivity,
    bool? twoFactor,
  }) =>
      PrivacySettings(
        publicProfile: publicProfile ?? this.publicProfile,
        showLocation:  showLocation  ?? this.showLocation,
        showActivity:  showActivity  ?? this.showActivity,
        twoFactor:     twoFactor     ?? this.twoFactor,
      );
}

class PrivacyService {
  DocumentReference<Map<String, dynamic>>? _doc() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('privacy');
  }

  /// Live stream of privacy settings.
  Stream<PrivacySettings> stream() {
    final doc = _doc();
    if (doc == null) return Stream.value(const PrivacySettings());
    return doc.snapshots().map((snap) => snap.exists && snap.data() != null
        ? PrivacySettings.fromMap(snap.data()!)
        : const PrivacySettings());
  }

  Future<void> update(PrivacySettings settings) async {
    final doc = _doc();
    if (doc == null) return;
    await doc.set(settings.toMap(), SetOptions(merge: true));
  }
}

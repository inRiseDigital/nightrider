import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

final organizerVerificationServiceProvider =
    Provider<OrganizerVerificationService>(
  (ref) => OrganizerVerificationService(FirebaseStorage.instance),
);

/// Uploads KYC evidence to the exact paths and content types storage.rules
/// requires: `kyc/{uid}/{stepId}/{attempt}/{file}`. `attempt` must be the
/// admin-owned `organizerReview.steps.<id>.attempt` the caller already read —
/// this service does not choose it, since only an admin may advance it.
class OrganizerVerificationService {
  const OrganizerVerificationService(this._storage);

  final FirebaseStorage _storage;

  Future<void> _putJpeg(String path, File file) async {
    await _storage.ref(path).putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );
  }

  /// NIC has two shots — front then back — both required before the step can
  /// be marked uploaded.
  Future<void> uploadNic({
    required String uid,
    required int attempt,
    required File front,
    required File back,
  }) async {
    final base = 'kyc/$uid/nic/$attempt';
    await _putJpeg('$base/front.jpg', front);
    await _putJpeg('$base/back.jpg', back);
  }

  Future<void> uploadSelfie({
    required String uid,
    required int attempt,
    required File capture,
  }) async {
    await _putJpeg('kyc/$uid/selfie/$attempt/capture.jpg', capture);
  }

  /// Uploads the walkthrough video and a poster frame extracted on-device —
  /// there is no Cloud Function to generate one server-side (see
  /// FIRESTORE_SCHEMA.md's Cloud Storage section).
  Future<void> uploadWalkthrough({
    required String uid,
    required int attempt,
    required File video,
  }) async {
    final base = 'kyc/$uid/video/$attempt';

    await _storage.ref('$base/walkthrough.mp4').putFile(
          video,
          SettableMetadata(contentType: 'video/mp4'),
        );

    final posterPath = await VideoThumbnail.thumbnailFile(
      video: video.path,
      imageFormat: ImageFormat.JPEG,
      quality: 75,
    );
    if (posterPath != null) {
      await _putJpeg('$base/poster.jpg', File(posterPath));
    }
  }
}

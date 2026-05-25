import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads PDF report bytes to Firebase Storage under users/{uid}/reports/{fileName}
  /// Returns a public, secure download URL.
  Future<String> uploadReport({
    required String userId,
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    try {
      final ref = _storage.ref().child('users/$userId/reports/$fileName');
      
      // Upload metadata
      final metadata = SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'userId': userId,
        },
      );

      final uploadTask = ref.putData(pdfBytes, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Firebase Storage Upload Error: $e');
      rethrow;
    }
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart'; // Needed for kIsWeb
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadHelper {
  static Future<String?> uploadFile({
    required PlatformFile file,
    required String bucketName,
    required String folderPath,
  }) async {
    final supabase = Supabase.instance.client;
    Uint8List? fileBytes;

    try {
      // Safely extract bytes regardless of platform
      if (kIsWeb) {
        fileBytes = file.bytes;
      } else {
        if (file.path != null) {
          fileBytes = await File(file.path!).readAsBytes();
        } else {
          fileBytes = file.bytes;
        }
      }

      if (fileBytes == null) {
        throw Exception("Could not read file data. Bytes are null.");
      }

      // Ensure exact spelling. Supabase buckets are case-sensitive.
      final String safeBucket = bucketName.trim().toLowerCase();
      
      // Upload using the binary stream
      await supabase.storage.from(safeBucket).uploadBinary(
            folderPath,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Return the public URL
      return supabase.storage.from(safeBucket).getPublicUrl(folderPath);

    } catch (e) {
      print("UPLOAD ERROR in bucket '$bucketName': $e");
      rethrow; // Pass error to UI so we can see what actually failed
    }
  }
}
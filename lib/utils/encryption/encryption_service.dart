import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../logger/app_logger.dart';

/// Service for encrypting and decrypting video URLs and files using AES-GCM
class EncryptionService {
  static final _logger = AppLogger.logger;
  static final AesGcm _algorithm = AesGcm.with256bits();
  static SecretKey? _cachedKey;

  /// Get AES key from .env file
  static Future<SecretKey> _getAesKey() async {
    if (_cachedKey != null) {
      return _cachedKey!;
    }

    try {
      final aesKeyBase64 = dotenv.env['AES_KEY'];
      if (aesKeyBase64 == null || aesKeyBase64.isEmpty) {
        throw Exception('AES_KEY not found in .env file');
      }

      final keyBytes = base64Decode(aesKeyBase64);
      _cachedKey = SecretKey(keyBytes);
      return _cachedKey!;
    } catch (e) {
      _logger.e('Error loading AES key: $e');
      rethrow;
    }
  }

  /// Decrypt an encrypted URL
  /// Returns the decrypted URL string
  static Future<String> decryptUrl(
    String encryptedBase64,
    String ivBase64,
    String tagBase64,
  ) async {
    try {
      final secretKey = await _getAesKey();
      final cipherText = base64Decode(encryptedBase64);
      final nonce = base64Decode(ivBase64);
      final macBytes = base64Decode(tagBase64);

      final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));

      final clear = await _algorithm.decrypt(secretBox, secretKey: secretKey);
      return utf8.decode(clear);
    } catch (e) {
      _logger.e('Error decrypting URL: $e');
      rethrow;
    }
  }

  /// Encrypt a file and save it encrypted
  /// Returns the path to the encrypted file
  static Future<String> encryptFile(
    String sourceFilePath,
    String outputFilePath,
  ) async {
    final key = dotenv.env['AES_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('AES_KEY not found in .env file');
    }
    return compute(_encryptFileTask, {
      'source': sourceFilePath,
      'output': outputFilePath,
      'key': key,
    });
  }

  static Future<String> _encryptFileTask(Map<String, String> args) async {
    try {
      final sourceFilePath = args['source']!;
      final outputFilePath = args['output']!;
      final keyBase64 = args['key']!;

      final sourceFile = File(sourceFilePath);
      if (!sourceFile.existsSync()) {
        throw Exception('Source file does not exist: $sourceFilePath');
      }

      final keyBytes = base64Decode(keyBase64);
      final secretKey = SecretKey(keyBytes);
      final fileBytes = await sourceFile.readAsBytes();

      // Encrypt the file
      final secretBox = await _algorithm.encrypt(
        fileBytes,
        secretKey: secretKey,
      );

      // Write encrypted file: nonce (12 bytes) + mac (16 bytes) + ciphertext
      final encryptedData = <int>[
        ...secretBox.nonce,
        ...secretBox.mac.bytes,
        ...secretBox.cipherText,
      ];

      final outputFile = File(outputFilePath);
      outputFile.writeAsBytesSync(encryptedData, flush: true);

      return outputFilePath;
    } catch (e) {
      // _logger.e('Error encrypting file: $e'); // Logger might not be available in isolate
      rethrow;
    }
  }

  /// Decrypt an encrypted file and save it decrypted
  /// Returns the path to the decrypted file
  static Future<String> decryptFile(
    String encryptedFilePath,
    String outputFilePath,
  ) async {
    final key = dotenv.env['AES_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('AES_KEY not found in .env file');
    }
    return compute(_decryptFileTask, {
      'encrypted': encryptedFilePath,
      'output': outputFilePath,
      'key': key,
    });
  }

  static Future<String> _decryptFileTask(Map<String, String> args) async {
    try {
      final encryptedFilePath = args['encrypted']!;
      final outputFilePath = args['output']!;
      final keyBase64 = args['key']!;

      final encryptedFile = File(encryptedFilePath);
      if (!encryptedFile.existsSync()) {
        throw Exception('Encrypted file does not exist: $encryptedFilePath');
      }

      final keyBytes = base64Decode(keyBase64);
      final secretKey = SecretKey(keyBytes);
      final encryptedData = encryptedFile.readAsBytesSync();

      // Extract nonce (12 bytes), mac (16 bytes), and ciphertext
      if (encryptedData.length < 28) {
        throw Exception('Invalid encrypted file format');
      }

      final nonce = encryptedData.sublist(0, 12);
      final macBytes = encryptedData.sublist(12, 28);
      final cipherText = encryptedData.sublist(28);

      final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));

      // Decrypt the file
      final decryptedBytes = await _algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      // Write decrypted file
      final outputFile = File(outputFilePath);
      outputFile.writeAsBytesSync(decryptedBytes, flush: true);

      return outputFilePath;
    } catch (e) {
      rethrow;
    }
  }

  /// Decrypt an encrypted file and return bytes (for streaming/upload)
  /// This is more memory efficient for large files
  static Future<Uint8List> decryptFileToBytes(String encryptedFilePath) async {
    final key = dotenv.env['AES_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('AES_KEY not found in .env file');
    }
    return compute(_decryptFileToBytesTask, {
      'encrypted': encryptedFilePath,
      'key': key,
    });
  }

  static Future<Uint8List> _decryptFileToBytesTask(
    Map<String, String> args,
  ) async {
    try {
      final encryptedFilePath = args['encrypted']!;
      final keyBase64 = args['key']!;

      final encryptedFile = File(encryptedFilePath);
      if (!encryptedFile.existsSync()) {
        throw Exception('Encrypted file does not exist: $encryptedFilePath');
      }

      final keyBytes = base64Decode(keyBase64);
      final secretKey = SecretKey(keyBytes);
      final encryptedData = encryptedFile.readAsBytesSync();

      // Extract nonce (12 bytes), mac (16 bytes), and ciphertext
      if (encryptedData.length < 28) {
        throw Exception('Invalid encrypted file format');
      }

      final nonce = encryptedData.sublist(0, 12);
      final macBytes = encryptedData.sublist(12, 28);
      final cipherText = encryptedData.sublist(28);

      final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));

      // Decrypt the file
      final decryptedBytes = await _algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      return Uint8List.fromList(decryptedBytes);
    } catch (e) {
      rethrow;
    }
  }

  /// Check if a file is encrypted (has our encryption format)
  static Future<bool> isFileEncrypted(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      // Check file size - encrypted files should be at least 28 bytes (12 nonce + 16 mac + some ciphertext)
      final fileSize = await file.length();
      if (fileSize < 28) {
        return false;
      }

      // Encrypted files start with nonce (12 bytes) + mac (16 bytes)
      // We can't definitively check without trying to decrypt, but we can check size
      return fileSize >= 28;
    } catch (e) {
      return false;
    }
  }
}

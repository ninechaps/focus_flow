import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:pointycastle/asn1/asn1_parser.dart';
import 'package:pointycastle/asn1/primitives/asn1_bit_string.dart';
import 'package:pointycastle/asn1/primitives/asn1_integer.dart';
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';

/// RSA-OAEP + SHA-256 encryption service for password transmission.
///
/// The server provides a PEM-format RSA public key. This service encrypts
/// the plaintext password using RSA-OAEP with SHA-256 digest, then returns
/// the ciphertext as a Base64-encoded string.
class RsaEncryptService {
  const RsaEncryptService._();

  /// Encrypt [plainText] using RSA-OAEP with SHA-256 and the given PEM public key.
  ///
  /// Returns a Base64-encoded ciphertext string.
  ///
  /// Throws [FormatException] if the PEM key is invalid.
  /// Throws [ArgumentError] if the plaintext is too long for the key size.
  static String encrypt(String plainText, String publicKeyPem) {
    final publicKey = _parsePublicKeyFromPem(publicKeyPem);
    final encryptor = OAEPEncoding.withSHA256(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

    final input = Uint8List.fromList(utf8.encode(plainText));
    final output = encryptor.process(input);
    return base64Encode(output);
  }

  /// Parse a PEM-format RSA public key into an [RSAPublicKey] object.
  static RSAPublicKey _parsePublicKeyFromPem(String pem) {
    final lines = pem
        .replaceAll('-----BEGIN PUBLIC KEY-----', '')
        .replaceAll('-----END PUBLIC KEY-----', '')
        .replaceAll(RegExp(r'\s+'), '');

    final keyBytes = base64Decode(lines);
    final asn1Parser = ASN1Parser(Uint8List.fromList(keyBytes));

    // SubjectPublicKeyInfo structure
    final topLevelSequence = asn1Parser.nextObject() as ASN1Sequence;
    final publicKeyBitString = topLevelSequence.elements![1] as ASN1BitString;

    // Remove the leading 0x00 byte from the bit string
    final publicKeyBytes = publicKeyBitString.valueBytes!.sublist(1);
    final publicKeyParser = ASN1Parser(Uint8List.fromList(publicKeyBytes));
    final publicKeySequence = publicKeyParser.nextObject() as ASN1Sequence;

    final modulus =
        (publicKeySequence.elements![0] as ASN1Integer).integer!;
    final exponent =
        (publicKeySequence.elements![1] as ASN1Integer).integer!;

    return RSAPublicKey(modulus, exponent);
  }
}

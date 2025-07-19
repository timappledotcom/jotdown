import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class EncryptionService {
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 16; // 128 bits

  /// Generate a password hash using PBKDF2
  static String hashPassword(String password, String salt) {
    final codec = Utf8Codec();
    final key = Pbkdf2().process(
      codec.encode(password),
      codec.encode(salt),
      1000, // iterations
      32, // key length
    );
    return base64.encode(key);
  }

  /// Generate a random salt
  static String generateSalt() {
    final random = SecureRandom('Fortuna')
      ..seed(KeyParameter(_randomBytes(32)));
    final saltBytes = _randomBytes(16);
    return base64.encode(saltBytes);
  }

  /// Derive encryption key from password
  static Uint8List _deriveKey(String password, String salt) {
    final codec = Utf8Codec();
    return Pbkdf2().process(
      codec.encode(password),
      base64.decode(salt),
      1000,
      _keyLength,
    );
  }

  /// Encrypt text using AES
  static String encrypt(String plainText, String password, String salt) {
    final key = _deriveKey(password, salt);
    final iv = _randomBytes(_ivLength);

    final cipher = AESEngine();
    final cbcCipher = CBCBlockCipher(cipher);
    final paddedCipher = PaddedBlockCipherImpl(PKCS7Padding(), cbcCipher);

    paddedCipher.init(
      true,
      PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), iv),
        null,
      ),
    );

    final input = utf8.encode(plainText);
    final encrypted = paddedCipher.process(Uint8List.fromList(input));

    // Combine IV + encrypted data
    final combined = Uint8List.fromList([...iv, ...encrypted]);
    return base64.encode(combined);
  }

  /// Decrypt text using AES
  static String decrypt(String encryptedText, String password, String salt) {
    final key = _deriveKey(password, salt);
    final combined = base64.decode(encryptedText);

    // Extract IV and encrypted data
    final iv = combined.sublist(0, _ivLength);
    final encrypted = combined.sublist(_ivLength);

    final cipher = AESEngine();
    final cbcCipher = CBCBlockCipher(cipher);
    final paddedCipher = PaddedBlockCipherImpl(PKCS7Padding(), cbcCipher);

    paddedCipher.init(
      false,
      PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), iv),
        null,
      ),
    );

    final decrypted = paddedCipher.process(encrypted);
    return utf8.decode(decrypted);
  }

  /// Verify password against hash
  static bool verifyPassword(String password, String hash, String salt) {
    return hashPassword(password, salt) == hash;
  }

  /// Generate random bytes
  static Uint8List _randomBytes(int length) {
    final random = SecureRandom('Fortuna');
    final seed = Uint8List.fromList(
      List.generate(
        32,
        (index) => DateTime.now().millisecondsSinceEpoch + index,
      ),
    );
    random.seed(KeyParameter(seed));

    return random.nextBytes(length);
  }
}

/// PBKDF2 implementation
class Pbkdf2 {
  Uint8List process(
    List<int> password,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    final hmac = HMac(SHA256Digest(), 64);
    final key = Uint8List.fromList(password);
    hmac.init(KeyParameter(key));

    final derivedKey = Uint8List(keyLength);
    final blockCount = (keyLength + hmac.macSize - 1) ~/ hmac.macSize;

    for (int i = 1; i <= blockCount; i++) {
      final block = _generateBlock(hmac, salt, iterations, i);
      final offset = (i - 1) * hmac.macSize;
      final length = (offset + hmac.macSize <= keyLength)
          ? hmac.macSize
          : keyLength - offset;
      derivedKey.setRange(offset, offset + length, block);
    }

    return derivedKey;
  }

  Uint8List _generateBlock(
    HMac hmac,
    List<int> salt,
    int iterations,
    int blockIndex,
  ) {
    final block = Uint8List(hmac.macSize);
    final temp = Uint8List(hmac.macSize);

    // Create initial input (salt + block index)
    final input = Uint8List(salt.length + 4);
    input.setRange(0, salt.length, salt);
    input[salt.length] = (blockIndex >> 24) & 0xFF;
    input[salt.length + 1] = (blockIndex >> 16) & 0xFF;
    input[salt.length + 2] = (blockIndex >> 8) & 0xFF;
    input[salt.length + 3] = blockIndex & 0xFF;

    // First iteration
    hmac.reset();
    hmac.update(input, 0, input.length);
    hmac.doFinal(temp, 0);
    block.setRange(0, block.length, temp);

    // Remaining iterations
    for (int i = 1; i < iterations; i++) {
      hmac.reset();
      hmac.update(temp, 0, temp.length);
      hmac.doFinal(temp, 0);

      for (int j = 0; j < block.length; j++) {
        block[j] ^= temp[j];
      }
    }

    return block;
  }
}

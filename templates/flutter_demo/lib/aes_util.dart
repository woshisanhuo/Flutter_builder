import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

/// AES加密工具类
/// 使用AES-256-CBC模式进行加密和解密
class AesUtil {
  // 密钥长度：32字节（256位）
  static const int keyLength = 32;
  // IV长度：16字节
  static const int ivLength = 16;
  
  // 固定的密钥（实际应用中应该安全存储）
  // 32字节密钥 = 256位
  static final String defaultKey = '0123456789abcdef0123456789abcdef';
  // 16字节IV
  static final String defaultIv = 'abcdef9876543210';

  /// 使用默认密钥和IV加密字符串
  /// [plainText] 明文
  /// 返回Base64编码的密文
  static String encrypt(String plainText) {
    return encryptWithKeyIv(plainText, defaultKey, defaultIv);
  }

  /// 使用默认密钥和IV解密字符串
  /// [cipherText] Base64编码的密文
  /// 返回明文
  static String decrypt(String cipherText) {
    return decryptWithKeyIv(cipherText, defaultKey, defaultIv);
  }

  /// 使用指定密钥和IV加密字符串
  /// [plainText] 明文
  /// [key] 密钥（32字节）
  /// [iv] IV（16字节）
  /// 返回Base64编码的密文
  static String encryptWithKeyIv(String plainText, String key, String iv) {
    try {
      // 确保密钥和IV长度正确
      final validKey = _padToLength(key, keyLength);
      final validIv = _padToLength(iv, ivLength);

      // 创建密钥和IV
      final keyObj = Key.fromUtf8(validKey);
      final ivObj = IV.fromUtf8(validIv);

      // 创建加密器
      final encrypter = Encrypter(AES(keyObj, mode: AESMode.cbc));

      // 加密
      final encrypted = encrypter.encrypt(plainText, iv: ivObj);

      return encrypted.base64;
    } catch (e) {
      throw Exception('加密失败: $e');
    }
  }

  /// 使用指定密钥和IV解密字符串
  /// [cipherText] Base64编码的密文
  /// [key] 密钥（32字节）
  /// [iv] IV（16字节）
  /// 返回明文
  static String decryptWithKeyIv(String cipherText, String key, String iv) {
    try {
      // 确保密钥和IV长度正确
      final validKey = _padToLength(key, keyLength);
      final validIv = _padToLength(iv, ivLength);

      // 创建密钥和IV
      final keyObj = Key.fromUtf8(validKey);
      final ivObj = IV.fromUtf8(validIv);

      // 创建解密器
      final encrypter = Encrypter(AES(keyObj, mode: AESMode.cbc));

      // 解密
      final decrypted = encrypter.decrypt64(cipherText, iv: ivObj);

      return decrypted;
    } catch (e) {
      throw Exception('解密失败: $e');
    }
  }

  /// 生成随机密钥
  /// 返回32字节（256位）的随机密钥的Base64编码
  static String generateRandomKey() {
    final key = Key.fromSecureRandom(keyLength);
    return base64Encode(key.bytes);
  }

  /// 生成随机IV
  /// 返回16字节的随机IV的Base64编码
  static String generateRandomIv() {
    final iv = IV.fromSecureRandom(ivLength);
    return base64Encode(iv.bytes);
  }

  /// 使用随机密钥和IV加密
  /// [plainText] 明文
  /// 返回包含密文、密钥和IV的Map
  static Map<String, String> encryptWithRandomKeyIv(String plainText) {
    final key = generateRandomKey();
    final iv = generateRandomKey();
    
    // 解码密钥和IV
    final keyBytes = base64Decode(key);
    final ivBytes = base64Decode(iv);
    
    // 转换为UTF-8字符串（用于encrypt库）
    final keyStr = utf8.decode(keyBytes, allowMalformed: true);
    final ivStr = utf8.decode(ivBytes, allowMalformed: true);
    
    // 确保长度正确
    final validKey = _padToLength(keyStr, keyLength);
    final validIv = _padToLength(ivStr, ivLength);
    
    final keyObj = Key.fromUtf8(validKey);
    final ivObj = IV.fromUtf8(validIv);
    
    final encrypter = Encrypter(AES(keyObj, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: ivObj);
    
    return {
      'cipherText': encrypted.base64,
      'key': key,
      'iv': iv,
    };
  }

  /// 填充字符串到指定长度
  static String _padToLength(String input, int length) {
    if (input.length >= length) {
      return input.substring(0, length);
    }
    return input.padRight(length, '0');
  }

  /// 将字节数组转换为十六进制字符串
  static String bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// 将十六进制字符串转换为字节数组
  static Uint8List hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }
}
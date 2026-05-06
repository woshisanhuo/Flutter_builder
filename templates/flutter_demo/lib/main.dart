import 'package:flutter/material.dart';
import 'aes_util.dart';

void main() {
  runApp(const AesDemoApp());
}

class AesDemoApp extends StatelessWidget {
  const AesDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AES加解密Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AesHomePage(),
    );
  }
}

class AesHomePage extends StatefulWidget {
  const AesHomePage({super.key});

  @override
  State<AesHomePage> createState() => _AesHomePageState();
}

class _AesHomePageState extends State<AesHomePage> {
  final TextEditingController _plainTextController = TextEditingController();
  final TextEditingController _cipherTextController = TextEditingController();
  final TextEditingController _decryptedTextController = TextEditingController();
  
  String _statusMessage = '';
  bool _isSuccess = false;

  @override
  void dispose() {
    _plainTextController.dispose();
    _cipherTextController.dispose();
    _decryptedTextController.dispose();
    super.dispose();
  }

  void _encrypt() {
    final plainText = _plainTextController.text;
    if (plainText.isEmpty) {
      _showStatus('请输入明文', false);
      return;
    }

    try {
      final cipherText = AesUtil.encrypt(plainText);
      _cipherTextController.text = cipherText;
      _decryptedTextController.clear();
      _showStatus('加密成功！', true);
    } catch (e) {
      _showStatus('加密失败: $e', false);
    }
  }

  void _decrypt() {
    final cipherText = _cipherTextController.text;
    if (cipherText.isEmpty) {
      _showStatus('请先加密或输入密文', false);
      return;
    }

    try {
      final decryptedText = AesUtil.decrypt(cipherText);
      _decryptedTextController.text = decryptedText;
      
      // 验证解密结果与原始明文
      if (decryptedText == _plainTextController.text) {
        _showStatus('解密成功！验证通过', true);
      } else {
        _showStatus('解密成功，但与原始明文不匹配', false);
      }
    } catch (e) {
      _showStatus('解密失败: $e', false);
    }
  }

  void _encryptWithRandomKey() {
    final plainText = _plainTextController.text;
    if (plainText.isEmpty) {
      _showStatus('请输入明文', false);
      return;
    }

    try {
      final result = AesUtil.encryptWithRandomKeyIv(plainText);
      _cipherTextController.text = result['cipherText']!;
      _decryptedTextController.clear();
      _showStatus('使用随机密钥加密成功！\n密钥: ${result['key']}\nIV: ${result['iv']}', true);
    } catch (e) {
      _showStatus('加密失败: $e', false);
    }
  }

  void _clear() {
    _plainTextController.clear();
    _cipherTextController.clear();
    _decryptedTextController.clear();
    _showStatus('已清空', true);
  }

  void _showStatus(String message, bool isSuccess) {
    setState(() {
      _statusMessage = message;
      _isSuccess = isSuccess;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('AES-256-CBC 加解密Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 简介
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AES加密说明',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('• 算法: AES-256-CBC'),
                    const Text('• 密钥长度: 32字节 (256位)'),
                    const Text('• IV长度: 16字节'),
                    const Text('• 填充模式: PKCS7'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 明文输入
            TextField(
              controller: _plainTextController,
              decoration: const InputDecoration(
                labelText: '明文',
                hintText: '请输入要加密的文本',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.text_fields),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // 加密按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _encrypt,
                    icon: const Icon(Icons.lock),
                    label: const Text('加密 (固定密钥)'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _encryptWithRandomKey,
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('加密 (随机密钥)'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 密文显示
            TextField(
              controller: _cipherTextController,
              decoration: const InputDecoration(
                labelText: '密文 (Base64)',
                hintText: '加密后的结果',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // 解密按钮
            ElevatedButton.icon(
              onPressed: _decrypt,
              icon: const Icon(Icons.lock_open),
              label: const Text('解密'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            
            // 解密结果
            TextField(
              controller: _decryptedTextController,
              decoration: const InputDecoration(
                labelText: '解密结果',
                hintText: '解密后的明文',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.visibility),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // 清空按钮
            OutlinedButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.clear),
              label: const Text('清空'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            
            // 状态消息
            if (_statusMessage.isNotEmpty)
              Card(
                color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(
                        _isSuccess ? Icons.check_circle : Icons.error,
                        color: _isSuccess ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            color: _isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

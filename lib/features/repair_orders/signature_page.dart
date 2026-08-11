import 'dart:io';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/theme/app_theme.dart';
import '../../data/local/db_provider.dart';

class SignaturePage extends StatefulWidget {
  final int orderId;
  const SignaturePage({super.key, required this.orderId});

  @override
  State<SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage> {
  final _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool _saving = false;

  Future<void> _save() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('لطفاً امضا کنید')));
      return;
    }
    setState(() => _saving = true);
    final bytes = await _controller.toPngBytes();
    if (bytes == null) {
      setState(() => _saving = false);
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    final sigDir = Directory(p.join(dir.path, 'signatures'));
    if (!await sigDir.exists()) await sigDir.create(recursive: true);
    final path = p.join(sigDir.path, 'sig_${widget.orderId}.png');
    await File(path).writeAsBytes(bytes);

    await DbProvider.repository.setSignature(widget.orderId, path);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('امضای تحویل مشتری'),
        actions: [
          TextButton(
            onPressed: () => _controller.clear(),
            child: const Text('پاک کردن'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'مشتری با امضای زیر تحویل دستگاه را تأیید می‌کند',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Signature(controller: _controller, backgroundColor: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('تأیید و ذخیره امضا'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

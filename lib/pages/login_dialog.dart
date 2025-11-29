import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginDialog extends StatefulWidget {
  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> _submit() async {
    setState(() { loading = true; error = null; });
    try {
      await context.read<AuthProvider>().login(emailCtrl.text.trim(), passCtrl.text.trim());
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() { error = e.toString(); });
    } finally {
      setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2B2623),
      title: const Text('Login', style: TextStyle(color: Colors.white)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: emailCtrl, decoration: const InputDecoration(hintText: 'Email')),
        const SizedBox(height: 8),
        TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'Password')),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.redAccent))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        ElevatedButton(onPressed: loading ? null : _submit, child: loading ? const CircularProgressIndicator() : const Text('Login')),
      ],
    );
  }
}

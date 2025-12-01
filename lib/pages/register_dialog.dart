import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterDialog extends StatefulWidget {
  const RegisterDialog({Key? key}) : super(key: key);

  @override
  State<RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<RegisterDialog> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool loading = false;
  String? error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await context.read<AuthProvider>().register(
            nameCtrl.text.trim(),
            emailCtrl.text.trim(),
            passCtrl.text.trim(),
          );

      if (mounted) Navigator.of(context).pop(true); // sukses daftar
    } catch (e) {
      setState(() {
        error = _mapError(e);
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _mapError(Object e) {
    final msg = e.toString();
    if (msg.contains("email")) return "Email sudah terdaftar.";
    if (msg.contains("422")) return "Data tidak valid. Periksa kembali input Anda.";
    return msg;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF2B2623);
    const card = Color(0xFF362F2C);
    final accent = Colors.deepOrange.shade400;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [accent.withOpacity(0.95), Colors.orange.shade200],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.person_add_alt_1, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Daftar",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text("Buat akun baru untuk melanjutkan",
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // FORM
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // NAME
                    TextFormField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _input("Nama lengkap", Icons.person),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "Nama wajib diisi";
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // EMAIL
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: _input("Email", Icons.email_outlined),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "Email wajib diisi";
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim()))
                          return "Format email salah";
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // PASSWORD
                    TextFormField(
                      controller: passCtrl,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: _input("Password", Icons.lock_outline),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "Password wajib diisi";
                        if (v.length < 6) return "Minimal 6 karakter";
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // ERROR
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: error == null
                          ? const SizedBox.shrink()
                          : Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                error!,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ),
                    ),

                    const SizedBox(height: 10),

                    // REGISTER BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.2),
                              )
                            : const Text("Daftar",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // CANCEL
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: loading ? null : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.white.withOpacity(0.06)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Batal"),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _input(String hint, IconData icon) {
    const bg = Color(0xFF2B2623);

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white70.withOpacity(0.85)),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: bg.withOpacity(0.35),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }
}

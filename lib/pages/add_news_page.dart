import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../models/news_model.dart';

class AddNewsPage extends StatefulWidget {
  final NewsModel? news;
  const AddNewsPage({Key? key, this.news}) : super(key: key);

  @override
  State<AddNewsPage> createState() => _AddNewsPageState();
}

class _AddNewsPageState extends State<AddNewsPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  File? _imageFile;       // Android/iOS
  Uint8List? _webImage;   // Web (bytes)

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.news != null) {
      _titleCtrl.text = widget.news!.title;
      _contentCtrl.text = widget.news!.content;
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    if (kIsWeb) {
      // WEB → read bytes
      _webImage = await picked.readAsBytes();
    } else {
      // ANDROID/iOS → use File
      _imageFile = File(picked.path);
    }

    setState(() {});
  }

  Widget _buildImagePreview() {
    if (kIsWeb && _webImage != null) {
      return Image.memory(_webImage!, height: 160, fit: BoxFit.cover);
    }

    if (!kIsWeb && _imageFile != null) {
      return Image.file(_imageFile!, height: 160, fit: BoxFit.cover);
    }

    // Jika edit dan sudah punya thumbnail bawaan
    if (widget.news?.thumbnail != null) {
      return Image.network(
        widget.news!.thumbnail!,
        height: 160,
        fit: BoxFit.cover,
      );
    }

    return Container(
      height: 160,
      color: Colors.black26,
      child: const Center(
        child: Text("No Image", style: TextStyle(color: Colors.white70)),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final prov = context.read<NewsProvider>();

    try {
      if (widget.news == null) {
        // CREATE
        await prov.createNewsMultipart(
          title: _titleCtrl.text,
          content: _contentCtrl.text,
          fileImage: _imageFile,
          webImage: _webImage,
        );
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Berita berhasil dibuat")));
      } else {
        // UPDATE
        await prov.updateNewsMultipart(
          id: widget.news!.id,
          title: _titleCtrl.text,
          content: _contentCtrl.text,
          fileImage: _imageFile,
          webImage: _webImage,
        );
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Berita berhasil diperbarui")));
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.news != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Berita" : "Tambah Berita")),
      backgroundColor: const Color(0xFF2B2623),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildImagePreview(),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: pickImage,
                child: const Text("Pilih Gambar"),
              ),
              const SizedBox(height: 16),

              // title
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(color: Colors.white),
                validator: (v) => v!.isEmpty ? "Judul wajib diisi" : null,
                decoration: _field("Judul berita"),
              ),
              const SizedBox(height: 16),

              // content
              TextFormField(
                controller: _contentCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 8,
                validator: (v) => v!.isEmpty ? "Konten wajib diisi" : null,
                decoration: _field("Isi konten berita"),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(isEdit ? "Update" : "Create"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _field(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF3A332F),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}

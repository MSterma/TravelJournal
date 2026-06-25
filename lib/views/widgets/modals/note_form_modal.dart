import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../database/app_database.dart';
import '../../../l10n/app_localizations.dart';
import '../../../locator.dart';
import '../../../repositories/local_repo.dart';


class NoteFormModal extends StatefulWidget {
  const NoteFormModal({
    super.key,
    required this.userId,
    required this.lat,
    required this.lng,
    this.initialTravelId,
    required this.scrollController
  });

  final String userId;
  final double lat;
  final double lng;
  final int? initialTravelId;
  final ScrollController scrollController;

  static void show(BuildContext context, {required String userId, required double lat, required double lng, int? initialTravelId, required VoidCallback onSuccess}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16.0,
            right: 16.0,
            top: 16.0,
          ),
          child: NoteFormModal(
            userId: userId,
            lat: lat,
            lng: lng,
            initialTravelId: initialTravelId,
            scrollController: controller,
          ),
        ),
      ),
    ).then((_) => onSuccess());
  }

  @override
  State<NoteFormModal> createState() => _NoteFormModalState();
}

class _NoteFormModalState extends State<NoteFormModal> {
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  int? _selectedTravelId;
  List<Travel> _travels = [];
  final List<String> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedTravelId = widget.initialTravelId;
    _loadTravels();
  }

  Future<void> _loadTravels() async {
    final travels = await locator<LocalRepo>().getTravels(widget.userId);
    setState(() {
      _travels = travels;
      _isLoading = false;
    });
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _photos.addAll(images.map((e) => e.path));
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));

    return ListView(
      controller: widget.scrollController,
      children: [
        Center(
          child: Container(
            width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.grey[500], borderRadius: BorderRadius.circular(10)),
          ),
        ),
        Text(l10n.newNote, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        DropdownButtonFormField<int?>(
          value: _selectedTravelId,
          decoration: InputDecoration(labelText: l10n.travel, border: const OutlineInputBorder()),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.noTravelGeneralNote)),
            ..._travels.map((t) => DropdownMenuItem(value: t.id, child: Text(t.travelName))),
          ],
          onChanged: (val) => setState(() => _selectedTravelId = val),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: l10n.nameRequired, border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _contentController,
          maxLines: 3,
          decoration: InputDecoration(labelText: l10n.contentOptional, border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _pickPhotos,
          icon: const Icon(Icons.photo_library),
          label: Text(l10n.addPhotos),
        ),
        if (_photos.isNotEmpty)
          Container(
            height: 80,
            margin: const EdgeInsets.only(top: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    Image.file(File(_photos[i]), height: 80, width: 80, fit: BoxFit.cover),
                    Positioned(
                      right: 0, top: 0,
                      child: InkWell(
                        onTap: () => setState(() => _photos.removeAt(i)),
                        child: Container(color: Colors.black54, child: const Icon(Icons.close, color: Colors.white, size: 16)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () async {
            if (_nameController.text.isNotEmpty) {
              await locator<LocalRepo>().addNoteWithPhotos(
                widget.userId,
                widget.lat,
                widget.lng,
                _nameController.text,
                _contentController.text.isEmpty ? null : _contentController.text,
                _selectedTravelId,
                _photos,
              );
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: Text(l10n.save.toUpperCase()),
        ),
      ],
    );
  }
}
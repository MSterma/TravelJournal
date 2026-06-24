import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/travels/travels_bloc.dart';
import '../../../bloc/travels/travels_event.dart';
import '../../../bloc/travels/travels_state.dart';
import '../../../database/app_database.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/constants.dart';
import '../common/photo_viewer.dart';
import '../common/image_placeholder.dart';

class TravelsDraggableSheet extends StatelessWidget {
  const TravelsDraggableSheet({
    super.key,
    required this.sheetController,
    required this.onAddTravel,
    required this.onShowNoteDetails,
  });

  final DraggableScrollableController sheetController;
  final VoidCallback onAddTravel;
  final Function(Note, String, List<String>, AppLocalizations)
      onShowNoteDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<TravelsBloc, TravelsState>(
      buildWhen: (prev, curr) {
        if (prev is! TravelsLoaded || curr is! TravelsLoaded) return true;
        return prev.travels != curr.travels ||
            prev.selectedTravelId != curr.selectedTravelId ||
            prev.timelineNotes != curr.timelineNotes ||
            prev.notePhotos != curr.notePhotos;
      },
      builder: (context, state) {
        if (state is! TravelsLoaded) return const SizedBox.shrink();

        return DraggableScrollableSheet(
          controller: sheetController,
          initialChildSize: 0.4,
          minChildSize: 0.1,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2))
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: Colors.grey[500],
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.travelTimeline,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const Icon(Icons.more_vert),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildChip(context, l10n.all, null,
                            state.selectedTravelId),
                        ...state.travels.map((t) => _buildChip(context,
                            t.travelName, t.id, state.selectedTravelId)),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                              label: const Text('+'), onPressed: onAddTravel),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.selectedTravelId == null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(l10n.selectTravelPrompt,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey)),
                    )
                  else if (state.timelineNotes.isEmpty)
                    Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(l10n.noEntriesInTravel))
                  else
                    Column(
                      children: state.timelineNotes.map((n) {
                        return _buildTimelineItem(
                            context,
                            n,
                            state.notePhotos[n.id] ?? [],
                            state.allTimelinePhotos,
                            state.travels,
                            l10n);
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChip(
      BuildContext context, String label, int? travelId, int? selectedTravelId) {
    final isSelected = selectedTravelId == travelId;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          context.read<TravelsBloc>().add(TravelsEvent.selectTravel(travelId));
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildTimelineItem(
      BuildContext context,
      Note note,
      List<String> photos,
      List<String> allTimelinePhotos,
      List<Travel> travels,
      AppLocalizations l10n) {
    final dateStr = "${note.date.day}-${note.date.month}-${note.date.year}";
    final travelName = travels
            .where((t) => t.id == note.travelId)
            .firstOrNull
            ?.travelName ??
        l10n.none;

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(width: 2, height: 16, color: Colors.blue),
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.blue, shape: BoxShape.circle)),
              Container(
                  width: 2,
                  height: photos.isNotEmpty ? 130 : 90,
                  color: Colors.blue),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("$dateStr: ${note.name}",
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                if (photos.isNotEmpty)
                  Container(
                    height: 60,
                    margin: const EdgeInsets.only(top: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      itemBuilder: (ctx, i) {
                        final path = photos[i];
                        final isPlaceholder =
                            path == AppConstants.photoPlaceholder;
                        final exists =
                            !isPlaceholder && File(path).existsSync();

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            onTap: () {
                              final globalIndex =
                                  allTimelinePhotos.indexOf(path);
                              PhotoViewer.show(context,
                                  photos: allTimelinePhotos,
                                  initialIndex:
                                      globalIndex != -1 ? globalIndex : 0,
                                  source: PhotoSource.file);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: exists
                                  ? Image.file(File(path),
                                      width: 60, height: 60, fit: BoxFit.cover)
                                  : const ImagePlaceholder(
                                      width: 60, height: 60),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 30,
                  child: TextButton(
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft),
                    onPressed: () =>
                        onShowNoteDetails(note, travelName, photos, l10n),
                    child: Text(l10n.details),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

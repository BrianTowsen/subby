// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets

import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────────────────────────────
// MEDIA SOURCE HELPER — shared "Take photo / Record video / Gallery"
// bottom sheet + camera capture used by every upload spot in the app.
// The MediaSourceHelper widget below is just a placeholder so FlutterFlow
// accepts this file as a custom widget; the real API is:
//   • showMediaSourceSheet(...)  → asks WHERE the media comes from
//   • captureWithCamera(...)     → opens the camera, returns name + bytes
// Other custom widgets use it by adding, below their header:
//   import 'media_source_helper.dart';
// ─────────────────────────────────────────────────────────────────────

class MediaSourceHelper extends StatelessWidget {
  const MediaSourceHelper({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// A file captured from the camera (or normalized from a picker),
/// carrying exactly what the upload code needs.
class PickedCameraFile {
  const PickedCameraFile({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}

/// Where the user chose to get the media from.
enum MediaPickSource { cameraPhoto, cameraVideo, gallery }

// Palette + type kept in sync with the app's design system.
const Color _sheetInk = Color(0xFF1E282E);
const Color _sheetInkMute = Color(0xFF566670);
const Color _sheetHairline = Color(0xFFEAEEF0);
const String _sheetDisplayFont = 'Inter Tight';
const String _sheetBodyFont = 'Inter';

/// Shows the source chooser. Returns the chosen [MediaPickSource], or null
/// if the sheet was dismissed.
Future<MediaPickSource?> showMediaSourceSheet(
  BuildContext context, {
  bool allowPhoto = true,
  bool allowVideo = false,
  String galleryLabel = 'Choose from gallery',
  String title = 'Add media',
}) {
  Widget option({
    required IconData icon,
    required String label,
    required MediaPickSource value,
    required BuildContext ctx,
  }) {
    return InkWell(
      onTap: () => Navigator.of(ctx).pop(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: _sheetInk),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: _sheetBodyFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _sheetInkMute,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: Color(0xFF93A3AC)),
          ],
        ),
      ),
    );
  }

  return showModalBottomSheet<MediaPickSource>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: _sheetDisplayFont,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                color: _sheetInk,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _sheetHairline),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (allowPhoto)
                  option(
                    icon: Icons.photo_camera_rounded,
                    label: 'Take photo',
                    value: MediaPickSource.cameraPhoto,
                    ctx: ctx,
                  ),
                if (allowVideo)
                  option(
                    icon: Icons.videocam_rounded,
                    label: 'Record video',
                    value: MediaPickSource.cameraVideo,
                    ctx: ctx,
                  ),
                option(
                  icon: Icons.photo_library_rounded,
                  label: galleryLabel,
                  value: MediaPickSource.gallery,
                  ctx: ctx,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    ),
  );
}

/// Opens the camera (photo or video, per [source]) and returns the captured
/// file as name + bytes. Returns null if the user cancelled or nothing was
/// captured. Gallery is NOT handled here — call sites keep their existing
/// FilePicker / ImagePicker gallery code for that.
Future<PickedCameraFile?> captureWithCamera(
  MediaPickSource source, {
  int imageQuality = 85,
  double? maxWidth,
  double? maxHeight,
  Duration maxVideoDuration = const Duration(minutes: 5),
}) async {
  final picker = ImagePicker();
  XFile? shot;
  if (source == MediaPickSource.cameraPhoto) {
    shot = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  } else if (source == MediaPickSource.cameraVideo) {
    shot = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: maxVideoDuration,
    );
  } else {
    return null; // gallery is handled by the call site
  }
  if (shot == null) return null;

  final bytes = await shot.readAsBytes();
  if (bytes.isEmpty) return null;

  // Normalize the name so downstream mime sniffing / extension switches
  // always have something to work with (web camera blobs can be nameless).
  final isVideo = source == MediaPickSource.cameraVideo;
  final fallbackExt = isVideo ? 'mp4' : 'jpg';
  var name = shot.name;
  if (name.isEmpty) {
    name = '${isVideo ? 'camera_video' : 'camera_photo'}_'
        '${DateTime.now().millisecondsSinceEpoch}.$fallbackExt';
  } else if (!name.contains('.')) {
    name = '$name.$fallbackExt';
  }
  return PickedCameraFile(name: name, bytes: bytes);
}

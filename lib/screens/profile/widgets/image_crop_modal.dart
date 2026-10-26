import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../theme/app_colors.dart';

/// Pan/zoom crop step shown before uploading a profile photo or banner.
/// Captures exactly what's visible inside the frame via a RepaintBoundary,
/// matching the backend's `croppedImageData` contract (a flattened bitmap,
/// not a focal-point descriptor — see ProfileService.uploadProfilePicture).
Future<String?> showImageCropModal(
  BuildContext context, {
  required File imageFile,
  required bool isCircle,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => _ImageCropSheet(imageFile: imageFile, isCircle: isCircle),
  );
}

class _ImageCropSheet extends StatefulWidget {
  final File imageFile;
  final bool isCircle;

  const _ImageCropSheet({required this.imageFile, required this.isCircle});

  @override
  State<_ImageCropSheet> createState() => _ImageCropSheetState();
}

class _ImageCropSheetState extends State<_ImageCropSheet> {
  final _repaintKey = GlobalKey();
  final _transformController = TransformationController();
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final base64Str = base64Encode(bytes);
      if (mounted) Navigator.pop(context, 'data:image/png;base64,$base64Str');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final frameSize = widget.isCircle ? 260.0 : 320.0;
    final frameHeight = widget.isCircle ? 260.0 : 140.0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text(
              widget.isCircle ? 'Adjust Photo' : 'Adjust Banner',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pinch to zoom, drag to reposition',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ClipPath(
              clipper: widget.isCircle ? _CircleClipper() : null,
              child: RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  width: frameSize,
                  height: frameHeight,
                  color: Colors.grey[200],
                  clipBehavior: Clip.hardEdge,
                  decoration: widget.isCircle
                      ? const BoxDecoration(shape: BoxShape.circle)
                      : BoxDecoration(borderRadius: BorderRadius.circular(12)),
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 0.5,
                    maxScale: 4,
                    child: Image.file(widget.imageFile, fit: BoxFit.cover, width: frameSize, height: frameHeight),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

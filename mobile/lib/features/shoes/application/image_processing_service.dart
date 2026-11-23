import 'dart:io';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final imageProcessingServiceProvider = Provider((ref) => ImageProcessingService());

class ImageProcessingService {
  final SubjectSegmenter _segmenter;

  ImageProcessingService()
      : _segmenter = SubjectSegmenter(
          options: SubjectSegmenterOptions(
            enableMultipleSubjects: SubjectResultOptions(
              enableConfidenceMask: true,
              enableSubjectBitmap: true,
            ),
            enableForegroundBitmap: false,
            enableForegroundConfidenceMask: false,
          ),
        );

  Future<void> dispose() async {
    await _segmenter.close();
  }

  Future<File?> removeBackground(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final result = await _segmenter.processImage(inputImage);

      if (result.subjects.isEmpty) {
        return null;
      }

      final bytes = await imageFile.readAsBytes();
      var originalImage = img.decodeImage(bytes);
      
      if (originalImage == null) return null;

      // Apply EXIF orientation so the image is upright
      originalImage = img.bakeOrientation(originalImage);

      if (!originalImage.hasAlpha) {
        originalImage = originalImage.convert(numChannels: 4);
      }

      final subject = result.subjects.first;
      final mask = subject.confidenceMask;
      if (mask == null) return null;

      int width = subject.width;
      int height = subject.height;
      int startX = subject.startX;
      int startY = subject.startY;

      // Apply mask — set alpha based on confidence
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final confidence = mask[y * width + x];
          final imgX = startX + x;
          final imgY = startY + y;
          
          if (imgX >= 0 && imgX < originalImage.width && imgY >= 0 && imgY < originalImage.height) {
            final pixel = originalImage.getPixel(imgX, imgY);
            if (confidence < 0.5) {
              pixel.a = 0;
            } else {
              pixel.a = (confidence * 255).toInt();
            }
          }
        }
      }

      // Clear everything outside the subject bounding box
      for (int y = 0; y < originalImage.height; y++) {
        for (int x = 0; x < originalImage.width; x++) {
          if (x < startX || x >= startX + width || y < startY || y >= startY + height) {
            originalImage.getPixel(x, y).a = 0;
          }
        }
      }

      var cropped = img.copyCrop(originalImage, x: startX, y: startY, width: width, height: height);

      // Orient the shoe so the sole faces down.
      // Strategy: if the image is taller than wide (portrait), rotate it 90° clockwise
      // so the shoe lies horizontally. Then check which side is "heavier" (darker/denser)
      // to determine if we need to flip vertically so the sole is at the bottom.
      if (cropped.height > cropped.width * 1.3) {
        // Shoe is vertical — rotate 90° clockwise to make it horizontal
        cropped = img.copyRotate(cropped, angle: 90);
      }

      // Detect sole orientation: the sole tends to be a flatter, denser edge.
      // Compare the average opacity-weighted brightness of the top half vs bottom half.
      // The sole (rubber, darker) should be at the bottom.
      cropped = _orientSoleDown(cropped);

      // Resize to max 512px on longest side to keep upload size small
      const maxDim = 512;
      if (cropped.width > maxDim || cropped.height > maxDim) {
        if (cropped.width >= cropped.height) {
          cropped = img.copyResize(cropped, width: maxDim);
        } else {
          cropped = img.copyResize(cropped, height: maxDim);
        }
      }

      final pngBytes = img.encodePng(cropped);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${const Uuid().v4()}.png');
      await tempFile.writeAsBytes(pngBytes);
      
      return tempFile;
    } catch (e) {
      print('Error removing background: $e');
      return null;
    }
  }

  /// Orient the shoe so the sole faces down.
  /// 
  /// Heuristic: The sole of a shoe is typically the densest, darkest horizontal
  /// edge. We compare the density of opaque pixels in the bottom quarter vs
  /// the top quarter. If the top quarter has more opaque-pixel density than
  /// the bottom, the shoe is upside-down and we flip it vertically.
  img.Image _orientSoleDown(img.Image image) {
    final quarterH = (image.height * 0.25).toInt();
    if (quarterH <= 0) return image;

    int topOpaqueCount = 0;
    int bottomOpaqueCount = 0;
    double topBrightness = 0;
    double bottomBrightness = 0;

    // Scan top quarter
    for (int y = 0; y < quarterH; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        if (pixel.a > 128) {
          topOpaqueCount++;
          // Luminance approximation
          topBrightness += (pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114);
        }
      }
    }

    // Scan bottom quarter
    for (int y = image.height - quarterH; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        if (pixel.a > 128) {
          bottomOpaqueCount++;
          bottomBrightness += (pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114);
        }
      }
    }

    // The sole side should have more opaque pixels (it's the flat edge)
    // and/or be darker (rubber sole). If the top has significantly more
    // opaque pixels, the shoe is upside down — flip it.
    if (topOpaqueCount > 0 && bottomOpaqueCount > 0) {
      final topDensity = topOpaqueCount / (quarterH * image.width);
      final bottomDensity = bottomOpaqueCount / (quarterH * image.width);
      
      final topAvgBright = topBrightness / topOpaqueCount;
      final bottomAvgBright = bottomBrightness / bottomOpaqueCount;

      // Score: higher density + lower brightness = more likely to be sole
      // We use a combined score: density * (1 - normalized_brightness)
      final topScore = topDensity * (1.0 - topAvgBright / 255.0);
      final bottomScore = bottomDensity * (1.0 - bottomAvgBright / 255.0);

      if (topScore > bottomScore * 1.15) {
        // Top looks like the sole — flip vertically
        return img.flipVertical(image);
      }
    } else if (topOpaqueCount > bottomOpaqueCount * 1.3) {
      // Fallback: top has way more pixels, shoe is upside down
      return img.flipVertical(image);
    }

    return image;
  }
}

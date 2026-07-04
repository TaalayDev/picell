import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:file_picker/file_picker.dart';
import 'package:platform/platform.dart';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

import 'image_helper.dart';

/// Converts raw ARGB pixels to (optionally resized) PNG bytes. Top-level so
/// it can run in a background isolate via [compute].
Uint8List _encode32BitPng(
  ({Uint32List pixels, int width, int height, int? exportWidth, int? exportHeight}) args,
) {
  img.Image image = img.Image.fromBytes(
    width: args.width,
    height: args.height,
    bytes: ImageHelper.fixColorChannels(args.pixels).buffer,
    numChannels: 4,
  );
  if (args.exportWidth != null && args.exportHeight != null) {
    image = img.copyResize(
      image,
      width: args.exportWidth!,
      height: args.exportHeight!,
    );
  }
  return Uint8List.fromList(img.encodePng(image));
}

class FileUtils {
  final BuildContext context;

  FileUtils(this.context);

  Future<void> saveJpg(Uint8List bytes) async {
    final img.Image jpgImage = img.decodeImage(bytes)!;
    final jpg = img.encodeJpg(jpgImage, quality: 90);

    final fileName = 'pixelart_${DateTime.now().millisecondsSinceEpoch}.jpg';

    saveImage(jpg, fileName);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image saved as $fileName')),
    );
  }

  Future<void> save32Bit(
    Uint32List pixels,
    int width,
    int height, {
    double? exportWidth,
    double? exportHeight,
  }) async {
    final png = await compute(_encode32BitPng, (
      pixels: pixels,
      width: width,
      height: height,
      exportWidth: exportWidth?.toInt(),
      exportHeight: exportHeight?.toInt(),
    ));

    final fileName = 'pixelart_${DateTime.now().millisecondsSinceEpoch}.png';

    await saveImage(png, fileName);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image saved as $fileName')),
    );
  }

  Future<void> save(String name, String contents) async {
    final directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$name';

    if (kIsWeb) {
      final blob = html.Blob([contents]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = name;
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } else {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: name,
      );

      if (outputFile == null) {
        return;
      }

      final File file = File(outputFile);
      await file.writeAsString(contents);
    }
  }

  Future<String?> readProjectFileContents() async {
    final completer = Completer<String?>();
    if (kIsWeb) {
      final html.InputElement input = html.document.createElement('input') as html.InputElement
        ..type = 'file'
        ..accept = '.pxv'
        ..style.display = 'none';

      input.onChange.listen((event) {
        final html.File file = input.files!.first;
        final reader = html.FileReader();
        reader.readAsText(file);
        reader.onLoadEnd.listen((event) {
          final String contents = reader.result as String;
          completer.complete(contents);
        });
      });
      html.document.body!.children.add(input);
      input.click();
    } else {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pxv'],
      );

      if (result != null) {
        final File file = File(result.files.single.path!);
        final String contents = await file.readAsString();
        completer.complete(contents);
      }
    }

    return completer.future;
  }

  Future<img.Image?> pickImageFile() async {
    final completer = Completer<img.Image?>();

    if (kIsWeb) {
      final html.InputElement input = html.document.createElement('input') as html.InputElement
        ..type = 'file'
        ..accept = 'image/*'
        ..style.display = 'none';

      input.onChange.listen((event) {
        final html.File file = input.files!.first;
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((event) {
          final Uint8List bytes = Uint8List.fromList(
            reader.result as List<int>,
          );
          completer.complete(img.decodeImage(bytes));
        });
      });
      html.document.body!.children.add(input);
      input.click();
    } else {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        final File file = File(result.files.single.path!);
        final bytes = img.decodeImage(await file.readAsBytes());

        completer.complete(bytes);
      }
    }

    return completer.future;
  }

  Future<void> saveImage(Uint8List imageData, String fileName) async {
    if (kIsWeb) {
      _downloadFileWeb(imageData, fileName);
    } else {
      const platform = LocalPlatform();

      if (platform.isMacOS || platform.isWindows || platform.isLinux) {
        await _saveWithFilePicker(imageData, fileName);
      } else if (platform.isIOS || platform.isAndroid) {
        await _saveToGallery(imageData, fileName);
      } else {
        await _saveToDocuments(imageData, fileName);
      }
    }
  }

  Future<void> saveUIImage(ui.Image image, String fileName) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    saveImage(pngBytes, fileName);
  }

  Future<void> _saveWithFilePicker(Uint8List jpg, String fileName) async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: fileName,
    );

    if (outputFile == null) {
      return;
    }

    final File file = File(outputFile);
    await file.writeAsBytes(jpg);
  }

  void _downloadFileWeb(Uint8List bytes, String fileName) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = fileName;
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _saveToGallery(Uint8List jpg, String fileName) async {
    await ImageGallerySaverPlus.saveImage(
      jpg,
      name: fileName,
      quality: 100,
    );
  }

  Future<void> _saveToDocuments(Uint8List jpg, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    await File(filePath).writeAsBytes(jpg);
  }
}

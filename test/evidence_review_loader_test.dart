import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkingmudde/widgets/evidence_review_loader.dart';

void main() {
  setUpAll(() async {
    // Optional real font for the local visual previews; assertions do not depend on it.
    final fontFile = File('C:/Windows/Fonts/segoeui.ttf');
    if (fontFile.existsSync()) {
      await (FontLoader('Roboto')..addFont(
            Future.value(ByteData.sublistView(fontFile.readAsBytesSync())),
          ))
          .load();
    }
    final iconFile = File(
      'C:/ProgramData/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (iconFile.existsSync()) {
      await (FontLoader('MaterialIcons')..addFont(
            Future.value(ByteData.sublistView(iconFile.readAsBytesSync())),
          ))
          .load();
    }
  });
  final pixel = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aD1sAAAAASUVORK5CYII=',
  );
  final previewPhoto = File('../synthetic-no-parking-test.png');
  final photo = previewPhoto.existsSync()
      ? previewPhoto.readAsBytesSync()
      : pixel;

  testWidgets(
    'photo packing, driving and station loop stays live until removed',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final boundary = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: boundary,
            child: Scaffold(
              body: EvidenceReviewLoader(photos: [photo, photo, photo, photo]),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(
        () => precacheImage(
          ResizeImage(MemoryImage(photo), width: 120),
          tester.element(find.byType(EvidenceReviewLoader)),
        ),
      );
      await tester.pump();
      expect(find.text('Packing your evidence'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(() => _snapshot(boundary, 'packing'));
      await tester.pump(const Duration(milliseconds: 3400));
      expect(find.text('On the road to review'), findsOneWidget);
      await tester.runAsync(() => _snapshot(boundary, 'driving'));
      await tester.pump(const Duration(milliseconds: 2200));
      expect(find.text('Awaiting the result'), findsOneWidget);
      await tester.runAsync(() => _snapshot(boundary, 'station'));
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.text('Packing your evidence'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('small display and reduced motion support video evidence', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 480),
            disableAnimations: true,
            textScaler: TextScaler.linear(1.4),
          ),
          child: const Scaffold(
            body: EvidenceReviewLoader(photos: [], isVideo: true),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Review in progress'), findsOneWidget);
    expect(find.text('1 clip'), findsOneWidget);
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('Review in progress'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

Future<void> _snapshot(GlobalKey key, String phase) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final directory = Directory('build/animation-previews')
    ..createSync(recursive: true);
  File(
    '${directory.path}/$phase.png',
  ).writeAsBytesSync(bytes!.buffer.asUint8List());
  image.dispose();
}

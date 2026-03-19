import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class PhotoCaptureViewport extends StatelessWidget {
  final Uint8List? previewBytes;
  final bool analyzing;
  final String? error;
  final Future<void>? cameraFuture;
  final CameraController? controller;

  const PhotoCaptureViewport({
    super.key,
    required this.previewBytes,
    required this.analyzing,
    required this.error,
    required this.cameraFuture,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        color: const Color(0xFF101513),
        child: previewBytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    previewBytes!,
                    fit: BoxFit.cover,
                  ),
                  if (analyzing)
                    Container(
                      color: Colors.black.withOpacity(0.45),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.white,
                            ),
                            SizedBox(height: 14),
                            Text(
                              "Validating food package photo…",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              )
            : FutureBuilder<void>(
                future: cameraFuture,
                builder: (context, snapshot) {
                  if (error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState != ConnectionState.done ||
                      controller == null ||
                      !controller!.value.isInitialized) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    );
                  }

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(controller!),
                      const PhotoGuideOverlay(),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class PhotoGuideOverlay extends StatelessWidget {
  const PhotoGuideOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.42),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                "Fit the package or ingredient label inside the frame",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 52),
              child: Container(
                width: 250,
                height: 330,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF8DE0A8),
                    width: 3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

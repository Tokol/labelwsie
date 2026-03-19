import 'package:flutter/material.dart';

class PhotoCaptureIntroCard extends StatelessWidget {
  final String barcode;

  const PhotoCaptureIntroCard({
    super.key,
    required this.barcode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE7DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Capture a clear food package photo",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF224D35),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Barcode: $barcode",
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6A7C6F),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Take a readable photo of a packaged food product or its ingredient label. We will validate the image first before extraction.",
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFF6A7C6F),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';



class ImagePreviewerLoader extends StatefulWidget {
  // ignore: prefer_typing_uninitialized_variables
  final imagePath;
  const ImagePreviewerLoader({super.key, required this.imagePath});

  @override
  // ignore: library_private_types_in_public_api
  _ImagePreviewerLoaderState createState() => _ImagePreviewerLoaderState();
}

class _ImagePreviewerLoaderState extends State<ImagePreviewerLoader> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              image: DecorationImage(image: FileImage(widget.imagePath)),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              height: 50,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

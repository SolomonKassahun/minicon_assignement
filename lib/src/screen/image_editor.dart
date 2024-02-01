import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../paint/eye_shadow_painter.dart';
import '../paint/mouse_painter.dart';

class ImageEditor extends StatefulWidget {
  const ImageEditor({super.key});

  @override
  State<ImageEditor> createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> {
  List<Face> _faces = [];
  ui.Image? _uiImage;
  // Rect? _eyesRect;
  // EyeShadowPainter? _painter;
  EyeShadowPainter? _currentPainter;
  bool isEditing = true;

  File? file;
  final _pickerImage = ImagePicker();
  _uploadImage() async {
    print("image changed first");

    try {
      final pickedFile =
          await _pickerImage.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;
      setState(() {
        print("image changed last");
        file = File(pickedFile.path);
        isEditing = false;
      });
      await _detectFaces();
    } catch (e) {
      print("Image picker error " + e.toString());
    }
  }

  Future<void> _detectFaces() async {
    if (file == null) {
      print('No image selected');
      return;
    }

    final inputImage = InputImage.fromFilePath(file!.path);
    final faceDetector = GoogleMlKit.vision.faceDetector();
    final faces = await faceDetector.processImage(inputImage);

    setState(() {
      print("faces assigned ++++");
      _faces = faces;
    });

    if (_faces.length > 1) {
      print("faces is more than one");
      // Show toast message...
      Fluttertoast.showToast(
          msg: "Faces is more than one",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }
    print("faces is one ${_faces.length}");
  }

  bool loading = false;
  bool isEyePainted = false;
  bool isMousePainted = false;

  Future<void> _saveImage() async {
    final directory = await getApplicationDocumentsDirectory();
    final targetPath = "${directory.path}/${path.basename(file!.path)}";
    await File(file!.path).copy(targetPath);
    setState(() {
      isEditing = true;
      isEyePainted = false;
      isMousePainted = false;
    });
    // Share the image...
  }

  late CameraController _controller;
  late CameraController _frontController;

  late Future<void> _initializeControllerFuture;
  late List<CameraDescription> cameras;
  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      setState(() {
        cameras = availableCameras;
        _controller = CameraController(cameras[0], ResolutionPreset.medium);

        _controller.initialize().then((_) {
          if (!mounted) return;
          setState(() {});
        });
        _frontController =
            CameraController(cameras[1], ResolutionPreset.medium);
        _frontController.initialize().then((_) {
          if (!mounted) return;
          setState(() {});
        });
      });
    }).catchError((err) {
      print("Error: $err.code\nError Message: $err.message");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isEditing
            ? const SizedBox.shrink()
            : IconButton(
                onPressed: () {
                  setState(() {
                    isEditing = true;
                    isEyePainted = false;
                    isMousePainted = false;
                  });
                },
                icon: const Icon(Icons.close)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert))
        ],
      ),
      body: Center(
        child: isEditing
            ? Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: Colors.black,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                        height: MediaQuery.of(context).size.height * .6,
                        width: MediaQuery.of(context).size.width,
                        child: CameraPreview(_controller)),
                    const SizedBox(
                      height: 40.0,
                    ),
                    GestureDetector(
                      onTap: () async {
                        try {
                          final image = await _controller.takePicture();
                          print('Image Path: ${image.path}');

                          setState(() {
                            print("image changed last");
                            file = File(image.path);
                            isEditing = false;
                          });
                          await _detectFaces();
                        } catch (e) {
                          print(e);
                        }
                        print("object taped taped");
                      },
                      child: Container(
                        height: 58.0,
                        width: 58.0,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                            onPressed: _uploadImage,
                            icon: const Icon(
                              Icons.photo,
                              color: Colors.white,
                              size: 24,
                            )),
                        IconButton(
                            onPressed: () async {
                              try {
                                final image =
                                    await _frontController.takePicture();
                                print('Image Path: ${image.path}');

                                setState(() {
                                  print("image changed last");
                                  file = File(image.path);
                                  isEditing = false;
                                });
                                await _detectFaces();
                              } catch (e) {
                                print(e);
                              }
                            },
                            icon: const Icon(
                              Icons.change_circle,
                              color: Colors.white,
                              size: 24,
                            ))
                      ],
                    )
                  ],
                ))

            // Center(
            //     child: Column(
            //     children: [
            //       ElevatedButton(
            //           style: ElevatedButton.styleFrom(
            //               backgroundColor: Colors.green),
            //           onPressed: () {
            //             print("test test 123");
            //           },
            //           child: Text("Test Test ")),
            //       Text('No image selected'),
            //     ],
            //   ))
            : SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: Colors.black,
                  child: Column(
                    children: [
                      CustomPaint(
                        painter: _currentPainter,
                        child: Container(
                          height: MediaQuery.of(context).size.height * .6,
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: FileImage(
                                file!,
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 24.0,
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                    onPressed: () {
                                      setState(() {
                                        isEditing = true;
                                        isEyePainted = false;
                                        isMousePainted = false;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.arrow_back_sharp,
                                      color: Colors.white,
                                    )),
                                const Text(
                                  "다시찍기",
                                  style: TextStyle(
                                      fontSize: 12.0, color: Colors.white),
                                )
                              ],
                            ),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 20.0,
                                ),
                                SizedBox(
                                  width: 60.0,
                                  height: 60.0,
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                      ),
                                      onPressed: () async {
                                        print("Clicked one");
                                        setState(() {
                                          isEyePainted = true;
                                        });

                                        if (file != null) {
                                          if (_faces.isNotEmpty) {
                                            final Uint8List imageBytes =
                                                await file!.readAsBytes();
                                            final codec =
                                                await instantiateImageCodec(
                                                    imageBytes);
                                            final FrameInfo frameInfo =
                                                await codec.getNextFrame();
                                            _uiImage =
                                                _uiImage ?? frameInfo.image;
                                            final leftEyePosition = _faces
                                                .first
                                                .landmarks[
                                                    FaceLandmarkType.leftEye]
                                                ?.position;
                                            final rightEyePosition = _faces
                                                .first
                                                .landmarks[
                                                    FaceLandmarkType.rightEye]
                                                ?.position;
                                            if (leftEyePosition != null &&
                                                rightEyePosition != null) {
                                              _currentPainter =
                                                  EyeShadowPainter(
                                                      _uiImage!, _faces.first);
                                            } else {
                                              Fluttertoast.showToast(
                                                  msg:
                                                      "Couldn't find both eyes! \nUse high quality images",
                                                  toastLength:
                                                      Toast.LENGTH_SHORT,
                                                  gravity: ToastGravity.CENTER,
                                                  timeInSecForIosWeb: 1,
                                                  backgroundColor: Colors.red,
                                                  textColor: Colors.white,
                                                  fontSize: 16.0);
                                              print(
                                                  "Couldn't find both eyes! +++ ${leftEyePosition}");
                                            }
                                          }
                                        }
                                      },
                                      child: const Text(
                                        "눈",
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.black),
                                      )),
                                ),
                                const SizedBox(
                                  width: 24.0,
                                ),
                                SizedBox(
                                  width: 60.0,
                                  height: 60.0,
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        print("mouse shadow printed");
                                        setState(() {
                                          isMousePainted = true;
                                        });
                                        if (file != null) {
                                          if (_faces.isNotEmpty) {
                                            final mousePosition = _faces
                                                .first
                                                .landmarks[
                                                    FaceLandmarkType.leftMouth]
                                                ?.position;
                                            final rightEyePosition = _faces
                                                .first
                                                .landmarks[
                                                    FaceLandmarkType.rightEye]
                                                ?.position;
                                            if (mousePosition != null) {
                                              MousePainter(
                                                  _uiImage!, _faces.first);
                                            } else {
                                              print(
                                                  "Couldn't find both eyes! +++ ");
                                            }
                                          }
                                        }
                                        // MousePainter(
                                        //               _uiImage!, _faces.first);
                                      },
                                      child: const Text("입",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black))),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 58.0,
                      ),
                      GestureDetector(
                        onTap: (isEyePainted && isMousePainted)
                            ? () {
                                _saveImage();
                              }
                            : null,
                        child: Container(
                          height: 40.0,
                          width: MediaQuery.of(context).size.width,
                          margin:
                              const EdgeInsets.only(left: 24.0, right: 24.0),
                          decoration: BoxDecoration(
                              color: (isEyePainted && isMousePainted)
                                  ? const Color(0xff7B8FF7)
                                  : const Color(0xffD3D3D3),
                              borderRadius: BorderRadius.circular(5)),
                          child: const Center(
                              child: Text(
                            "저장하기",
                            style:
                                TextStyle(color: Colors.white, fontSize: 12.0),
                          )),
                        ),
                      )

                      //                   CustomPaint(
                      //                     foregroundPainter: _painter,
                      //  child: Image.file(File(_image!.path)),
                      //                     // child: Image.file(File(_image!.path))
                      //                     ),
                    ],
                  ),
                ),
              ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _uploadImage,
      //   tooltip: 'Select image',
      //   child: Icon(Icons.add_a_photo),
      // ),
      // bottomNavigationBar: BottomAppBar(
      //   child: Row(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: <Widget>[
      //       IconButton(
      //         icon: Icon(Icons.check),
      //         onPressed: _isEditing && _faces.length <= 1 ? _saveImage : null,
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}

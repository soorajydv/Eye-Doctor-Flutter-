import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late File _image = File(''); // Initialize with an empty file path
  final picker = ImagePicker(); // Initialize the ImagePicker

  bool _isSkinImage = true;

  Future<void> getImageFromGallery() async {
    final pickedFile = await picker.pickImage(
        source:
            ImageSource.gallery); // Use ImagePicker to get image from gallery
    if (pickedFile != null) {
      _setImage(File(pickedFile.path));
    }
  }

  Future<void> predictImage() async {
    if (!_image.existsSync()) {
      return;
    }

    var request = http.MultipartRequest(
        'POST', Uri.parse('http://192.168.1.89:5000/predict'));
    request.files.add(await http.MultipartFile.fromPath('image', _image.path));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PredictionResultPage(responseBody),
          ),
        );
      } else {
        // Handle error, maybe show a snackbar or dialog
      }
    } catch (e) {
      // Handle error, maybe show a snackbar or dialog
    }
  }

  void _setImage(File imageFile) async {
    // You can implement image validation logic here
    // For demonstration purpose, let's assume an image is considered a skin image if its file size is greater than 0
    setState(() {
      _image = imageFile;
      _isSkinImage = _image.existsSync() && _image.lengthSync() > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eye Disease Detection'),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.blueGrey, // Set the background color
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[200],
                    ),
                    child: _image.existsSync()
                        ? Image.file(
                            _image,
                            height: 200,
                            fit: BoxFit.cover,
                          )
                        : Icon(Icons.image, size: 100, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: getImageFromGallery,
                child: const Text('Choose Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.teal, // Use backgroundColor instead of primary
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSkinImage ? predictImage : null,
                child: const Text('Predict'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.teal, // Use backgroundColor instead of primary
                  padding: EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 20), // Adjust padding for button size
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (!_isSkinImage)
                Text(
                  'Please only take eye image',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PredictionResultPage extends StatelessWidget {
  final String htmlData;

  PredictionResultPage(this.htmlData);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediction Result'),
      ),
      body: WebView(
        initialUrl: Uri.dataFromString(
          htmlData,
          mimeType: 'text/html',
          encoding: Encoding.getByName('utf-8'),
        ).toString(),
        javascriptMode: JavascriptMode.unrestricted,
        navigationDelegate: (NavigationRequest request) {
          if (request.url.startsWith('data:text/html')) {
            return NavigationDecision.navigate;
          } else {
            // Prevent loading other URLs
            return NavigationDecision.prevent;
          }
        },
      ),
    );
  }
}

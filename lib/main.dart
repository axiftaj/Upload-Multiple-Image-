import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_absolute_path/flutter_absolute_path.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:path/path.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<Asset> imagesList = <Asset>[];
  String _error = 'No Error Dectected';

  bool showSpinner = false  ;

  @override
  void initState() {
    super.initState();
  }



  Widget buildGridView() {
    return GridView.count(
      crossAxisCount: 3,
      children: List.generate(imagesList.length, (index) {
        Asset asset = imagesList[index];
        return AssetThumb(
          asset: asset,
          width: 300,
          height: 300,
        );
      }),
    );
  }

  Future<void> loadAssets() async {
    List<Asset> resultList = <Asset>[];
    String error = 'No Error Detected';

    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 300,
        enableCamera: true,
        selectedAssets: imagesList,
        cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
        materialOptions: MaterialOptions(
          actionBarColor: "#abcdef",
          actionBarTitle: "Example App",
          allViewTitle: "All Photos",
          useDetailsView: false,
          selectCircleStrokeColor: "#000000",
        ),
      );
    } on Exception catch (e) {
      error = e.toString();
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      imagesList = resultList;
      _error = error;
    });
  }

  Future uploadImageToServer(BuildContext context) async {

    try{
      setState(() {
        showSpinner = true ;
      });

      var uri = Uri.parse('http://18.224.86.8:4000/api/v1/posts/add');
      http.MultipartRequest request = new http.MultipartRequest('POST', uri);

      request.fields['userid'] = '1';
      request.fields['food_name'] = 'piza';
      request.fields['category'] = 'piza';
      request.fields['serving_no'] = '3';
      request.fields['post_type'] = 'Global';
      request.fields['cooking_date'] = '2020-12-09';
      request.fields['exchange_for'] = 'yes';
      request.fields['spice_level'] = '2';
      request.fields['private_address'] ='yes';
      request.fields['address'] = 'nothing';
      request.fields['city'] = 'Peshawar';
      request.fields['state'] = 'KP';
      request.fields['zipcode'] = '2500';
      request.fields['allergies'] = 'No';
      request.fields['diet_specific'] = 'egg';
      request.fields['include_ingredients'] = 'egg, butter';
      request.fields['exclude_ingredients'] = 'egg butter';
      request.fields['details'] = 'nothing';

      List<http.MultipartFile> newList = new List<http.MultipartFile>();

      for (int i = 0; i < imagesList.length; i++) {
        var path = await FlutterAbsolutePath.getAbsolutePath(imagesList[i].identifier);
        File imageFile =  File(path);

        var stream = new http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();

        var multipartFile = new http.MultipartFile("pictures", stream, length,
            filename: basename(imageFile.path));
        newList.add(multipartFile);
      }



      request.files.addAll(newList);
      var response = await request.send();
      print(response.toString()) ;

      response.stream.transform(utf8.decoder).listen((value) {
        print('value') ;
        print(value);
      });

      if (response.statusCode == 200) {
        setState(() {
          showSpinner = false ;
        });

        print('uploaded');


      } else {
        setState(() {
          showSpinner = false ;
        });
        print('failed');

      }

    }catch(e){
      setState(() {
        showSpinner = false ;
      });
      print(e.toString()) ;

    }


  }
  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: showSpinner,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Center(child: Text('Error: $_error')),
              ElevatedButton(
                child: Text("Pick images"),
                onPressed: loadAssets,
              ),
              Expanded(
                child: buildGridView(),
              ),
              Visibility(
                visible: imagesList.isEmpty ? false : true,
                child: ElevatedButton(
                  child: Text("Upload"),
                  onPressed: ()async {
                    uploadImageToServer(context);
                  },
                ),
              ),
            ],
          ),
        ),

      ),
    );
  }
}

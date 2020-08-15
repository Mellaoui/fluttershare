import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:khadamat/constants.dart';
import 'package:khadamat/models/user.dart';
import 'package:khadamat/pages/home.dart';
import 'package:khadamat/widgets/progress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';

class UploadCard extends StatefulWidget {
  final User currentUser;

  UploadCard({this.currentUser});

  @override
  _UploadCardState createState() => _UploadCardState();
}

class _UploadCardState extends State<UploadCard>
    with AutomaticKeepAliveClientMixin<UploadCard> {
  TextEditingController captionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController introController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController professionalExperienceController =
      TextEditingController();
  TextEditingController trainingController = TextEditingController();
  TextEditingController diplomaController = TextEditingController();
  TextEditingController licenceController = TextEditingController();
  TextEditingController certificationController = TextEditingController();
  TextEditingController experienceController = TextEditingController();
  TextEditingController competencesController = TextEditingController();
  TextEditingController achievementController = TextEditingController();
  TextEditingController recommendationController = TextEditingController();
  TextEditingController languageController = TextEditingController();

  File file;
  bool isUploading = false;
  String cardId = Uuid().v4();

  handleTakePhoto() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );
    setState(() {
      this.file = file;
    });
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      this.file = file;
    });
  }

  selectImage(parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text("Create JobPost"),
          children: <Widget>[
            SimpleDialogOption(
                child: Text("Photo with Camera"), onPressed: handleTakePhoto),
            SimpleDialogOption(
                child: Text("Image from Gallery"),
                onPressed: handleChooseFromGallery),
            SimpleDialogOption(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  Container buildSplashScreen() {
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset('assets/images/upload.svg', height: 260.0),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: RaisedButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  "UploadCard Image",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.0,
                  ),
                ),
                color: Colors.deepOrange,
                onPressed: () => selectImage(context)),
          ),
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_$cardId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 85));
    setState(() {
      file = compressedImageFile;
    });
  }

  Future<String> uploadCardImage(imageFile) async {
    StorageUploadTask uploadCardTask =
        storageRef.child("post_$cardId.jpg").putFile(imageFile);
    StorageTaskSnapshot storageSnap = await uploadCardTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  createBusinessCardInFirestore({
    String mediaUrl,
    String location,
    String description,
    String jobCategory,
    String intro,
    String bio,
    String professionalExperience,
    String training,
    String diploma,
    String licence,
    String certification,
    String experience,
    String competences,
    String achievement,
    String recommendation,
    String language,
  }) {
    businessCardsRef
        .document(widget.currentUser.id)
        .collection("businessCards")
        .document(cardId)
        .setData({
      "cardId": cardId,
      "jobCategory": jobCategory,
      "ownerId": widget.currentUser.id,
      "username": widget.currentUser.username,
      "mediaUrl": mediaUrl,
      "description": description,
      "location": location,
      "timestamp": timestamp,
      "likes": {},
      "intro": intro,
      "bio": bio,
      "professionalExperience": professionalExperience,
      "training": training,
      "diploma": diploma,
      "licence": licence,
      "certification": certification,
      "experience": experience,
      "competences": competences,
      "achievement": achievement,
      "recommendation": recommendation,
      "language": language,
    });
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    if (file != null) await compressImage();
    String mediaUrl = file == null ? "" : await uploadCardImage(file);
    createBusinessCardInFirestore(
      mediaUrl: mediaUrl,
      location: locationController.text,
      description: captionController.text,
      jobCategory: categoryController.text,
      intro: introController.text,
      bio: bioController.text,
      professionalExperience: professionalExperienceController.text,
      training: trainingController.text,
      diploma: diplomaController.text,
      licence: licenceController.text,
      certification: certificationController.text,
      experience: experienceController.text,
      competences: competencesController.text,
      achievement: achievementController.text,
      recommendation: recommendationController.text,
      language: languageController.text,
    );
    captionController.clear();
    locationController.clear();
    categoryController.clear();
    introController.clear();
    bioController.clear();
    professionalExperienceController.clear();
    trainingController.clear();
    diplomaController.clear();
    licenceController.clear();
    certificationController.clear();
    experienceController.clear();
    competencesController.clear();
    achievementController.clear();
    recommendationController.clear();
    languageController.clear();
    setState(() {
      file = null;
      isUploading = false;
      cardId = Uuid().v4();
    });
  }

  Scaffold buildUploadCardForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
//        leading: IconButton(
//            icon: Icon(Icons.arrow_back, color: Colors.black),
//            onPressed: clearImage),
        title: Text(
          "Caption JobPost",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          FlatButton(
            onPressed: isUploading ? null : () => handleSubmit(),
            child: Text(
              "JobPost",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          isUploading ? linearProgress() : Text(""),
          Padding(
            padding: EdgeInsets.only(top: 10.0),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.currentUser.photoUrl),
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: kJobDescription,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          CardTextField(controller: locationController, hint: kJobLocation),
          CardTextField(
              controller: categoryController, hint: "categoryController"),
          CardTextField(controller: introController, hint: "introController"),
          CardTextField(controller: bioController, hint: "bioController"),
          CardTextField(
              controller: professionalExperienceController,
              hint: "professionalExperienceController"),
          CardTextField(
              controller: trainingController, hint: "trainingController"),
          CardTextField(
              controller: diplomaController, hint: "diplomaController"),
          CardTextField(
              controller: licenceController, hint: "licenceController"),
          CardTextField(
              controller: certificationController,
              hint: "certificationController"),
          CardTextField(
              controller: experienceController, hint: "experienceController"),
          CardTextField(
              controller: competencesController, hint: "competencesController"),
          CardTextField(
              controller: achievementController, hint: "achievementController"),
          CardTextField(
              controller: recommendationController,
              hint: "recommendationController"),
          CardTextField(
              controller: languageController, hint: "languageController"),
          Container(
            width: 200.0,
            height: 100.0,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              label: Text(
                "Use Current Location",
                style: TextStyle(color: Colors.white),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              color: Colors.blue,
              onPressed: getUserLocation,
              icon: Icon(
                Icons.my_location,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            alignment: Alignment.centerLeft,
            child: file == null
                ? IconButton(
                    iconSize: 100.0,
                    icon: Icon(
                      Icons.add_a_photo,
                      color: Colors.grey,
                    ),
                    onPressed: () => selectImage(context),
                  )
                : Container(
                    height: 220.0,
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: FileImage(file),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    String completeAddress =
        '${placemark.subThoroughfare} ${placemark.thoroughfare}, ${placemark.subLocality} ${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country}';
    print(completeAddress);
    String formattedAddress = "${placemark.locality}, ${placemark.country}";
    locationController.text = formattedAddress;
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return buildUploadCardForm();
//    return file == null ? buildSplashScreen() : buildUploadCardForm();
  }
}

class CardTextField extends StatelessWidget {
  CardTextField({
    @required this.controller,
    @required this.hint,
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.category,
        color: Colors.orange,
        size: 35.0,
      ),
      title: Container(
        width: 250.0,
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

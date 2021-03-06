import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:khadamat/constants.dart';
import 'package:khadamat/models/job.dart';
import 'package:khadamat/models/review.dart';
import 'package:khadamat/models/user.dart';
import 'package:khadamat/pages/create_freelance_account.dart';
import 'package:khadamat/pages/edit_profile.dart';
import 'package:khadamat/pages/home.dart';
import 'package:khadamat/pages/messages_screen.dart';
import 'package:khadamat/widgets/post.dart';
import 'package:khadamat/widgets/post_tile.dart';
import 'package:khadamat/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class Profile extends StatefulWidget {
  final String profileId;
  final Job job;

  Profile({this.profileId, this.job});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile>
    with AutomaticKeepAliveClientMixin<Profile> {
  User user;
  String selectedTab = "info";
  bool isHired = false;
  bool isLoading = false;
  int postCount = 0;
  int completedJobsCount = 0;
  int evaluation;
  List<Post> posts = [];

  bool get isApplicationResponse {
    return job != null &&
        job.applications[widget.profileId] == null &&
        job.jobOwnerId != widget.profileId &&
        job.jobOwnerId == currentUser.id &&
        job.isVacant == true &&
        job.isOwnerCompleted == false;
  }

  Job get job => widget.job;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getEvaluation();
    getCompletedJobsCount();
    checkIfHired();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: usersRef.document(widget.profileId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return linearProgress();
          user = User.fromDocument(snapshot.data);
          return user.isFreelancer
              ? buildFreelancerScreen(context)
              : buildClientScreen(context);
        });
  }

  Scaffold buildClientScreen(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          SizedBox(),
          Container(
            height: MediaQuery.of(context).size.height * 3 / 5,
            width: double.infinity,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0)),
                color: Colors.white),
            child: buildButton(
                text: kCreateCard,
                function: () => showCreateFreelanceAccount(context,
                    firestoreUser: currentUser)),
          ),
        ],
      ),
    );
  }

  SafeArea buildFreelancerScreen(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: isApplicationResponse ? buildAcceptAppBar(context) : null,
        body: Column(
          children: [
            buildProfileHeader(),
            Expanded(
              child: Container(
                height: MediaQuery.of(context).size.height * 3 / 5,
                width: double.infinity,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30.0),
                        topRight: Radius.circular(30.0)),
                    color: Colors.white),
                child: Column(
                  children: [
                    buildToggleTab(),
                    Divider(height: 0.0, indent: 30.0, endIndent: 30.0),
                    buildContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildProfileHeader() {
    return FutureBuilder(
        future: usersRef.document(widget.profileId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: <Widget>[
//                  linearProgress(),
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 40.0,
                        backgroundImage:
                            CachedNetworkImageProvider(kBlankProfileUrl),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: <Widget>[
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                buildCountColumn("posts", 0),
                                buildCountColumn(kJobsCount, 0),
                                buildCountColumn(kEvaluation, 0),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          User user = User.fromDocument(snapshot.data);
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 40.0,
                      backgroundColor: Theme.of(context).primaryColor,
                      backgroundImage: CachedNetworkImageProvider(
                          user.professionalPhoto ?? kBlankProfileUrl),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              buildCountColumn("posts", postCount),
                              buildCountColumn(kJobsCount, completedJobsCount),
                              buildCountColumn(kEvaluation, evaluation),
                            ],
                          ),
                          buildProfileButton(),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 12.0),
                  child: Text(
                    user.username ?? "",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 4.0),
                  child: Text(
                    user.googleName ?? "",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 2.0),
                  child: Text(
                    user.personalBio ?? "",
                  ),
                ),
              ],
            ),
          );
        });
  }

  Expanded buildProfileInfo() {
    return Expanded(
      child: ListView(
        children: [
          buildProfileInfoField(label: kUsername, text: user.username),
          buildProfileInfoField(label: kEmail, text: user.email),
          buildProfileInfoField(label: kPersonalBio, text: user.personalBio),
          buildProfileInfoField(label: kGender, text: user.gender),
          buildProfileInfoField(label: kLocation, text: user.location),
          buildProfileInfoField(label: kBirthDate, text: user.birthDate),
          buildProfileInfoField(
              label: kProfessionalCategory, text: user.professionalCategory),
          buildProfileInfoField(
              label: kProfessionalTitle, text: user.professionalTitle),
          buildProfileInfoField(
              label: kProfessionalDescription,
              text: user.professionalDescription),
          buildProfileInfoField(label: kKeyWords, text: user.keyWords),
          buildProfileInfoField(label: kDiploma, text: user.diploma),
          buildProfileInfoField(label: kLicence, text: user.licence),
          buildProfileInfoField(
              label: kCertification, text: user.certification),
          buildProfileInfoField(label: kLanguage, text: user.language),
          buildProfileInfoField(label: kExperience, text: user.experience),
          buildProfileInfoField(label: kInternship, text: user.internship),
          buildProfileInfoField(label: kCompetence, text: user.competence),
          buildProfileInfoField(label: kAchievement, text: user.achievement),
          buildProfileInfoField(
              label: kRecommendation, text: user.recommendation),
          buildProfileInfoField(
              label: kCreatedAt,
              text: timeago.format(
                  user.createdAt?.toDate() ?? Timestamp.now().toDate())),
        ],
      ),
    );
  }

  Column buildProfileInfoField(
      {@required String label, @required String text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10.0),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(15.0))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$label ",
                style: kTextStyleProfileInfoHeader,
              ),
              Expanded(
                child: Text(
                  "$text",
                  style: kTextStyleProfileInfo,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 0.0, indent: 30.0, endIndent: 30.0),
      ],
    );
  }

  buildProfileReviews() {
    return FutureBuilder(
        future: reviewsRef
            .document(widget.profileId)
            .collection("reviews")
            .getDocuments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return linearProgress();
          }
          List<Review> reviews = [];
          snapshot.data.documents.forEach((doc) {
            reviews.add(Review.fromDocument(doc));
          });
          if (reviews.isNotEmpty) {
            //TODO implement professional profile interface
            return Center(
                child: Column(
              children: reviews
                  .map((review) => Text(review.freelancerReview ?? ""))
                  .toList(),
            ));
          } else {
            return Center(child: Text(kHasNoReview));
          }
        });
  }

  buildProfileGallery() {
    if (isLoading) {
      return linearProgress();
    } else if (posts.isEmpty) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset('assets/images/no_content.svg', height: 260.0),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text(
                "No Posts",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 40.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (true) {
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(child: PostTile(post)));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (selectedTab == "list") {
      return Column(
        children: posts,
      );
    }
  }

  buildToggleTab() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          onPressed: () => setTab("info"),
          icon: Icon(Icons.info),
          color: selectedTab == 'info'
              ? Theme.of(context).accentColor
              : Theme.of(context).primaryColor,
        ),
        IconButton(
          onPressed: () => setTab("review"),
          icon: Icon(Icons.list),
          color: selectedTab == 'review'
              ? Theme.of(context).accentColor
              : Theme.of(context).primaryColor,
        ),
        IconButton(
          onPressed: () => setTab("gallery"),
          icon: Icon(Icons.grid_on),
          color: selectedTab == 'gallery'
              ? Theme.of(context).accentColor
              : Theme.of(context).primaryColor,
        ),
      ],
    );
  }

  buildContent() {
    if (selectedTab == "info") return buildProfileInfo();
    if (selectedTab == "review") return buildProfileReviews();
    if (selectedTab == "gallery") return buildProfileGallery();
  }

  AppBar buildAcceptAppBar(BuildContext context) {
    return AppBar(
      actions: [
        Expanded(
            child: buildButton(
          text: kReject,
          fillColor: Colors.red,
          function: () {
            toggleIsLoading();
            handleRejectApplication().then((value) {
              toggleIsLoading();
              Navigator.pop(context);
            });
          },
        )),
        Expanded(
            child: buildButton(
          text: kAccept,
          fillColor: Colors.green,
          function: () async {
            toggleIsLoading();
            handleAcceptApplication();
            toggleIsLoading();
            Navigator.pop(context);
            showMessagesScreen(context);
          },
        )),
      ],
    );
  }

  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 15.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  buildProfileButton() {
    // viewing your own profile - should show edit profile button
    bool isProfileOwner = currentUser.id == widget.profileId;
    if (isProfileOwner) {
      return buildButton(
        text: kEditProfile,
        function: () => showEditProfile(context),
      );
    } else if (!isHired && !isApplicationResponse) {
      return buildButton(
        text: kHire,
        function: handleHireUser,
      );
    } else
      return Container();
//    else if (isApplicationResponse) {
//      return buildButton(
//        text: "Post a job",
//        function: handleUnfollowUser,
//      );
//    }
  }

  Future<void> handleUnfollowUser() async {
    setState(() {
      isHired = false;
    });
    // remove hire
    hiresRef
        .document(widget.profileId)
        .collection('userHires')
        .document(currentUser.id)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // remove following
    hiresRef
        .document(currentUser.id)
        .collection('userHires')
        .document(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // delete activity feed item for them
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUser.id)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  Future<void> handleHireUser() async {
    // TODO implement hire function

    setState(() {
      isHired = true;
    });
    // Make auth user hire of THAT user (update THEIR hires collection)
    hiresRef
        .document(widget.profileId)
        .collection('userHires')
        .document(currentUser.id)
        .setData({});

    jobsRef
        .document(currentUser.id)
        .collection("userJobs")
        .document(job.jobId)
        .collection("application")
        .document(widget.profileId)
        .setData({
      "accepted": true,
    });
    // Put THAT user on YOUR following collection (update your following collection)
//    followingRef
//        .document(currentUser.id)
//        .collection('userFollowing')
//        .document(widget.profileId)
//        .setData({});
    // add activity feed item for that user to notify about new hire (us)
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUser.id)
        .setData({
      "type": "accepted",
      "jobOwnerId": widget.profileId,
      "username": currentUser.username,
      "userId": currentUser.id,
      "userProfileImg": currentUser.photoUrl,
      "createdAt": FieldValue.serverTimestamp(),
    });

    activityFeedRef
        .document(currentUser.id)
        .collection('feedItems')
        .document(widget.profileId)
        .setData({
      "type": "accept",
      "jobOwnerId": widget.profileId,
      "username": currentUser.username,
      "userId": currentUser.id,
      "userProfileImg": currentUser.photoUrl,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> handleRejectApplication() async {
    return job.handleRejectApplication(
        applicantId: user.id,
        applicantName: user.username,
        applicantEmail: user.email);
  }

  Future<void> handleAcceptApplication() async {
    return job
        .handleAcceptApplication(
      applicantId: user.id,
      applicantName: user.username,
      applicantEmail: user.email,
    )
        .then((value) {
      job.jobFreelancerId = user.id;
      job.jobFreelancerName = user.username;
      job.jobFreelancerEmail = user.email;
      job.isVacant = false;
    });
  }

  Future<void> checkIfHired() async {
    DocumentSnapshot doc = await jobsRef
        .document(widget.profileId)
        .collection("userJobs")
        .document("jobId")
        .get();
    setState(() {
      isHired = doc.exists;
    });
  }

  Future<void> getEvaluation() async {
    QuerySnapshot snapshot = await reviewsRef
        .document(widget.profileId)
        .collection('userReviews')
        .getDocuments();
    setState(() {
      // TODO implement review evaluation logic
      evaluation = snapshot.documents.length;
    });
  }

  Future<void> getCompletedJobsCount() async {
    QuerySnapshot snapshot = await usersRef
        .document(widget.profileId)
        .collection("userJobs")
        .where("isCompleted", isEqualTo: true)
        .getDocuments();
    setState(() {
      completedJobsCount = snapshot.documents.length;
    });
  }

  Future<void> getProfilePosts() async {
    toggleIsLoading();
    QuerySnapshot snapshot = await postsRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('createdAt', descending: true)
        .getDocuments();
    toggleIsLoading();
    setState(() {
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  void toggleIsLoading() {
    setState(() {
      isLoading = !isLoading;
    });
  }

  setTab(String label) {
    setState(() {
      this.selectedTab = label;
    });
  }

  Container buildButton(
      {String text, Color fillColor = Colors.blue, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 200.0,
          height: 27.0,
          child: Text(
            text,
            style: TextStyle(
              color: isHired ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fillColor,
            border: Border.all(
              color: fillColor,
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
      ),
    );
  }
}

showProfile(BuildContext context,
    {@required String profileId, @required String profileName, Job job}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Profile(
        profileId: profileId,
        job: job,
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:khadamat/constants.dart';
import 'package:khadamat/models/job.dart';
import 'package:khadamat/widgets/custom_button.dart';
import 'package:khadamat/widgets/custom_text_field.dart';
import 'package:khadamat/widgets/header.dart';

class DismissFreelancerScreen extends StatelessWidget {
  final Job job;

  DismissFreelancerScreen({
    @required this.job,
  });
  final TextEditingController dismissReasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(
        context,
        titleText: kDismissCurrentFreelancer,
      ),
      body: Container(
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: [
            Expanded(
              child: CustomTextField(
                  label: kDismissReason, controller: dismissReasonController),
            ),
            CustomButton(
              padding: 5.0,
              fillColor: Colors.amber,
              widthFactor: 2,
              heightFactor: 1.2,
              text: kDismiss,
              function: () => dismissFreelancer(context),
            )
          ],
        ),
      ),
    );
  }

  Future<void> dismissFreelancer(BuildContext context) async {
    job
        .handleDismissFreelancer(dismissReason: dismissReasonController.text)
        .then((value) {
      job.jobFreelancerId = null;
      job.jobFreelancerName = null;
      job.jobFreelancerEmail = null;
      job.isVacant = true;
    });
    Navigator.pop(context);
  }
}

Future<void> showDismissFreelancerScreen(
  BuildContext context, {
  @required Job job,
}) {
  return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DismissFreelancerScreen(
          job: job,
        ),
      ));
}

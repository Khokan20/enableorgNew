import 'dart:async';

import 'package:enableorg/ui/customTexts.dart';
import 'package:enableorg/ui/custom_button.dart';
import 'package:enableorg/widgets/manager/manager_current_questionnaire.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enableorg/controller/manager/manager_questionnaire_notification.dart';
import 'package:enableorg/models/questionnaire_notifications.dart';
import 'package:enableorg/models/user.dart';
import 'package:random_string/random_string.dart';

class ManagerFoundationQuestionnaireNotification extends StatefulWidget {
  final User user;

  ManagerFoundationQuestionnaireNotification({required this.user});
  @override
  State<ManagerFoundationQuestionnaireNotification> createState() =>
      _ManagerFoundationQuestionnaireNotificationState();
}

class _ManagerFoundationQuestionnaireNotificationState
    extends State<ManagerFoundationQuestionnaireNotification> {
  late ManagerQuestionnaireNotificationController notificationController;
  DateTime? _scheduledDate;
  final int daysToExpiry = 14; // 14 days

  @override
  void initState() {
    super.initState();
    notificationController = ManagerQuestionnaireNotificationController();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('New Foundation Questionnaire',
                  style: CustomTextStyles.boldedBodyText),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Send a new questionnaire to the team',
                  style: CustomTextStyles.generalBodyText),
            ],
          ),
          SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: 180.0,
                height: 36.0,
                child: CustomButton(
                  text: Text(
                    'Send now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Cormorant Garamond',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  icon: Icon(Icons.send),
                  onPressed: () async {
                    final QuestionnaireNotification questionnaireNotification =
                        QuestionnaireNotification(
                      qnid: randomAlpha(30),
                      type: QuestionnaireNotificationTypes.FB_COMPLETE,
                      creationTimestamp: Timestamp.now(),
                      startTimestamp: Timestamp.now(),
                      expiryTimestamp:
                          notificationController.setExpiryTimestamp(
                              Timestamp.now(), daysToExpiry),
                      uid: widget.user.uid,
                    );

                    bool success = await _onQuestionnaireNotificationSend(
                        questionnaireNotification);

                    _showNotificationResultDialog(success);
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('Or', style: CustomTextStyles.generalBodyText),
              ),
              SizedBox(
                width: 180.0,
                height: 36.0,
                child: CustomButton(
                  text: Text(
                    'Schedule',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Cormorant Garamond',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  icon: Icon(Icons.schedule_send),
                  onPressed: () {
                    _selectDate(context);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16.0),
          ManagerCurrentQuestionnaire(
            expiryDate: notificationController.getFBCurrentExpiryDate,
            getCompletionProgress:
                notificationController.getCompletionProgressFB,
            user: widget.user,
            onSendRemind: notificationController.sendFBRemindNotification,
          )
        ],
      ),
    );
  }

  Future<bool> _onQuestionnaireNotificationSend(
      QuestionnaireNotification questionnaireNotification) async {
    print("Checking if there is a scheduled notificiation...");

    QuestionnaireNotification? toUpdateNotification =
        await notificationController
            .getFBQuestionnaireNotificationScheduledNext(
                questionnaireNotification.uid);
    print("Checking for ongoing questionnaire notification...");

    QuestionnaireNotification? getOngoingQuestionnaireNotification =
        await notificationController.getOngoingQuestionnaireNotification(
            questionnaireNotification.uid, questionnaireNotification.type);

    if (getOngoingQuestionnaireNotification != null) {
      print("There is an ongoing questionnaire notification."
          " Please wait for it to expire.");
      _showOngoingNotificationFailureDialog();
      return false;
    }

    if (toUpdateNotification != null) {
      print("There is a questionnaire scheduled...");
      bool updateQuestionnaireNotification =
          await _showUpdateConfirmationDialog();
      if (updateQuestionnaireNotification) {
        print("Updating Questionnaire Notification...");
        bool success =
            await notificationController.updateQuestionnaireNotification(
                toUpdateNotification.qnid, questionnaireNotification);
        return success;
      } else {
        return false;
      }
    }

    /* create as there is nothing to update */
    bool success = await notificationController
        .onQuestionnaireNotificationSend(questionnaireNotification);

    return success;
  }

  Future<bool> _showUpdateConfirmationDialog() async {
    Completer<bool> completer = Completer<bool>();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Update Questionnaire'),
          content: Text(
              'An updated questionnaire is available. Do you want to update?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                completer.complete(true); // Resolve the completer with true
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                completer.complete(false); // Resolve the completer with false
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );

    return completer.future; // Return the completer's future
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)), // One year from now
    );

    if (pickedDate != null && pickedDate != _scheduledDate) {
      _updateScheduledDateAndSendNotification(context, pickedDate);
    }
  }

  Future<void> _updateScheduledDateAndSendNotification(
      BuildContext context, DateTime pickedDate) async {
    final QuestionnaireNotification questionnaireNotification =
        QuestionnaireNotification(
      qnid: randomAlpha(30),
      type: QuestionnaireNotificationTypes.FB_COMPLETE,
      creationTimestamp: Timestamp.now(),
      startTimestamp: Timestamp.fromDate(pickedDate),
      expiryTimestamp: notificationController.setExpiryTimestamp(
          Timestamp.fromDate(pickedDate), daysToExpiry),
      uid: widget.user.uid,
    );

    bool success =
        await _onQuestionnaireNotificationSend(questionnaireNotification);

    setState(() {
      _scheduledDate = pickedDate;
      if (success) {
        _showNotificationResultDialog(success);
      }
    });
  }

  void _showOngoingNotificationFailureDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notification could not be sent'),
          content: Text('There is an ongoing notification. Please wait before '
              'sending another notification.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showNotificationResultDialog(bool success) {
    if (!success) {
      //Just for now lol
      return;
    }
    String message = success
        ? 'Questionnaire Notification Sent Successfully!'
        : 'Failed to Send Questionnaire Notification. Please try again later.';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notification Status'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

// ignore_for_file: use_build_context_synchronously

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

class ManagerPulseQuestionnaireNotification extends StatefulWidget {
  final User user;

  ManagerPulseQuestionnaireNotification({required this.user, Key? key})
      : super(key: key);
  @override
  State<ManagerPulseQuestionnaireNotification> createState() =>
      _ManagerPulseQuestionnaireNotificationState();
}

class _ManagerPulseQuestionnaireNotificationState
    extends State<ManagerPulseQuestionnaireNotification> {
  late ManagerQuestionnaireNotificationController notificationController;
  DateTime? _scheduledDate;
  DateTime? nextscheduledDate;
  final int daysToExpiry = 14; // Should be 14 days
  late bool fbQuestionnaireHasBeenSent = false;

  @override
  void initState() {
    setState(() {});
    super.initState();
    notificationController = ManagerQuestionnaireNotificationController();
    _checkIfFBQuestionnaireHasBeenSent();
  }

  _checkIfFBQuestionnaireHasBeenSent() async {
    List<QuestionnaireNotification> notifs =
        await notificationController.getAllQuestionnaireNotifications();

    for (var notif in notifs) {
      print({'$notif =============================\n\n\n'});
      if (notif.type == QuestionnaireNotificationTypes.FB_COMPLETE) {
        fbQuestionnaireHasBeenSent = true;
        setState(() {});
        return;
      }
    }
    fbQuestionnaireHasBeenSent = false;
    setState(() {});
  }

  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _checkIfFBQuestionnaireHasBeenSent();
    if (fbQuestionnaireHasBeenSent) {
      return Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 16.0),
            Center(
              child: SizedBox(
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
                      final QuestionnaireNotification
                          questionnaireNotification = QuestionnaireNotification(
                        qnid: randomAlpha(30),
                        type: QuestionnaireNotificationTypes.WB_COMPLETE,
                        creationTimestamp: Timestamp.now(),
                        startTimestamp: Timestamp.now(),
                        expiryTimestamp: notificationController
                            .setExpiryTimestamp(Timestamp.now(), daysToExpiry),
                        uid: widget.user.uid,
                      );

                      bool success = await _onQuestionnaireNotificationSend(
                          questionnaireNotification, true);

                      _showNotificationResultDialog(success);
                    }),
              ),
            ),
            SizedBox(height: 16.0),
            Center(
              child: SizedBox(
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
                    }),
              ),
            ),
            ManagerCurrentQuestionnaire(
              expiryDate: notificationController.getWBCurrentExpiryDate,
              getCompletionProgress:
                  notificationController.getCompletionProgressWB,
              user: widget.user,
              onSendRemind: notificationController.sendWBRemindNotification,
            )
          ],
        ),
      );
    } else {
      // UI for when FB questionnaire has not been sent
      return Text('Please send a foundation questionnaire first',
          textAlign: TextAlign.center,
          style: CustomTextStyles.boldedReportsHeaderText);
    }
  }

  Future<bool> _onQuestionnaireNotificationSend(
      QuestionnaireNotification questionnaireNotification,
      bool checkMonthsAgo) async {
    print("Checking if there is a scheduled notificiation...");

    QuestionnaireNotification? toUpdateNotification =
        await notificationController
            .getWBQuestionnaireNotificationScheduledNext(// Should be Pulse
                questionnaireNotification.uid);
    print("Checking for ongoing questionnaire notification...");

    // Check if there is a notification within 3 months
    if (checkMonthsAgo) {
      final now = Timestamp.now();
      final threeMonthsAgo = now.toDate().subtract(Duration(days: 3 * 30));
      print(questionnaireNotification.expiryTimestamp.toDate());
      bool inThePast3Months = questionnaireNotification.startTimestamp
          .toDate()
          .isAfter(threeMonthsAgo);

      if (inThePast3Months) {
        print("There is a questionnaire scheduled within 3 months.");
        _showLastQuestionnaireWithingThreeMonthsDialog();
        return false;
      }
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

  Future<DateTime> getInitialDate() async {
    QuestionnaireNotification? notif = await notificationController
        .getMostRecentQuestionnaireNotificationAlreadySent(widget.user.uid);
    if (notif == null) {
      return DateTime.now();
    }

    return notif.expiryTimestamp.toDate().add(Duration(days: 3 * 30));
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: await getInitialDate(),
      firstDate: await getInitialDate(),
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
      type: QuestionnaireNotificationTypes.WB_COMPLETE,
      creationTimestamp: Timestamp.now(),
      startTimestamp: Timestamp.fromDate(pickedDate),
      expiryTimestamp: notificationController.setExpiryTimestamp(
          Timestamp.fromDate(pickedDate), daysToExpiry),
      uid: widget.user.uid,
    );

    bool success = await _onQuestionnaireNotificationSend(
        questionnaireNotification, false);

    setState(() {
      _scheduledDate = pickedDate;
      if (success) {
        _showNotificationResultDialog(success);
      }
    });
  }

  void _showLastQuestionnaireWithingThreeMonthsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notification could not be sent'),
          content: Text(
              'Questionnaire cannnot be sent within 3 months of previous questionnaire survey.'),
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

import 'package:flutter/material.dart';

class TermsConditionsPopup extends StatelessWidget {
  final VoidCallback onAccept;

  TermsConditionsPopup({required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Terms and Conditions'),
      content: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Text(
              'Welcome to our app. By using our services, you agree to the following terms and conditions:',
            ),
            SizedBox(height: 16),
            Text(
              '1. You must accept our terms to use this app.',
            ),
            Text(
              '2. Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
            ),
            Text(
              '3. Sed do eiusmod tempor incididunt ut labore et dolore.',
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Disagree'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onAccept(); // Call the onAccept callback when terms are accepted.
          },
          child: Text('Agree'),
        ),
      ],
    );
  }
}

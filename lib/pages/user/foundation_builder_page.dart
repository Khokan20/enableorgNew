// ignore_for_file: library_private_types_in_public_api

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enableorg/dto/questionList_and_qnid_DTO.dart';
import 'package:enableorg/models/question_answer.dart';
import 'package:enableorg/models/user.dart';
import 'package:enableorg/ui/customTexts.dart';
import 'package:enableorg/ui/custom_slider.dart';
import 'package:enableorg/ui/custom_slider_thumbshape.dart';
import 'package:flutter/material.dart';
import 'package:random_string/random_string.dart';
import '../../controller/user/foundation_builder_controller.dart';
import '../../models/question.dart';

class FoundationBuilderPage extends StatefulWidget {
  final User user;

  FoundationBuilderPage({required this.user});

  @override
  _FoundationBuilderPageState createState() => _FoundationBuilderPageState();
}

class _FoundationBuilderPageState extends State<FoundationBuilderPage> {
  late FoundationBuilderController controller;
  late Future<QuestionListAndQnidDTO> questionsFuture;
  int currentPageIndex = 0;
  int oldPageIndex = 0;
  int currentQuestionIndex = 0;
  List<int> questionResponses = List.filled(1000, 3);
  List<bool> questionsMoved = List<bool>.filled(13, false);
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = FoundationBuilderController(currentUser: widget.user);
    questionsFuture = controller.getQuestions(widget.user);
  }

  void onNextPressed() async {
    QuestionListAndQnidDTO questionsAndQnid = await questionsFuture;
    List<Question> questions = questionsAndQnid.qList;
    String? qnid = questionsAndQnid.qnid;
    if (currentPageIndex < questions.length ~/ 12 + 1) {
      List<Question> currentPageQuestions = questions.sublist(
        currentPageIndex * 12,
        min((currentPageIndex + 1) * 12, questions.length),
      );

      List<int> currentPageResponses = questionResponses.sublist(
        currentPageIndex * 12,
        min((currentPageIndex + 1) * 12, questions.length),
      );

      List<QuestionAnswer> questionAnswers = [];

      for (var i = 0; i < currentPageQuestions.length; i++) {
        var question = currentPageQuestions[i];
        var answer = currentPageResponses[i];

        QuestionAnswer questionAnswer = QuestionAnswer(
          qnid: qnid!,
          qaid: randomAlpha(30),
          creationTimestamp: Timestamp.now(),
          answer: answer,
          qid: question.qid,
          uid: widget.user.uid,
        );

        questionAnswers.add(questionAnswer);
      }

      await controller.saveAndNext(questionAnswers);
    }

    // Scroll to the top
    _scrollController.animateTo(
      0.0,
      duration: Duration(milliseconds: 500), // You can adjust the duration
      curve: Curves.easeInOut,
    );

    setState(() {
      oldPageIndex = currentPageIndex; // Update oldPageIndex
      currentPageIndex++;
      questionsMoved = List<bool>.filled(13, false);
    });
  }

  void updateOldPageIndex() {
    setState(() {
      oldPageIndex = currentPageIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuestionListAndQnidDTO>(
        future: questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No questions available.'));
          } else {
            QuestionListAndQnidDTO questionsAndQnid = snapshot.data!;
            List<Question> questions = questionsAndQnid.qList;

            List<Question> currentPageQuestions;
            if (currentPageIndex * 12 <= questions.length) {
              currentPageQuestions = questions.sublist(
                currentPageIndex * 12,
                min((currentPageIndex + 1) * 12, questions.length),
              );
            } else {
              currentPageQuestions = [];
            }
            List<Widget> heading = [
              SizedBox(
                height: 60,
                child: Text(
                  'Foundation Builder',
                  style: CustomTextStyles.generalHeaderText,
                ),
              ),
              // Add any other widgets you want in your heading here.
            ];
            Widget pageContent;

            if (currentPageQuestions.isEmpty) {
              pageContent = Center(
                child: Text(
                    'No questions available. You have completed all your questions :)'),
              );
            } else {
              pageContent = ListView.builder(
                controller: _scrollController, // Add this line
                itemCount: currentPageQuestions.length,
                itemBuilder: (context, index) {
                  Question question = currentPageQuestions[index];
                  int questionIndex = currentPageIndex * 12 + index;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0), // Padding for question and slider
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                              '${questionIndex + 1}. ${question.question}'),
                        ),
                        CustomSlider(
                          reset: currentPageIndex != oldPageIndex,
                          onReset: updateOldPageIndex,
                          sliderValue:
                              questionResponses[questionIndex].toDouble(),
                          onChanged: (double value) {
                            setState(() {
                              questionResponses[questionIndex] = value.toInt();
                            });
                          },
                          label: questionResponses[questionIndex].toString(),
                          onSliderMoved: (sliderMoved) {
                            setState(() {
                              print(questionsMoved);
                              questionsMoved[index] = sliderMoved;
                            });
                          },
                          customThumbShape: CustomSliderThumbShape(),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
            return Column(
              children: [
                ...heading,
                Expanded(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 10,
                        width: 24,
                        child: Container(
                          alignment: Alignment.center,
                          /*child: Column(
                            children: [
                              Icon(Icons.arrow_upward),
                              RotatedBox(
                                quarterTurns: -1,
                                child: Text('Strongly Disagree'),
                              ),
                              Icon(Icons.arrow_downward),
                            ],
                          ),*/
                          child: Image.asset('Stronglydisagree.png'),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: 0,
                        width: 24,
                        child: Container(
                          alignment: Alignment.center,
                          /*child: Column(
                            children: [
                              Icon(Icons.arrow_upward),
                              RotatedBox(
                                quarterTurns: -1,
                                child: Text('Strongly Agree'),
                              ),
                              Icon(Icons.arrow_downward),
                            ],
                          ),*/
                          child: Image.asset('Stronglyagree.png'),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.only(left: 120, right: 120),
                              child: pageContent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Wrap the "Save" and "Next" buttons in a Row

                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .spaceBetween, // Align them to the left and right
                  children: [
                    // "Save" button - Always visible
                    SizedBox(
                      width: 100,
                    ),
                    SizedBox(
                      // margin: EdgeInsets.only(left: 100),
                      width: 120,
                      // Adjust the width as needed
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle "Save" button press here
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 12, 67, 111),
                          shape: ContinuousRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: 120,
                      height: 100,
                    ), // "Next" button - Conditionally visible
                    if (questionsMoved
                        .sublist(0, currentPageQuestions.length)
                        .every((element) => element))
                      SizedBox(
                        width: 120, // Adjust the width as needed
                        child: ElevatedButton(
                          onPressed: onNextPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 12, 67, 111),
                            shape: ContinuousRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: Text(
                            'Next',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                )
              ],
            );
          }
        });
  }
}

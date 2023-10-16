import 'package:enableorg/ui/custom_slider_thumbshape.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'gradient_slider_custom.dart';

class CustomSlider extends StatefulWidget {
  final double? sliderValue;
  final ValueChanged<double> onChanged;
  final String? label;
  final ValueChanged<bool> onSliderMoved;
  final CustomSliderThumbShape customThumbShape;
  final bool reset;
  final Function onReset;

  CustomSlider(
      {Key? key,
      required this.sliderValue,
      required this.label,
      required this.onChanged,
      required this.onSliderMoved,
      required this.customThumbShape,
      required this.reset,
      required this.onReset});

  @override
  State<CustomSlider> createState() => _CustomSliderState();
}

class _CustomSliderState extends State<CustomSlider> {
  final textController = TextEditingController();
  bool sliderMoved = false;

  @override
  void didUpdateWidget(CustomSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the reset flag is true and reset the sliderMoved state
    if (widget.reset) {
      SchedulerBinding.instance!.addPostFrameCallback((_) {
        setState(() {
          sliderMoved = false;
          widget.onReset();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            sliderMoved = true;
          });
        },
        child: GradientSliderCustom(
          thumbShape: widget.customThumbShape,
          trackHeight: 17,
          trackBorder: 1,
          trackBorderColor: Colors.black,
          activeTrackGradient: sliderMoved
              ? const LinearGradient(colors: [
                  Color(0xFFC00000),
                  Color(0xFFFFC000),
                  Color(0xFFFFFF00),
                  Color(0xFF009BA5),
                  Color(0xFF0070C0),
                  Color(0xFF002060),
                ])
              : LinearGradient(colors: [
                  Color(0xFF213188),
                  Color(0xFF162058),
                  Color(0xFF213188),
                  Color(0xFF162058),
                  Color(0xFF213188),
                  Color(0xFF162058),
                  Color(0xFF213188),
                  Color(0xFF162058),
                ]),
          inactiveTrackGradient: LinearGradient(colors: [
            Color(0xFF213188),
            Color(0xFF162058),
            Color(0xFF213188),
            Color(0xFF162058),
            Color(0xFF213188),
            Color(0xFF162058),
            Color(0xFF213188),
            Color(0xFF162058),
          ]),
          slider: Slider(
            value: widget.sliderValue!,
            min: 1,
            max: 5,
            divisions: 4, // Number of equidistant points
            onChanged: (val) {
              widget.onChanged(val);
              widget.onSliderMoved(true); // Call the onChanged callback
              setState(() {
                sliderMoved = true;
              });
            },
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() async {
  try {
    final interpreter = await Interpreter.fromFile(File('assets/model/model_unquant.tflite'));
    final inputTensor = interpreter.getInputTensor(0);
    print(inputTensor.shape);
  } catch (e) {
    print(e);
  }
}

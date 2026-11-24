import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final image = img.Image(width: 224, height: 224);
  image.setPixelRgba(10, 10, 100, 150, 200, 255);
  final pixel = image.getPixel(10, 10);
  print('R: ${pixel.r}, G: ${pixel.g}, B: ${pixel.b}');
}

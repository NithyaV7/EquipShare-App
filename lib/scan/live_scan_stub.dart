// Live camera scanning is Android only. The web version hides the button.
import 'package:flutter/widgets.dart';

bool get liveScanSupported => false;

Widget buildLiveScanScreen() => const SizedBox.shrink();

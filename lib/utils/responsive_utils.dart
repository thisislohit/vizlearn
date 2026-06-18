import 'package:flutter/material.dart';

class ResponsiveUtils{
  static buttonWidth(BuildContext context) => (MediaQuery.of(context).size.width < 600
  ? MediaQuery.of(context).size.width
      : (MediaQuery.of(context).size.width > 600 && MediaQuery.of(context).size.width < 1000)
  ? MediaQuery.of(context).size.width * 0.8
      : MediaQuery.of(context).size.width * 0.5);
}
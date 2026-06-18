import 'package:flutter/material.dart';
import 'package:vizlearn/utils/app_export.dart';
import 'package:vizlearn/views/widgets/custom_wrapper.dart';

class ContentLibraryScreen extends StatelessWidget {
  const ContentLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomWrapper(
      child: Column(
        children: [
          CustomAppBar(title: 'Content Library'),
          Expanded(
            child: Center(
              child: Text('Content Library Screen'),
            ),
          ),
        ],
      ),
    );
  }
}


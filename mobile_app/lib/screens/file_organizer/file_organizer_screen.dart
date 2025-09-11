import 'package:flutter/material.dart';
import 'package:homie_app/screens/file_organizer/modern_file_organizer_screen.dart';

class FileOrganizerScreen extends StatelessWidget {
  final bool isStandaloneLaunch;
  final String? initialSourcePath;
  final String? initialDestinationPath;
  
  const FileOrganizerScreen({
    super.key,
    this.isStandaloneLaunch = false,
    this.initialSourcePath,
    this.initialDestinationPath,
  });

  @override
  Widget build(BuildContext context) {
    // Use the modern implementation with all the advanced features
    return ModernFileOrganizerScreen(
      isStandaloneLaunch: isStandaloneLaunch,
    );
  }
} 
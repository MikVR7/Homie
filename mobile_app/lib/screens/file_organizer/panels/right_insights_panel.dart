import 'package:flutter/material.dart';
import 'package:homie_app/theme/app_theme.dart';
import 'package:homie_app/widgets/file_organizer/modern/file_insights_dashboard.dart';

class RightInsightsPanel extends StatelessWidget {
  const RightInsightsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      physics: ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FileInsightsDashboard(),
        ],
      ),
    );
  }
}



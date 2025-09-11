import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:homie_app/services/feature_flag_service.dart';

/// In-app help system with guided tours, tooltips, and documentation
class HelpSystem extends StatefulWidget {
  final Widget child;
  final bool enableTooltips;
  final bool enableTours;

  const HelpSystem({
    Key? key,
    required this.child,
    this.enableTooltips = true,
    this.enableTours = true,
  }) : super(key: key);

  @override
  State<HelpSystem> createState() => _HelpSystemState();

  /// Show help overlay for a specific feature
  static void showFeatureHelp(BuildContext context, String feature) {
    final helpData = _getFeatureHelpData(feature);
    if (helpData != null) {
      showDialog(
        context: context,
        builder: (context) => HelpDialog(helpData: helpData),
      );
    }
  }

  /// Show guided tour
  static void startGuidedTour(BuildContext context, String tourName) {
    final tour = _getTourData(tourName);
    if (tour != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GuidedTourScreen(tour: tour),
        ),
      );
    }
  }

  /// Show keyboard shortcuts help
  static void showKeyboardShortcuts(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const KeyboardShortcutsDialog(),
    );
  }

  /// Get feature help data
  static HelpData? _getFeatureHelpData(String feature) {
    final helpContent = _getHelpContent();
    return helpContent[feature];
  }

  /// Get tour data
  static TourData? _getTourData(String tourName) {
    final tours = _getTourContent();
    return tours[tourName];
  }

  /// Get all help content
  static Map<String, HelpData> _getHelpContent() {
    return {
      'file_organizer': HelpData(
        title: 'File Organizer',
        description: 'AI-powered file organization that learns your preferences',
        sections: [
          HelpSection(
            title: 'Getting Started',
            content: '''
• Select a source folder to organize
• Choose your organization style
• Review AI suggestions before applying
• The system learns from your choices
            ''',
          ),
          HelpSection(
            title: 'Organization Styles',
            content: '''
• Smart Categories: AI determines optimal categories
• By File Type: Groups files by extension
• By Date: Organizes by creation/modification date
• Custom: Define your own organization rules
            ''',
          ),
          HelpSection(
            title: 'Tips & Tricks',
            content: '''
• Use batch operations for multiple files
• Bookmark frequently used folders
• Enable real-time monitoring for automatic organization
• Review the activity log to track changes
            ''',
          ),
        ],
        shortcuts: [
          'Ctrl+O: Open folder browser',
          'Ctrl+R: Refresh file list',
          'Ctrl+A: Select all files',
          'Delete: Remove selected files',
        ],
        videos: [
          HelpVideo(
            title: 'Quick Start Guide',
            url: 'https://help.homie.example.com/videos/quickstart',
            duration: '3:45',
          ),
          HelpVideo(
            title: 'Advanced Organization',
            url: 'https://help.homie.example.com/videos/advanced',
            duration: '7:20',
          ),
        ],
      ),
      'batch_operations': HelpData(
        title: 'Batch Operations',
        description: 'Select and operate on multiple files simultaneously',
        sections: [
          HelpSection(
            title: 'Selection Methods',
            content: '''
• Click checkboxes to select individual files
• Use Ctrl+A to select all visible files
• Use Shift+Click to select ranges
• Filter files first to narrow selection
            ''',
          ),
          HelpSection(
            title: 'Available Operations',
            content: '''
• Move: Relocate selected files to a new folder
• Copy: Create copies in a destination folder
• Delete: Remove selected files permanently
• Organize: Apply AI organization to selection
            ''',
          ),
        ],
        shortcuts: [
          'Ctrl+A: Select all',
          'Ctrl+D: Deselect all',
          'Shift+Click: Select range',
          'Space: Toggle selection',
        ],
      ),
      'advanced_search': HelpData(
        title: 'Advanced Search',
        description: 'Powerful search with filters, regex, and content search',
        sections: [
          HelpSection(
            title: 'Search Options',
            content: '''
• Text Search: Find files by name or content
• File Type Filter: Limit to specific file types
• Date Range: Search within date ranges
• Size Filter: Find files by size criteria
            ''',
          ),
          HelpSection(
            title: 'Advanced Features',
            content: '''
• Regular Expressions: Use regex patterns
• Case Sensitivity: Toggle case-sensitive search
• Content Search: Search inside file contents
• Saved Searches: Save frequently used searches
            ''',
          ),
        ],
        shortcuts: [
          'Ctrl+F: Open search',
          'Ctrl+Shift+F: Advanced search',
          'F3: Find next',
          'Shift+F3: Find previous',
        ],
      ),
      'export_options': HelpData(
        title: 'Export Options',
        description: 'Export operation reports and analytics in various formats',
        sections: [
          HelpSection(
            title: 'Export Formats',
            content: '''
• CSV: Spreadsheet-compatible format
• JSON: Structured data format
• HTML: Formatted report for viewing
• PDF: Professional document format
            ''',
          ),
          HelpSection(
            title: 'Export Types',
            content: '''
• Operation Reports: Details of file operations
• Analytics: Usage statistics and insights
• File Lists: Current file organization
• Activity Logs: Historical operation records
            ''',
          ),
        ],
        shortcuts: [
          'Ctrl+E: Quick export',
          'Ctrl+Shift+E: Export options',
        ],
      ),
    };
  }

  /// Get tour content
  static Map<String, TourData> _getTourContent() {
    return {
      'first_time_setup': TourData(
        title: 'Welcome to Homie File Organizer',
        description: 'Let\'s get you started with AI-powered file organization',
        steps: [
          TourStep(
            title: 'Welcome!',
            content: 'Homie File Organizer uses AI to intelligently organize your files. Let\'s take a quick tour!',
            image: 'assets/tour/welcome.png',
          ),
          TourStep(
            title: 'Select Source Folder',
            content: 'Choose the folder you want to organize. This could be your Downloads, Desktop, or any messy folder.',
            image: 'assets/tour/source_folder.png',
            highlightWidget: 'source_folder_button',
          ),
          TourStep(
            title: 'Choose Organization Style',
            content: 'Pick how you want files organized. Smart Categories uses AI to create logical groupings.',
            image: 'assets/tour/organization_style.png',
            highlightWidget: 'organization_dropdown',
          ),
          TourStep(
            title: 'Review AI Suggestions',
            content: 'The AI will analyze your files and suggest where to move them. You can approve or modify each suggestion.',
            image: 'assets/tour/ai_suggestions.png',
            highlightWidget: 'operations_preview',
          ),
          TourStep(
            title: 'Execute Operations',
            content: 'Once you\'re happy with the suggestions, click Execute to organize your files!',
            image: 'assets/tour/execute.png',
            highlightWidget: 'execute_button',
          ),
          TourStep(
            title: 'You\'re All Set!',
            content: 'The AI learns from your choices and gets better over time. Happy organizing!',
            image: 'assets/tour/complete.png',
          ),
        ],
      ),
      'advanced_features': TourData(
        title: 'Advanced Features Tour',
        description: 'Discover powerful features for power users',
        steps: [
          TourStep(
            title: 'Batch Operations',
            content: 'Select multiple files and perform operations on all of them at once.',
            image: 'assets/tour/batch_operations.png',
            highlightWidget: 'batch_selector',
          ),
          TourStep(
            title: 'Advanced Search',
            content: 'Use powerful search filters to find exactly what you\'re looking for.',
            image: 'assets/tour/advanced_search.png',
            highlightWidget: 'search_button',
          ),
          TourStep(
            title: 'Export & Reporting',
            content: 'Generate reports of your organization activities in various formats.',
            image: 'assets/tour/export.png',
            highlightWidget: 'export_button',
          ),
          TourStep(
            title: 'Keyboard Shortcuts',
            content: 'Use keyboard shortcuts to work faster. Press Ctrl+? to see all shortcuts.',
            image: 'assets/tour/shortcuts.png',
          ),
        ],
      ),
    };
  }
}

class _HelpSystemState extends State<HelpSystem> {
  final GlobalKey _tooltipKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Help data structure
class HelpData {
  final String title;
  final String description;
  final List<HelpSection> sections;
  final List<String> shortcuts;
  final List<HelpVideo> videos;

  HelpData({
    required this.title,
    required this.description,
    required this.sections,
    this.shortcuts = const [],
    this.videos = const [],
  });
}

class HelpSection {
  final String title;
  final String content;

  HelpSection({
    required this.title,
    required this.content,
  });
}

class HelpVideo {
  final String title;
  final String url;
  final String duration;

  HelpVideo({
    required this.title,
    required this.url,
    required this.duration,
  });
}

/// Tour data structure
class TourData {
  final String title;
  final String description;
  final List<TourStep> steps;

  TourData({
    required this.title,
    required this.description,
    required this.steps,
  });
}

class TourStep {
  final String title;
  final String content;
  final String? image;
  final String? highlightWidget;

  TourStep({
    required this.title,
    required this.content,
    this.image,
    this.highlightWidget,
  });
}

/// Help dialog widget
class HelpDialog extends StatefulWidget {
  final HelpData helpData;

  const HelpDialog({Key? key, required this.helpData}) : super(key: key);

  @override
  State<HelpDialog> createState() => _HelpDialogState();
}

class _HelpDialogState extends State<HelpDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final tabCount = 1 + 
        (widget.helpData.shortcuts.isNotEmpty ? 1 : 0) +
        (widget.helpData.videos.isNotEmpty ? 1 : 0);
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Tab>[
      const Tab(text: 'Guide', icon: Icon(Icons.help_outline)),
    ];
    
    if (widget.helpData.shortcuts.isNotEmpty) {
      tabs.add(const Tab(text: 'Shortcuts', icon: Icon(Icons.keyboard)));
    }
    
    if (widget.helpData.videos.isNotEmpty) {
      tabs.add(const Tab(text: 'Videos', icon: Icon(Icons.play_circle_outline)));
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 500,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.help,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.helpData.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        Text(
                          widget.helpData.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              tabs: tabs,
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Guide tab
                  _buildGuideTab(),
                  
                  // Shortcuts tab
                  if (widget.helpData.shortcuts.isNotEmpty)
                    _buildShortcutsTab(),
                  
                  // Videos tab
                  if (widget.helpData.videos.isNotEmpty)
                    _buildVideosTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.helpData.sections.length,
      itemBuilder: (context, index) {
        final section = widget.helpData.sections[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  section.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShortcutsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.helpData.shortcuts.length,
      itemBuilder: (context, index) {
        final shortcut = widget.helpData.shortcuts[index];
        final parts = shortcut.split(': ');
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              parts[0],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(parts.length > 1 ? parts[1] : shortcut),
        );
      },
    );
  }

  Widget _buildVideosTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.helpData.videos.length,
      itemBuilder: (context, index) {
        final video = widget.helpData.videos[index];
        return ListTile(
          leading: const Icon(Icons.play_circle_filled),
          title: Text(video.title),
          subtitle: Text('Duration: ${video.duration}'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () {
            // In a real app, you'd open the video URL
            debugPrint('Opening video: ${video.url}');
          },
        );
      },
    );
  }
}

/// Guided tour screen
class GuidedTourScreen extends StatefulWidget {
  final TourData tour;

  const GuidedTourScreen({Key? key, required this.tour}) : super(key: key);

  @override
  State<GuidedTourScreen> createState() => _GuidedTourScreenState();
}

class _GuidedTourScreenState extends State<GuidedTourScreen> {
  int _currentStep = 0;
  PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tour.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / widget.tour.steps.length,
          ),
          
          // Tour content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.tour.steps.length,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              itemBuilder: (context, index) {
                final step = widget.tour.steps[index];
                return _buildTourStep(step);
              },
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _previousStep,
                    child: const Text('Previous'),
                  )
                else
                  const SizedBox.shrink(),
                
                Text('${_currentStep + 1} of ${widget.tour.steps.length}'),
                
                if (_currentStep < widget.tour.steps.length - 1)
                  ElevatedButton(
                    onPressed: _nextStep,
                    child: const Text('Next'),
                  )
                else
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Finish'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTourStep(TourStep step) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Image
          if (step.image != null)
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.image,
                  size: 100,
                  color: Colors.grey,
                ),
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Content
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Text(
                  step.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  step.content,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < widget.tour.steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}

/// Keyboard shortcuts dialog
class KeyboardShortcutsDialog extends StatelessWidget {
  const KeyboardShortcutsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shortcuts = _getAllKeyboardShortcuts();
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 600,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.keyboard,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Keyboard Shortcuts',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Shortcuts list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: shortcuts.length,
                itemBuilder: (context, index) {
                  final category = shortcuts.keys.elementAt(index);
                  final categoryShortcuts = shortcuts[category]!;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (index > 0) const SizedBox(height: 16),
                      Text(
                        category,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...categoryShortcuts.map((shortcut) {
                        final parts = shortcut.split(': ');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 120,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  parts[0],
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  parts.length > 1 ? parts[1] : shortcut,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<String>> _getAllKeyboardShortcuts() {
    return {
      'General': [
        'Ctrl+?: Show keyboard shortcuts',
        'Ctrl+H: Show help',
        'Ctrl+R: Refresh',
        'Escape: Cancel current action',
        'F1: Show feature help',
      ],
      'File Operations': [
        'Ctrl+O: Open folder browser',
        'Ctrl+N: New organization',
        'Ctrl+E: Execute operations',
        'Ctrl+Z: Undo last operation',
        'Delete: Delete selected files',
      ],
      'Selection': [
        'Ctrl+A: Select all files',
        'Ctrl+D: Deselect all',
        'Shift+Click: Select range',
        'Space: Toggle selection',
        'Ctrl+I: Invert selection',
      ],
      'Search': [
        'Ctrl+F: Quick search',
        'Ctrl+Shift+F: Advanced search',
        'F3: Find next',
        'Shift+F3: Find previous',
        'Escape: Clear search',
      ],
      'Export': [
        'Ctrl+E: Quick export',
        'Ctrl+Shift+E: Export options',
        'Ctrl+P: Print report',
      ],
      'Navigation': [
        'Tab: Next element',
        'Shift+Tab: Previous element',
        'Enter: Activate button',
        'Arrow keys: Navigate lists',
      ],
    };
  }
}

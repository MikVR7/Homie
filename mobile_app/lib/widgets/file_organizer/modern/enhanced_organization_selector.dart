import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homie_app/providers/file_organizer_provider.dart';
import 'package:homie_app/services/api_service.dart';

/// Enhanced organization style selector with descriptions, examples, and preset management
class EnhancedOrganizationSelector extends StatefulWidget {
  final String? sourcePath;
  final Function(OrganizationStyle)? onStyleChanged;
  final Function(String)? onCustomIntentChanged;
  final bool showAdvancedOptions;

  const EnhancedOrganizationSelector({
    Key? key,
    this.sourcePath,
    this.onStyleChanged,
    this.onCustomIntentChanged,
    this.showAdvancedOptions = true,
  }) : super(key: key);

  @override
  State<EnhancedOrganizationSelector> createState() => _EnhancedOrganizationSelectorState();
}

class _EnhancedOrganizationSelectorState extends State<EnhancedOrganizationSelector>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _customIntentController = TextEditingController();
  bool _showPresets = false;
  bool _isLoadingPresets = false;
  List<OrganizationPreset> _presets = [];
  List<OrganizationSuggestion> _suggestions = [];
  List<OrganizationHistory> _history = [];
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadInitialData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _customIntentController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadPresets(),
      _loadSuggestions(),
      _loadHistory(),
    ]);
  }

  Future<void> _loadPresets() async {
    if (!widget.showAdvancedOptions) return;
    
    setState(() => _isLoadingPresets = true);
    
    try {
      final apiService = ApiService();
      final result = await apiService.getOrganizationPresets(
        sourcePath: widget.sourcePath,
        limit: 10,
      );
      
      if (result['success'] == true) {
        setState(() {
          _presets = (result['presets'] as List)
              .map((p) => OrganizationPreset.fromJson(p))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Failed to load presets: $e');
    } finally {
      setState(() => _isLoadingPresets = false);
    }
  }

  Future<void> _loadSuggestions() async {
    if (widget.sourcePath == null) return;
    
    try {
      final apiService = ApiService();
      final result = await apiService.getPersonalizedSuggestions(
        sourcePath: widget.sourcePath!,
        limit: 5,
      );
      
      if (result['success'] == true) {
        setState(() {
          _suggestions = (result['suggestions'] as List)
              .map((s) => OrganizationSuggestion.fromJson(s))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Failed to load suggestions: $e');
    }
  }

  Future<void> _loadHistory() async {
    try {
      final apiService = ApiService();
      final response = await apiService.getOrganizationHistory(
        sourcePath: widget.sourcePath,
        limit: 10,
      );
      
      setState(() {
        _history = (response['history'] as List?)
            ?.map((item) => OrganizationHistory.fromJson(item))
            .toList() ?? [];
      });
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  void _onStyleChanged(OrganizationStyle style) {
    final provider = context.read<FileOrganizerProvider>();
    provider.setOrganizationStyle(style);
    widget.onStyleChanged?.call(style);
    
    // Clear custom intent when switching away from custom style
    if (style != OrganizationStyle.custom) {
      _customIntentController.clear();
      provider.setCustomIntent('');
      widget.onCustomIntentChanged?.call('');
    }
  }

  void _onCustomIntentChanged(String intent) {
    final provider = context.read<FileOrganizerProvider>();
    provider.setCustomIntent(intent);
    widget.onCustomIntentChanged?.call(intent);
  }

  Future<void> _applyPreset(OrganizationPreset preset) async {
    final provider = context.read<FileOrganizerProvider>();
    
    // Set the style
    _onStyleChanged(preset.style);
    
    // If custom, set the intent
    if (preset.style == OrganizationStyle.custom) {
      _customIntentController.text = preset.intent;
      _onCustomIntentChanged(preset.intent);
    }
    
    // Record usage
    try {
      final apiService = ApiService();
      await apiService.recordUserPreference(
        action: 'preset_applied',
        context: 'organization_selector',
        preference: {
          'preset_id': preset.id,
          'preset_name': preset.name,
          'style': preset.style.name,
          'source_path': widget.sourcePath,
        },
      );
    } catch (e) {
      debugPrint('Failed to record preset usage: $e');
    }
    
    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Applied preset: ${preset.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildStyleCard(OrganizationStyle style) {
    final provider = context.watch<FileOrganizerProvider>();
    final isSelected = provider.organizationStyle == style;
    final styleInfo = _getStyleInfo(style);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? Theme.of(context).primaryColor 
              : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected 
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.white,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onStyleChanged(style),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: styleInfo.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      styleInfo.icon,
                      color: styleInfo.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          styleInfo.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                                ? Theme.of(context).primaryColor 
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          styleInfo.subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                styleInfo.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (styleInfo.examples.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: styleInfo.examples.map((example) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: styleInfo.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: styleInfo.color.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      example,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: styleInfo.color.shade700,
                        fontSize: 11,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomIntentSection() {
    final provider = context.watch<FileOrganizerProvider>();
    final showCustom = provider.organizationStyle == OrganizationStyle.custom;
    
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: showCustom
          ? FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit, color: Colors.purple.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Custom Organization Intent',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customIntentController,
                      onChanged: _onCustomIntentChanged,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Describe how you want your files organized...\n\nExample: "Organize photos by year and event, documents by type and project"',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.purple.shade400),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    if (_suggestions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'AI Suggestions:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _suggestions.take(3).map((suggestion) => 
                          ActionChip(
                            label: Text(
                              suggestion.description,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () {
                              _customIntentController.text = suggestion.intent;
                              _onCustomIntentChanged(suggestion.intent);
                            },
                            backgroundColor: Colors.purple.shade100,
                            side: BorderSide(color: Colors.purple.shade300),
                          ),
                        ).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildPresetsSection() {
    if (!widget.showAdvancedOptions || _presets.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.bookmark, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            Text(
              'Saved Presets',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() => _showPresets = !_showPresets),
              icon: Icon(
                _showPresets ? Icons.expand_less : Icons.expand_more,
                color: Colors.blue.shade600,
              ),
              label: Text(
                _showPresets ? 'Hide' : 'Show',
                style: TextStyle(color: Colors.blue.shade600),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: _showPresets
              ? Column(
                  children: [
                    const SizedBox(height: 8),
                    ..._presets.map((preset) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: preset.style.color.withOpacity(0.1),
                            child: Icon(
                              preset.style.icon,
                              color: preset.style.color,
                              size: 16,
                            ),
                          ),
                          title: Text(preset.name),
                          subtitle: Text(
                            preset.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (preset.relevanceScore > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${(preset.relevanceScore * 100).round()}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _applyPreset(preset),
                                icon: const Icon(Icons.play_arrow),
                                tooltip: 'Apply preset',
                              ),
                            ],
                          ),
                          onTap: () => _applyPreset(preset),
                        ),
                      ),
                    )).toList(),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    if (!widget.showAdvancedOptions || _history.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: Icon(
          Icons.history,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Organization History'),
        subtitle: Text('${_history.length} recent patterns'),
        initiallyExpanded: _showHistory,
        onExpansionChanged: (expanded) {
          setState(() => _showHistory = expanded);
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reuse successful organization patterns from your history',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                ..._history.map((historyItem) => _buildHistoryItem(historyItem)),
                if (_history.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _clearHistory,
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Clear History'),
                      ),
                      TextButton.icon(
                        onPressed: _viewFullHistory,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('View Full History'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(OrganizationHistory historyItem) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: historyItem.style.color.shade100,
          child: Icon(
            historyItem.style.icon,
            color: historyItem.style.color.shade700,
            size: 20,
          ),
        ),
        title: Text(
          historyItem.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(historyItem.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _formatDate(historyItem.lastUsed),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.folder, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${historyItem.filesOrganized} files',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _applyHistoryItem(historyItem),
              icon: const Icon(Icons.replay),
              tooltip: 'Apply This Pattern',
            ),
            IconButton(
              onPressed: () => _saveHistoryAsPreset(historyItem),
              icon: const Icon(Icons.bookmark_add),
              tooltip: 'Save as Preset',
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }

  Future<void> _applyHistoryItem(OrganizationHistory historyItem) async {
    // Apply the organization pattern from history
    _onStyleChanged(historyItem.style);
    
    if (historyItem.style == OrganizationStyle.custom) {
      _customIntentController.text = historyItem.customIntent ?? '';
      _onCustomIntentChanged(historyItem.customIntent ?? '');
    }

    // Record usage
    try {
      final apiService = ApiService();
      await apiService.recordUserPreference(
        action: 'history_applied',
        context: 'organization_selector',
        preference: {
          'history_id': historyItem.id,
          'style': historyItem.style.name,
          'source_path': widget.sourcePath,
        },
      );
    } catch (e) {
      debugPrint('Failed to record history usage: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Applied pattern: ${historyItem.name}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _saveHistoryAsPreset(OrganizationHistory historyItem) async {
    try {
      final apiService = ApiService();
      await apiService.saveOrganizationPreset(
        name: '${historyItem.name} (from history)',
        preset: {
          'style': historyItem.style,
          'intent': historyItem.customIntent ?? '',
          'sourcePath': widget.sourcePath,
        },
        description: 'Converted from organization history',
      );

      await _loadPresets(); // Refresh presets

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('History pattern saved as preset'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preset: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearHistory() async {
    try {
      final apiService = ApiService();
      await apiService.clearOrganizationHistory();
      await _loadHistory(); // Refresh history

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Organization history cleared'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewFullHistory() async {
    // Navigate to full history view or show dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Organization History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _history.length,
            itemBuilder: (context, index) {
              return _buildHistoryItem(_history[index]);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            'Organization Style',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how you want your files organized',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Organization style cards
          ...OrganizationStyle.values.map((style) => _buildStyleCard(style)),
          
          // Custom intent section
          _buildCustomIntentSection(),
          
          // Presets section
          _buildPresetsSection(),
          
          // History section
          _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  OrganizationStyleInfo _getStyleInfo(OrganizationStyle style) {
    switch (style) {
      case OrganizationStyle.smartCategories:
        return OrganizationStyleInfo(
          title: 'Smart Categories',
          subtitle: 'AI-powered intelligent categorization',
          description: 'Uses AI to automatically categorize files based on content, type, and context. Creates smart folder structures that make sense.',
          icon: Icons.psychology,
          color: Colors.blue,
          examples: ['Documents', 'Images', 'Projects', 'Work Files'],
        );
      case OrganizationStyle.byType:
        return OrganizationStyleInfo(
          title: 'By File Type',
          subtitle: 'Organize by file extensions',
          description: 'Groups files by their type into standard folders like Documents, Images, Videos, Music, and Archives.',
          icon: Icons.category,
          color: Colors.green,
          examples: ['PDF Files', 'Images', 'Videos', 'Audio'],
        );
      case OrganizationStyle.byDate:
        return OrganizationStyleInfo(
          title: 'By Date',
          subtitle: 'Organize chronologically',
          description: 'Creates folder structures based on file creation or modification dates, typically in Year/Month format.',
          icon: Icons.calendar_today,
          color: Colors.orange,
          examples: ['2024/01', '2024/02', '2023/12'],
        );
      case OrganizationStyle.custom:
        return OrganizationStyleInfo(
          title: 'Custom Intent',
          subtitle: 'Describe your own organization',
          description: 'Provide specific instructions for how you want your files organized. The AI will follow your custom intent.',
          icon: Icons.edit,
          color: Colors.purple,
          examples: ['Custom rules', 'Personal preferences', 'Specific workflows'],
        );
    }
  }
}

/// Information about an organization style
class OrganizationStyleInfo {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final MaterialColor color;
  final List<String> examples;

  const OrganizationStyleInfo({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.examples,
  });
}

/// Organization preset model
class OrganizationPreset {
  final String id;
  final String name;
  final String description;
  final String intent;
  final OrganizationStyle style;
  final double relevanceScore;
  final bool isCustom;
  final DateTime createdAt;
  final int usageCount;

  const OrganizationPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.intent,
    required this.style,
    required this.relevanceScore,
    required this.isCustom,
    required this.createdAt,
    required this.usageCount,
  });

  factory OrganizationPreset.fromJson(Map<String, dynamic> json) {
    return OrganizationPreset(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      intent: json['intent'] ?? '',
      style: OrganizationStyle.values.firstWhere(
        (s) => s.name == json['style'],
        orElse: () => OrganizationStyle.smartCategories,
      ),
      relevanceScore: (json['relevance_score'] ?? 0.0).toDouble(),
      isCustom: json['is_custom'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      usageCount: json['usage_count'] ?? 0,
    );
  }
}

/// Organization suggestion model
class OrganizationSuggestion {
  final String id;
  final String description;
  final String intent;
  final double confidence;

  const OrganizationSuggestion({
    required this.id,
    required this.description,
    required this.intent,
    required this.confidence,
  });

  factory OrganizationSuggestion.fromJson(Map<String, dynamic> json) {
    return OrganizationSuggestion(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      intent: json['intent'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }
}

/// Organization history item with usage metadata
class OrganizationHistory {
  final String id;
  final String name;
  final String description;
  final OrganizationStyle style;
  final String? customIntent;
  final DateTime lastUsed;
  final int filesOrganized;
  final String sourcePath;

  const OrganizationHistory({
    required this.id,
    required this.name,
    required this.description,
    required this.style,
    this.customIntent,
    required this.lastUsed,
    required this.filesOrganized,
    required this.sourcePath,
  });

  factory OrganizationHistory.fromJson(Map<String, dynamic> json) {
    return OrganizationHistory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      style: OrganizationStyle.values.firstWhere(
        (style) => style.name == json['style'],
        orElse: () => OrganizationStyle.smartCategories,
      ),
      customIntent: json['custom_intent'],
      lastUsed: DateTime.tryParse(json['last_used'] ?? '') ?? DateTime.now(),
      filesOrganized: json['files_organized'] ?? 0,
      sourcePath: json['source_path'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'style': style.name,
      'custom_intent': customIntent,
      'last_used': lastUsed.toIso8601String(),
      'files_organized': filesOrganized,
      'source_path': sourcePath,
    };
  }
}

/// Extension to add visual properties to OrganizationStyle
extension OrganizationStyleExtension on OrganizationStyle {
  IconData get icon {
    switch (this) {
      case OrganizationStyle.smartCategories:
        return Icons.psychology;
      case OrganizationStyle.byType:
        return Icons.category;
      case OrganizationStyle.byDate:
        return Icons.calendar_today;
      case OrganizationStyle.custom:
        return Icons.edit;
    }
  }

  MaterialColor get color {
    switch (this) {
      case OrganizationStyle.smartCategories:
        return Colors.blue;
      case OrganizationStyle.byType:
        return Colors.green;
      case OrganizationStyle.byDate:
        return Colors.orange;
      case OrganizationStyle.custom:
        return Colors.purple;
    }
  }
}

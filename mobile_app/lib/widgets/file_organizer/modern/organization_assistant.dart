import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homie_app/providers/file_organizer_provider.dart';
import 'package:homie_app/services/api_service.dart';

/// Intelligent organization assistant that provides smart suggestions,
/// custom intent building, and personalized organization patterns
class OrganizationAssistant extends StatefulWidget {
  final String? sourcePath;
  final String? destinationPath;
  final VoidCallback? onOrganizationComplete;
  final bool showAdvancedOptions;

  const OrganizationAssistant({
    Key? key,
    this.sourcePath,
    this.destinationPath,
    this.onOrganizationComplete,
    this.showAdvancedOptions = false,
  }) : super(key: key);

  @override
  State<OrganizationAssistant> createState() => _OrganizationAssistantState();
}

class _OrganizationAssistantState extends State<OrganizationAssistant>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _customIntentController = TextEditingController();
  final TextEditingController _presetNameController = TextEditingController();
  
  bool _isAnalyzing = false;
  bool _showExamples = false;
  List<Map<String, dynamic>> _smartSuggestions = [];
  List<Map<String, dynamic>> _historicalPatterns = [];
  List<Map<String, dynamic>> _savedRules = [];
  String? _selectedPreset;
  String? _analysisResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customIntentController.dispose();
    _presetNameController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadSmartSuggestions(),
      _loadHistoricalPatterns(),
      _loadSavedRules(),
    ]);
  }

  Future<void> _loadSmartSuggestions() async {
    if (widget.sourcePath == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final apiService = ApiService();
      final provider = context.read<FileOrganizerProvider>();
      
      // Analyze folder content for smart suggestions
      final result = await apiService.analyzeWithPreview(
        sourcePath: widget.sourcePath!,
        destinationPath: widget.destinationPath ?? '/home/user/Organized',
        includePreview: true,
      );

      if (result['success'] == true) {
        setState(() {
          _smartSuggestions = List<Map<String, dynamic>>.from(
            result['smart_suggestions'] ?? []
          );
          _analysisResult = result['analysis_summary'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load suggestions: $e')),
      );
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _loadHistoricalPatterns() async {
    try {
      final apiService = ApiService();
      final preferences = await apiService.getUserPreferences(
        context: 'file_organization',
        limit: 20,
      );

      if (preferences['success'] == true) {
        setState(() {
          _historicalPatterns = List<Map<String, dynamic>>.from(
            preferences['patterns'] ?? []
          );
        });
      }
    } catch (e) {
      debugPrint('Failed to load historical patterns: $e');
    }
  }

  Future<void> _loadSavedRules() async {
    try {
      final provider = context.read<FileOrganizerProvider>();
      // In a real implementation, this would load from the provider or API
      setState(() {
        _savedRules = [
          {
            'id': '1',
            'name': 'Documents by Type',
            'intent': 'organize files by type (documents, images, videos)',
            'style': 'by_type',
            'usage_count': 15,
            'success_rate': 0.92,
          },
          {
            'id': '2',
            'name': 'Date-based Organization',
            'intent': 'organize files by date (year/month folders)',
            'style': 'by_date',
            'usage_count': 8,
            'success_rate': 0.85,
          },
          {
            'id': '3',
            'name': 'Project-based Sorting',
            'intent': 'organize files by project and category',
            'style': 'smart_categories',
            'usage_count': 12,
            'success_rate': 0.89,
          },
        ];
      });
    } catch (e) {
      debugPrint('Failed to load saved rules: $e');
    }
  }

  Future<void> _applyPreset(Map<String, dynamic> preset) async {
    final provider = context.read<FileOrganizerProvider>();
    
    provider.setOrganizationStyle(
      OrganizationStyle.values.firstWhere(
        (style) => style.toString().split('.').last == preset['style'],
        orElse: () => OrganizationStyle.smartCategories,
      ),
    );
    
    provider.setCustomIntent(preset['intent']);
    
    setState(() {
      _selectedPreset = preset['id'];
      _customIntentController.text = preset['intent'];
    });

    // Record usage for learning
    await _recordPresetUsage(preset);
  }

  Future<void> _recordPresetUsage(Map<String, dynamic> preset) async {
    try {
      final apiService = ApiService();
      await apiService.recordUserPreference(
        action: 'preset_applied',
        context: 'organization_assistant',
        preference: {
          'preset_id': preset['id'],
          'preset_name': preset['name'],
          'style': preset['style'],
          'intent': preset['intent'],
          'source_path': widget.sourcePath,
        },
      );
    } catch (e) {
      debugPrint('Failed to record preset usage: $e');
    }
  }

  Future<void> _saveCustomRule() async {
    if (_customIntentController.text.isEmpty || _presetNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide both name and intent')),
      );
      return;
    }

    try {
      final provider = context.read<FileOrganizerProvider>();
      final newRule = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _presetNameController.text,
        'intent': _customIntentController.text,
        'style': provider.organizationStyle.toString().split('.').last,
        'usage_count': 0,
        'success_rate': 0.0,
        'created_at': DateTime.now().toIso8601String(),
      };

      setState(() {
        _savedRules.insert(0, newRule);
      });

      // Record the new rule
      final apiService = ApiService();
      await apiService.recordUserPreference(
        action: 'rule_created',
        context: 'organization_assistant',
        preference: newRule,
      );

      _presetNameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rule saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save rule: $e')),
      );
    }
  }

  Future<void> _deleteRule(Map<String, dynamic> rule) async {
    setState(() {
      _savedRules.removeWhere((r) => r['id'] == rule['id']);
    });

    try {
      final apiService = ApiService();
      await apiService.recordUserPreference(
        action: 'rule_deleted',
        context: 'organization_assistant',
        preference: {'rule_id': rule['id']},
      );
    } catch (e) {
      debugPrint('Failed to record rule deletion: $e');
    }
  }

  Widget _buildSmartSuggestionsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Smart Suggestions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isAnalyzing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_analysisResult != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Folder Analysis',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_analysisResult!),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Expanded(
            child: _smartSuggestions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a folder to see smart suggestions',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _smartSuggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _smartSuggestions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade100,
                            child: Text(
                              '${(suggestion['confidence'] * 100).round()}%',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(suggestion['title'] ?? 'Suggestion'),
                          subtitle: Text(suggestion['description'] ?? ''),
                          trailing: ElevatedButton(
                            onPressed: () => _applyPreset(suggestion),
                            child: const Text('Apply'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomIntentTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit, color: Colors.purple),
              const SizedBox(width: 8),
              Text(
                'Custom Intent Builder',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _showExamples ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _showExamples = !_showExamples),
                tooltip: _showExamples ? 'Hide Examples' : 'Show Examples',
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _customIntentController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Organization Intent',
              hintText: 'Describe how you want your files organized...',
              border: OutlineInputBorder(),
              helperText: 'Be specific about how files should be categorized',
            ),
          ),
          const SizedBox(height: 16),

          if (_showExamples) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Examples:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._buildExamplesList(),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _presetNameController,
                  decoration: const InputDecoration(
                    labelText: 'Rule Name (optional)',
                    hintText: 'Save this intent as a preset',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _saveCustomRule,
                icon: const Icon(Icons.save),
                label: const Text('Save Rule'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _customIntentController.text.isNotEmpty
                  ? () => _applyCustomIntent()
                  : null,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Apply Custom Intent'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExamplesList() {
    final examples = [
      'Organize files by type (images in Pictures, documents in Documents)',
      'Sort by date with year/month folders (2024/01, 2024/02)',
      'Group by project: work files in Work folder, personal in Personal',
      'Organize photos by event and date',
      'Sort documents by category and importance',
    ];

    return examples.map((example) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _customIntentController.text = example,
              child: Text(
                example,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }

  Future<void> _applyCustomIntent() async {
    final provider = context.read<FileOrganizerProvider>();
    provider.setCustomIntent(_customIntentController.text);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Custom intent applied!')),
    );

    // Record usage for learning
    try {
      final apiService = ApiService();
      await apiService.recordUserPreference(
        action: 'custom_intent_applied',
        context: 'organization_assistant',
        preference: {
          'intent': _customIntentController.text,
          'source_path': widget.sourcePath,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Failed to record custom intent usage: $e');
    }
  }

  Widget _buildHistoricalPatternsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Historical Patterns',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _historicalPatterns.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timeline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No historical patterns found',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start organizing files to see your patterns',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _historicalPatterns.length,
                    itemBuilder: (context, index) {
                      final pattern = _historicalPatterns[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Text(
                              '${pattern['frequency'] ?? 0}x',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(pattern['pattern'] ?? 'Pattern'),
                          subtitle: Text(
                            'Success rate: ${((pattern['success_rate'] ?? 0) * 100).round()}%',
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _applyPreset(pattern),
                            child: const Text('Use'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedRulesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rule, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Saved Rules',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _savedRules.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rule_folder,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No saved rules',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create custom rules in the Intent Builder',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _savedRules.length,
                    itemBuilder: (context, index) {
                      final rule = _savedRules[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              '${((rule['success_rate'] ?? 0) * 100).round()}%',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(rule['name'] ?? 'Rule'),
                          subtitle: Text(
                            'Used ${rule['usage_count'] ?? 0} times',
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Intent:',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(rule['intent'] ?? ''),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _applyPreset(rule),
                                        icon: const Icon(Icons.play_arrow),
                                        label: const Text('Apply'),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () => _editRule(rule),
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Edit'),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () => _deleteRule(rule),
                                        icon: const Icon(Icons.delete),
                                        label: const Text('Delete'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _editRule(Map<String, dynamic> rule) {
    _presetNameController.text = rule['name'] ?? '';
    _customIntentController.text = rule['intent'] ?? '';
    _tabController.animateTo(1); // Switch to Custom Intent tab
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Organization Assistant',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Text(
                        'AI-powered organization suggestions and custom rules',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.lightbulb), text: 'Suggestions'),
              Tab(icon: Icon(Icons.edit), text: 'Custom'),
              Tab(icon: Icon(Icons.history), text: 'Patterns'),
              Tab(icon: Icon(Icons.rule), text: 'Rules'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSmartSuggestionsTab(),
                _buildCustomIntentTab(),
                _buildHistoricalPatternsTab(),
                _buildSavedRulesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

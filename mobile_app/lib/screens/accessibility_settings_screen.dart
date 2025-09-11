import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accessibility_provider.dart';
import '../widgets/accessibility/accessible_button.dart';
import '../widgets/accessibility/screen_reader_announcer.dart';

/// Screen for managing accessibility settings
class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({Key? key}) : super(key: key);

  @override
  State<AccessibilitySettingsScreen> createState() => _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState extends State<AccessibilitySettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityProvider>(
      builder: (context, accessibilityProvider, child) {
        final colorScheme = accessibilityProvider.getColorScheme(context);
        final textTheme = accessibilityProvider.getTextTheme(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Accessibility Settings',
              style: textTheme.headlineSmall,
              semanticsLabel: 'Accessibility settings page',
            ),
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            leading: AccessibleIconButton(
              icon: Icons.arrow_back,
              semanticLabel: 'Go back',
              semanticHint: 'Return to previous screen',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: ScreenReaderAnnouncer(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visual Accessibility Section
                  _buildSectionHeader(
                    'Visual Accessibility',
                    'Settings for better visibility and readability',
                    textTheme,
                  ),
                  const SizedBox(height: 16),
                  _buildVisualSettings(accessibilityProvider, colorScheme, textTheme),
                  
                  const SizedBox(height: 32),
                  
                  // Interaction Accessibility Section
                  _buildSectionHeader(
                    'Interaction',
                    'Settings for keyboard and touch interactions',
                    textTheme,
                  ),
                  const SizedBox(height: 16),
                  _buildInteractionSettings(accessibilityProvider, colorScheme, textTheme),
                  
                  const SizedBox(height: 32),
                  
                  // Screen Reader Section
                  _buildSectionHeader(
                    'Screen Reader',
                    'Settings for voice announcements and descriptions',
                    textTheme,
                  ),
                  const SizedBox(height: 16),
                  _buildScreenReaderSettings(accessibilityProvider, colorScheme, textTheme),
                  
                  const SizedBox(height: 32),
                  
                  // Reset Section
                  _buildSectionHeader(
                    'Reset',
                    'Restore default accessibility settings',
                    textTheme,
                  ),
                  const SizedBox(height: 16),
                  _buildResetSection(accessibilityProvider, colorScheme, textTheme),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, String description, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          semanticsLabel: '$title section',
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
          semanticsLabel: description,
        ),
      ],
    );
  }

  Widget _buildVisualSettings(
    AccessibilityProvider provider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      color: colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // High Contrast Toggle
            SwitchListTile(
              title: Text(
                'High Contrast Mode',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'Increases color contrast for better visibility',
                style: textTheme.bodySmall,
              ),
              value: provider.highContrastMode,
              onChanged: (value) {
                provider.toggleHighContrast();
              },
              secondary: Icon(
                Icons.contrast,
                color: colorScheme.primary,
                semanticLabel: 'High contrast icon',
              ),
              semanticLabel: 'High contrast mode toggle',
            ),
            
            const Divider(),
            
            // Text Size Slider
            ListTile(
              leading: Icon(
                Icons.text_fields,
                color: colorScheme.primary,
                semanticLabel: 'Text size icon',
              ),
              title: Text(
                'Text Size',
                style: textTheme.titleMedium,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adjust text size for better readability',
                    style: textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: 'Text size slider',
                    hint: 'Drag to adjust text size from 80% to 200%',
                    value: '${(provider.textScale * 100).round()}%',
                    child: Slider(
                      value: provider.textScale,
                      min: 0.8,
                      max: 2.0,
                      divisions: 12,
                      label: '${(provider.textScale * 100).round()}%',
                      onChanged: (value) {
                        provider.setTextScale(value);
                      },
                    ),
                  ),
                  Text(
                    'Current: ${(provider.textScale * 100).round()}%',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // Reduce Motion Toggle
            SwitchListTile(
              title: Text(
                'Reduce Motion',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'Minimizes animations and transitions',
                style: textTheme.bodySmall,
              ),
              value: provider.reduceMotion,
              onChanged: (value) {
                provider.toggleReduceMotion();
              },
              secondary: Icon(
                Icons.motion_photos_off,
                color: colorScheme.primary,
                semanticLabel: 'Reduce motion icon',
              ),
              semanticLabel: 'Reduce motion toggle',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionSettings(
    AccessibilityProvider provider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      color: colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Large Buttons Toggle
            SwitchListTile(
              title: Text(
                'Large Buttons',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'Increases button size for easier interaction',
                style: textTheme.bodySmall,
              ),
              value: provider.largeButtons,
              onChanged: (value) {
                provider.toggleLargeButtons();
              },
              secondary: Icon(
                Icons.touch_app,
                color: colorScheme.primary,
                semanticLabel: 'Large buttons icon',
              ),
              semanticLabel: 'Large buttons toggle',
            ),
            
            const Divider(),
            
            // Keyboard Navigation Toggle
            SwitchListTile(
              title: Text(
                'Keyboard Navigation',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'Enable keyboard shortcuts and focus management',
                style: textTheme.bodySmall,
              ),
              value: provider.keyboardNavigationEnabled,
              onChanged: (value) {
                provider.toggleKeyboardNavigation();
              },
              secondary: Icon(
                Icons.keyboard,
                color: colorScheme.primary,
                semanticLabel: 'Keyboard navigation icon',
              ),
              semanticLabel: 'Keyboard navigation toggle',
            ),
            
            const Divider(),
            
            // Keyboard Shortcuts Help
            ListTile(
              leading: Icon(
                Icons.help_outline,
                color: colorScheme.primary,
                semanticLabel: 'Help icon',
              ),
              title: Text(
                'Keyboard Shortcuts',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'View all available keyboard shortcuts',
                style: textTheme.bodySmall,
              ),
              trailing: Icon(
                Icons.chevron_right,
                semanticLabel: 'Open shortcuts help',
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const KeyboardShortcutsDialog(),
                );
              },
              semanticLabel: 'View keyboard shortcuts help',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenReaderSettings(
    AccessibilityProvider provider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      color: colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // State Announcements Toggle
            SwitchListTile(
              title: Text(
                'State Announcements',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'Announce changes like progress and errors',
                style: textTheme.bodySmall,
              ),
              value: provider.announceStateChanges,
              onChanged: (value) {
                provider.toggleStateAnnouncements();
              },
              secondary: Icon(
                Icons.record_voice_over,
                color: colorScheme.primary,
                semanticLabel: 'Voice announcements icon',
              ),
              semanticLabel: 'State announcements toggle',
            ),
            
            const Divider(),
            
            // Verbose Descriptions Toggle
            SwitchListTile(
              title: Text(
                'Verbose Descriptions',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'Provide detailed descriptions of visual elements',
                style: textTheme.bodySmall,
              ),
              value: provider.verboseDescriptions,
              onChanged: (value) {
                provider.toggleVerboseDescriptions();
              },
              secondary: Icon(
                Icons.description,
                color: colorScheme.primary,
                semanticLabel: 'Verbose descriptions icon',
              ),
              semanticLabel: 'Verbose descriptions toggle',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetSection(
    AccessibilityProvider provider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      color: colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                Icons.restore,
                color: colorScheme.error,
                semanticLabel: 'Reset icon',
              ),
              title: Text(
                'Reset to Defaults',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'Restore all accessibility settings to their default values',
                style: textTheme.bodySmall,
              ),
              semanticLabel: 'Reset accessibility settings to defaults',
            ),
            const SizedBox(height: 16),
            AccessibleButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => _buildResetConfirmationDialog(
                    provider,
                    colorScheme,
                    textTheme,
                  ),
                );
              },
              isDestructive: true,
              semanticLabel: 'Reset all accessibility settings',
              semanticHint: 'Opens confirmation dialog before resetting',
              child: Text('Reset All Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetConfirmationDialog(
    AccessibilityProvider provider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return AlertDialog(
      title: Text(
        'Reset Accessibility Settings',
        style: textTheme.headlineSmall,
      ),
      content: Text(
        'Are you sure you want to reset all accessibility settings to their default values? This action cannot be undone.',
        style: textTheme.bodyMedium,
      ),
      actions: [
        AccessibleButton(
          onPressed: () => Navigator.of(context).pop(),
          semanticLabel: 'Cancel reset',
          child: Text('Cancel'),
        ),
        AccessibleButton(
          onPressed: () {
            provider.resetToDefaults();
            Navigator.of(context).pop();
            provider.announceSuccess('Accessibility settings reset to defaults');
          },
          isDestructive: true,
          semanticLabel: 'Confirm reset all settings',
          child: Text('Reset'),
        ),
      ],
      semanticLabel: 'Reset confirmation dialog',
    );
  }
}

/// Widget for quick accessibility toggle in app bar
class AccessibilityQuickToggle extends StatelessWidget {
  const AccessibilityQuickToggle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityProvider>(
      builder: (context, provider, child) {
        return PopupMenuButton<String>(
          icon: Icon(
            Icons.accessibility,
            semanticLabel: 'Accessibility quick settings',
          ),
          onSelected: (value) {
            switch (value) {
              case 'high_contrast':
                provider.toggleHighContrast();
                break;
              case 'large_buttons':
                provider.toggleLargeButtons();
                break;
              case 'reduce_motion':
                provider.toggleReduceMotion();
                break;
              case 'settings':
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AccessibilitySettingsScreen(),
                  ),
                );
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'high_contrast',
              child: ListTile(
                leading: Icon(
                  provider.highContrastMode ? Icons.check_box : Icons.check_box_outline_blank,
                  semanticLabel: provider.highContrastMode ? 'Enabled' : 'Disabled',
                ),
                title: Text('High Contrast'),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'large_buttons',
              child: ListTile(
                leading: Icon(
                  provider.largeButtons ? Icons.check_box : Icons.check_box_outline_blank,
                  semanticLabel: provider.largeButtons ? 'Enabled' : 'Disabled',
                ),
                title: Text('Large Buttons'),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'reduce_motion',
              child: ListTile(
                leading: Icon(
                  provider.reduceMotion ? Icons.check_box : Icons.check_box_outline_blank,
                  semanticLabel: provider.reduceMotion ? 'Enabled' : 'Disabled',
                ),
                title: Text('Reduce Motion'),
                dense: true,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('All Settings'),
                dense: true,
              ),
            ),
          ],
          semanticLabel: 'Accessibility menu',
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../services/content_moderation_service.dart';

class ContentSettingsScreen extends StatefulWidget {
  const ContentSettingsScreen({super.key});

  @override
  State<ContentSettingsScreen> createState() => _ContentSettingsScreenState();
}

class _ContentSettingsScreenState extends State<ContentSettingsScreen> {
  final ContentModerationService _moderationService = ContentModerationService();
  final String _currentUserId = 'user-1';
  
  bool _showRestrictedContent = false;
  int _userAge = 18; // Default age

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  void _loadUserSettings() {
    // In real app, load from user preferences
    setState(() {
      _userAge = 18;
      _showRestrictedContent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strikeRecord = _moderationService.getUserStrikes(_currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (strikeRecord != null && strikeRecord.policyStrikes > 0) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: strikeRecord.policyStrikes >= 3
                                ? Colors.red
                                : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Policy Violations: ${strikeRecord.policyStrikes}',
                              style: TextStyle(
                                color: strikeRecord.policyStrikes >= 3
                                    ? Colors.red
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (strikeRecord.isSuspended)
                        const Text(
                          'Your account is suspended due to policy violations.',
                          style: TextStyle(color: Colors.red),
                        )
                      else if (strikeRecord.isRestricted)
                        const Text(
                          'Your posting is restricted due to policy violations.',
                          style: TextStyle(color: Colors.orange),
                        )
                      else
                        Text(
                          '${3 - strikeRecord.policyStrikes} strikes remaining before restrictions.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                    ] else
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'No policy violations',
                            style: TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Content Preferences
            const Text(
              'Content Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Age Setting
            Card(
              child: ListTile(
                title: const Text('Your Age'),
                subtitle: Text('$_userAge years old'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Set Your Age'),
                      content: StatefulBuilder(
                        builder: (context, setState) {
                          int tempAge = _userAge;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Age: $tempAge'),
                              Slider(
                                value: tempAge.toDouble(),
                                min: 13,
                                max: 100,
                                divisions: 87,
                                label: '$tempAge',
                                onChanged: (value) {
                                  setState(() {
                                    tempAge = value.toInt();
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _userAge = 18; // Would update from dialog
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Show Restricted Content
            Card(
              child: SwitchListTile(
                title: const Text('Show Restricted Content'),
                subtitle: const Text(
                  'Allow sexualized content (18+ only)',
                  style: TextStyle(fontSize: 12),
                ),
                value: _showRestrictedContent,
                onChanged: (value) {
                  if (_userAge < 18) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You must be 18+ to view restricted content'),
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _showRestrictedContent = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 24),

            // Content Policy
            Card(
              child: ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Content Policy'),
                subtitle: const Text('View our community guidelines'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Content Policy'),
                      content: const SingleChildScrollView(
                        child: Text(
                          'Our content policy prohibits:\n\n'
                          '• Explicit sexual activity\n'
                          '• Nudity\n'
                          '• Pornographic material\n'
                          '• Sexualized content (restricted)\n\n'
                          'Sponsored content must be completely free of sexual or suggestive elements.\n\n'
                          'Violations may result in content removal, account restrictions, or suspension.',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Appeal Policy Violation
            if (strikeRecord != null && strikeRecord.policyStrikes > 0)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.gavel),
                  title: const Text('Appeal Policy Violation'),
                  subtitle: const Text('Request review of a violation'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Appeal submitted. We will review your case.'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

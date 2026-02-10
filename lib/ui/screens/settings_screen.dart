import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:picell/ui/widgets/animated_background.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  // App Preferences
  bool _darkMode = true;
  bool _autoSave = false;
  bool _showGrid = true;
  bool _showPixelInfo = true;

  // Quality Settings
  double _renderQuality = 1.0;
  bool _highQualityExport = true;
  bool _antiAliasing = false;

  // Animation Settings
  bool _autoPlayAnimations = true;
  double _animationSpeed = 1.0;
  bool _loopAnimations = true;

  // Export Settings
  String _defaultExportFormat = 'PNG';
  bool _includeTransparency = true;
  double _exportScale = 1.0;

  // Notifications
  bool _enableNotifications = true;
  bool _exportCompleteNotification = true;
  bool _tipsAndTricks = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Appearance Section
            _buildSection(
              'Appearance',
              Icons.palette_outlined,
              [
                _buildSwitchTile(
                  'Dark Mode',
                  'Use dark theme throughout the app',
                  _darkMode,
                  (value) => setState(() => _darkMode = value),
                  MaterialCommunityIcons.moon_full,
                ),
                _buildSwitchTile(
                  'Show Grid',
                  'Display pixel grid overlay',
                  _showGrid,
                  (value) => setState(() => _showGrid = value),
                  MaterialIcons.grid_on,
                ),
                _buildSwitchTile(
                  'Show Pixel Info',
                  'Display pixel coordinates and color',
                  _showPixelInfo,
                  (value) => setState(() => _showPixelInfo = value),
                  MaterialIcons.info_outline,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Performance Section
            _buildSection(
              'Performance',
              Icons.speed,
              [
                _buildSliderTile(
                  'Render Quality',
                  'Adjust rendering quality (higher = better quality)',
                  _renderQuality,
                  0.5,
                  2.0,
                  (value) => setState(() => _renderQuality = value),
                  MaterialIcons.high_quality,
                  divisions: 6,
                  valueLabel: '${(_renderQuality * 100).round()}%',
                ),
                _buildSwitchTile(
                  'High Quality Export',
                  'Use maximum quality for exported images',
                  _highQualityExport,
                  (value) => setState(() => _highQualityExport = value),
                  MaterialIcons.hd,
                ),
                _buildSwitchTile(
                  'Anti-aliasing',
                  'Smooth edges (may reduce pixel art sharpness)',
                  _antiAliasing,
                  (value) => setState(() => _antiAliasing = value),
                  MaterialIcons.blur_on,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Animation Section
            _buildSection(
              'Animations',
              Icons.animation,
              [
                _buildSwitchTile(
                  'Auto-play Animations',
                  'Automatically play effect animations',
                  _autoPlayAnimations,
                  (value) => setState(() => _autoPlayAnimations = value),
                  MaterialIcons.play_circle_outline,
                ),
                _buildSliderTile(
                  'Animation Speed',
                  'Control playback speed of animations',
                  _animationSpeed,
                  0.25,
                  2.0,
                  (value) => setState(() => _animationSpeed = value),
                  Feather.zap,
                  divisions: 7,
                  valueLabel: '${_animationSpeed.toStringAsFixed(2)}x',
                ),
                _buildSwitchTile(
                  'Loop Animations',
                  'Continuously repeat animations',
                  _loopAnimations,
                  (value) => setState(() => _loopAnimations = value),
                  MaterialIcons.loop,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Export Section
            _buildSection(
              'Export Settings',
              Icons.file_download_outlined,
              [
                _buildDropdownTile(
                  'Default Format',
                  'Choose default export file format',
                  _defaultExportFormat,
                  ['PNG', 'JPEG', 'GIF', 'WEBP'],
                  (value) => setState(() => _defaultExportFormat = value!),
                  MaterialIcons.image,
                ),
                _buildSliderTile(
                  'Export Scale',
                  'Scale multiplier for exported images',
                  _exportScale,
                  1.0,
                  4.0,
                  (value) => setState(() => _exportScale = value),
                  MaterialIcons.zoom_in,
                  divisions: 6,
                  valueLabel: '${_exportScale.toStringAsFixed(1)}x',
                ),
                _buildSwitchTile(
                  'Include Transparency',
                  'Preserve transparent pixels in exports',
                  _includeTransparency,
                  (value) => setState(() => _includeTransparency = value),
                  MaterialIcons.opacity,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Storage Section
            _buildSection(
              'Storage & Saving',
              Icons.save_outlined,
              [
                _buildSwitchTile(
                  'Auto-save',
                  'Automatically save your work',
                  _autoSave,
                  (value) => setState(() => _autoSave = value),
                  MaterialIcons.save,
                ),
                _buildActionTile(
                  'Clear Cache',
                  'Free up space by clearing cached data',
                  MaterialIcons.delete_outline,
                  () => _showClearCacheDialog(),
                ),
                _buildActionTile(
                  'Manage Saved Projects',
                  'View and organize your saved projects',
                  MaterialIcons.folder_open,
                  () => _navigateToProjects(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Notifications Section
            _buildSection(
              'Notifications',
              Icons.notifications_outlined,
              [
                _buildSwitchTile(
                  'Enable Notifications',
                  'Receive app notifications',
                  _enableNotifications,
                  (value) => setState(() => _enableNotifications = value),
                  MaterialIcons.notifications,
                ),
                _buildSwitchTile(
                  'Export Complete',
                  'Notify when exports finish',
                  _exportCompleteNotification,
                  (value) => setState(() => _exportCompleteNotification = value),
                  MaterialIcons.check_circle_outline,
                  enabled: _enableNotifications,
                ),
                _buildSwitchTile(
                  'Tips & Tricks',
                  'Show helpful tips and feature suggestions',
                  _tipsAndTricks,
                  (value) => setState(() => _tipsAndTricks = value),
                  MaterialIcons.lightbulb_outline,
                  enabled: _enableNotifications,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // About Section
            _buildSection(
              'About',
              Icons.info_outlined,
              [
                _buildActionTile(
                  'Version',
                  'App version 1.0.0 (Build 100)',
                  MaterialIcons.info,
                  null,
                ),
                _buildActionTile(
                  'Privacy Policy',
                  'Read our privacy policy',
                  MaterialIcons.lock_outline,
                  () => _openPrivacyPolicy(),
                ),
                _buildActionTile(
                  'Terms of Service',
                  'Review terms and conditions',
                  MaterialIcons.description,
                  () => _openTerms(),
                ),
                _buildActionTile(
                  'Licenses',
                  'View open source licenses',
                  MaterialIcons.code,
                  () => _showLicenses(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Danger Zone
            _buildSection(
              'Danger Zone',
              Icons.warning_outlined,
              [
                _buildActionTile(
                  'Reset Settings',
                  'Restore all settings to defaults',
                  MaterialIcons.refresh,
                  () => _showResetDialog(),
                  isDestructive: true,
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: _darkMode ? Colors.white70 : Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _darkMode ? Colors.white70 : Colors.grey.shade700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _darkMode ? const Color(0xFF0F3460) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon, {
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? (_darkMode ? Colors.white70 : Colors.grey.shade700) : Colors.grey.shade500,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? (_darkMode ? Colors.white : Colors.black87) : Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? (_darkMode ? Colors.white54 : Colors.grey.shade600) : Colors.grey.shade500,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: const Color(0xFF00D9FF),
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    IconData icon, {
    int? divisions,
    String? valueLabel,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            icon,
            color: _darkMode ? Colors.white70 : Colors.grey.shade700,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: _darkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: _darkMode ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _darkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              valueLabel ?? value.toStringAsFixed(1),
              style: TextStyle(
                color: _darkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF00D9FF),
              inactiveTrackColor: _darkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade300,
              thumbColor: const Color(0xFF00D9FF),
              overlayColor: const Color(0xFF00D9FF).withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    String value,
    List<String> options,
    Function(String?) onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: _darkMode ? Colors.white70 : Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _darkMode ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: _darkMode ? Colors.white54 : Colors.grey.shade600,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: _darkMode ? const Color(0xFF0F3460) : Colors.white,
        style: TextStyle(
          color: _darkMode ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        underline: Container(),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : (_darkMode ? Colors.white70 : Colors.grey.shade700),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : (_darkMode ? Colors.white : Colors.black87),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDestructive ? Colors.red.shade300 : (_darkMode ? Colors.white54 : Colors.grey.shade600),
        ),
      ),
      trailing: onTap != null
          ? Icon(
              Icons.chevron_right,
              color: isDestructive ? Colors.red : (_darkMode ? Colors.white54 : Colors.grey.shade400),
            )
          : null,
      onTap: onTap,
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _darkMode ? const Color(0xFF0F3460) : Colors.white,
        title: Text(
          'Clear Cache',
          style: TextStyle(color: _darkMode ? Colors.white : Colors.black87),
        ),
        content: Text(
          'This will delete all cached data and free up storage space. Continue?',
          style: TextStyle(color: _darkMode ? Colors.white70 : Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: _darkMode ? Colors.white70 : Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _darkMode ? const Color(0xFF0F3460) : Colors.white,
        title: Text(
          'Reset Settings',
          style: TextStyle(color: _darkMode ? Colors.white : Colors.black87),
        ),
        content: Text(
          'This will restore all settings to their default values. This action cannot be undone.',
          style: TextStyle(color: _darkMode ? Colors.white70 : Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: _darkMode ? Colors.white70 : Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetSettings();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _resetSettings() {
    setState(() {
      _darkMode = true;
      _autoSave = false;
      _showGrid = true;
      _showPixelInfo = true;
      _renderQuality = 1.0;
      _highQualityExport = true;
      _antiAliasing = false;
      _autoPlayAnimations = true;
      _animationSpeed = 1.0;
      _loopAnimations = true;
      _defaultExportFormat = 'PNG';
      _includeTransparency = true;
      _exportScale = 1.0;
      _enableNotifications = true;
      _exportCompleteNotification = true;
      _tipsAndTricks = true;
    });
  }

  void _navigateToProjects() {
    // Navigate to projects screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening saved projects...')),
    );
  }

  void _openPrivacyPolicy() {
    // Open privacy policy
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening privacy policy...')),
    );
  }

  void _openTerms() {
    // Open terms of service
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening terms of service...')),
    );
  }

  void _showLicenses() {
    showLicensePage(context: context);
  }
}

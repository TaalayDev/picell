import 'package:flutter/material.dart';
import '../../data/storage/local_storage.dart';
import '../../providers/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/ui/widgets/version_text.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../config/assets.dart';
import '../../config/constants.dart';
import '../../app/theme/theme.dart';
import '../widgets/pv/pv.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    return Scaffold(
      backgroundColor: pv.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(Strings.of(context).aboutTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: PvSpace.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            PvContentWidth(
              maxWidth: PvBreakpoints.readableWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: PvSpace.xl),
                  _buildInfoSection(context),
                  const SizedBox(height: PvSpace.lg),
                  _buildFeaturesList(context),
                  const SizedBox(height: PvSpace.lg),
                  _buildFooter(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final pv = context.pv;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: PvSpace.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(pv.primary.withValues(alpha: 0.22), pv.surface),
            pv.background,
          ],
        ),
      ),
      child: Column(
        children: [
          const PixelArtLogo(),
          const SizedBox(height: PvSpace.lg),
          Text(
            Strings.of(context).appName,
            style: pv.pixelTitle(size: 24),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: PvSpace.sm),
          VersionTextBuilder(builder: (context, version, isLoading) {
            return PvChip(label: Strings.of(context).version(version), icon: Icons.tag, color: pv.accent)
                .animate()
                .fadeIn(delay: 300.ms, duration: 600.ms);
          }),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final pv = context.pv;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Strings.of(context).welcome,
          style: pv.body(size: 22, weight: FontWeight.w700),
        ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1, end: 0),
        const SizedBox(height: PvSpace.sm),
        Text(
          Strings.of(context).aboutAppDescription,
          style: pv.body(size: 15, color: pv.textSecondary, weight: FontWeight.w400).copyWith(height: 1.5),
        ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
      ],
    );
  }

  Widget _buildFeaturesList(BuildContext context) {
    final pv = context.pv;
    final features =
        Strings.of(context).features.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

    return PvCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PvSectionHeader(
            title: Strings.of(context).featuresTitle,
            icon: Icons.auto_awesome_outlined,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: PvSpace.xs),
          ...features.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: PvSpace.xs + 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: pv.ok),
                  const SizedBox(width: PvSpace.md),
                  Expanded(child: Text(entry.value, style: pv.body(size: 14, weight: FontWeight.w400))),
                ],
              ).animate().fadeIn(delay: (300 + entry.key * 80).ms, duration: 500.ms),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final pv = context.pv;
    final linkStyle = pv.body(size: 12, color: pv.primary, weight: FontWeight.w600);
    return Column(
      children: [
        PvCard(
          padding: const EdgeInsets.symmetric(vertical: PvSpace.sm),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.public, color: pv.accent),
                title: Text(Strings.of(context).visitWebsite, style: pv.body(size: 14)),
                subtitle: Text('taalaydev.github.io', style: pv.body(size: 12, color: pv.textSecondary)),
                trailing: Icon(Icons.open_in_new, size: 18, color: pv.textSecondary),
                onTap: () => launchUrlString('https://taalaydev.github.io'),
              ),
              Divider(height: 1, color: pv.divider, indent: PvSpace.lg, endIndent: PvSpace.lg),
              const _AnalyticsToggle(),
            ],
          ),
        ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
        const SizedBox(height: PvSpace.lg),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              onPressed: () => launchUrlString(Constants.termsOfServiceUrl),
              child: Text('Terms of Service', style: linkStyle),
            ),
            Text('•', style: pv.body(size: 12, color: pv.textSecondary)),
            TextButton(
              onPressed: () => launchUrlString(Constants.privacyPolicyUrl),
              child: Text('Privacy Policy', style: linkStyle),
            ),
          ],
        ).animate().fadeIn(delay: 1000.ms, duration: 600.ms),
      ],
    );
  }
}

class _AnalyticsToggle extends ConsumerStatefulWidget {
  const _AnalyticsToggle();

  @override
  ConsumerState<_AnalyticsToggle> createState() => _AnalyticsToggleState();
}

class _AnalyticsToggleState extends ConsumerState<_AnalyticsToggle> {
  final _storage = LocalStorage();

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    return SwitchListTile(
      secondary: Icon(Icons.insights_outlined, color: pv.accent),
      title: Text('Share anonymous usage data', style: pv.body(size: 14)),
      subtitle: Text('Helps improve Picell. No projects or personal data are sent.',
          style: pv.body(size: 12, color: pv.textSecondary, weight: FontWeight.w400)),
      value: _storage.analyticsEnabled,
      onChanged: (value) {
        setState(() => _storage.analyticsEnabled = value);
        if (!value) ref.read(analyticsProvider).clear();
      },
    );
  }
}

class PixelArtLogo extends StatelessWidget {
  const PixelArtLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Image.asset(Assets.images.logo),
    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut);
  }
}

// import 'package:rzv/page/settings_page/appearance.dart';
import 'package:flutter/material.dart';
import 'package:rzv/enums/options/supported_language.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:rzv/l10n/generated/L10n.dart';
import 'package:rzv/providers/shared_preferences_provider.dart';
import 'package:provider/provider.dart';

/// Onboarding screen for first-time users
/// Shows introduction pages covering key features and settings
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final GlobalKey<IntroductionScreenState> _introKey =
      GlobalKey<IntroductionScreenState>();

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      key: _introKey,
      globalBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
      allowImplicitScrolling: true,
      infiniteAutoScroll: false,
      globalHeader: Align(
        alignment: Alignment.topRight,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 16, right: 16),
            child: _buildSkipButton(),
          ),
        ),
      ),
      pages: [
        _buildWelcomePage(),
        _buildAppearancePage(),
        _buildPluginsPage(),
        _buildEditorPage(),
        _buildCompletePage(),
      ],
      onDone: _onIntroEnd,
      onSkip: _onIntroEnd,
      showSkipButton: false, // We handle skip in globalHeader? set to false
      showBackButton: true,
      showNextButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBottomPart: true,
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: DotsDecorator(
        size: const Size(10.0, 10.0),
        color: Prefs().secondaryColor.withAlpha(150),
        activeSize: const Size(22.0, 10.0),
        activeColor: Prefs().secondaryColor,
        activeShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
      next: Icon(
        Icons.arrow_forward,
        color: Prefs().secondaryColor,
      ),
      back: Icon(
        Icons.arrow_back,
        color: Prefs().secondaryColor,
      ),
      done: Text(
        L10n.of(context).commonDone, // onboardingDone
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Prefs().secondaryColor,
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: _onIntroEnd,
      child: Text(
        L10n.of(context).commonSkip, // onboardingSkip
        style: TextStyle(
          color: Prefs().secondaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  PageViewModel _buildWelcomePage() {
    return PageViewModel(
      title: L10n.of(context).onboardingWelcomeTitle, // onboardingWelcomeTitle
      body: L10n.of(context).onboardingWelcomeBody, // onboardingWelcomeBody
      image: _buildIconPage(Icons.archive_outlined),
      decoration: _getPageDecoration(),
    );
  }

  PageViewModel _buildAppearancePage() {
    return PageViewModel(
      title: '',
      bodyWidget: _buildAppearanceSettings(),
      decoration: _getPageDecoration(),
    );
  }

  PageViewModel _buildEditorPage() {
    return PageViewModel(
      title: L10n.of(context).onboardingEditorTitle,
      bodyWidget: _buildPageWithTip(
        L10n.of(context).onboardingEditorBody,
        L10n.of(context).onboardingEditorTip,
      ),
      image: _buildIconPage(Icons.code_outlined),
      decoration: _getPageDecoration(),
    );
  }

  PageViewModel _buildPluginsPage() {
    return PageViewModel(
      title: L10n.of(context).onboardingPluginsTitle,
      bodyWidget: _buildPageWithTip(
        L10n.of(context).onboardingPluginsBody,
        L10n.of(context).onboardingPluginsTip,
      ),
      image: _buildIconPage(Icons.settings_input_hdmi_outlined),
      decoration: _getPageDecoration(),
    );
  }

  PageViewModel _buildCompletePage() {
    return PageViewModel(
      title: L10n.of(context).onboardingCompleteTitle,
      body: L10n.of(context).onboardingCompleteBody,
      image: _buildIconPage(Icons.check_circle_outline),
      decoration: _getPageDecoration(),
    );
  }

  Widget _buildIconPage(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Prefs().secondaryColor.withAlpha(10),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(20),
      child: Icon(
        icon,
        size: 60,
        color: Prefs().secondaryColor,
      ),
    );
  }

  PageDecoration _getPageDecoration() {
    return PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 26.0,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      bodyTextStyle: TextStyle(
        fontSize: 17.0,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Theme.of(context).scaffoldBackgroundColor,
      imagePadding: const EdgeInsets.symmetric(vertical: 40.0),
    );
  }

  Widget _buildAppearanceSettings() {
    Widget buildLanguageSelector() {
      final currentLocale = Prefs().locale;
      final currentLanguageCode = currentLocale?.languageCode ?? 'System';
      final currentCountryCode = currentLocale?.countryCode ?? '';
      final currentLanguageTag = currentLanguageCode +
          (currentCountryCode.isNotEmpty ? '-$currentCountryCode' : '');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.language,
                color: Prefs().secondaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                L10n.of(context).settingsAppearanceLanguage,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: Prefs().secondaryColor.withAlpha(100),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              isExpanded: true,
              underline: const SizedBox(),
              value: supportedLanguages.any(
                      (option) => option.values.first == currentLanguageTag)
                  ? currentLanguageTag
                  : 'system',
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    Prefs().saveLocaleToPrefs(newValue);
                  });
                }
              },
              items: supportedLanguages
                  .map<DropdownMenuItem<String>>((Map<String, String> option) {
                final displayName = option.keys.first;
                final languageCode = option.values.first;
                return DropdownMenuItem<String>(
                  value: languageCode,
                  child: Text(displayName),
                );
              }).toList(),
            ),
          ),
        ],
      );
    }

    Widget buildSecondaryThemeColorSelector() {
      final List<Color> themeColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    // Colors.brown,
      ]..toList();
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette,
                color: Prefs().secondaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                L10n.of(context).settingsAppearanceSecondaryColor,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: themeColors.length,
            itemBuilder: (context, index) {
              final color = themeColors[index];
              final isSelected =
                  color.toARGB32() == Prefs().secondaryColor.toARGB32();

              return GestureDetector(
                onTap: () {
                  setState(() {
                    Prefs().saveSecondaryColor(color);
                    setState(() {
                    });
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                      if (isSelected)
                        BoxShadow(
                          color: color.withAlpha(100),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            },
          ),
        ],
      );
    }

    Widget buildAccentThemeColorSelector() {
      final List<Color> themeColors = [
    Colors.redAccent,
    Colors.pinkAccent,
    Colors.purpleAccent,
    Colors.deepPurpleAccent,
    Colors.indigoAccent,
    Colors.blueAccent,
    Colors.lightBlueAccent,
    Colors.cyanAccent,
    Colors.tealAccent,
    Colors.greenAccent,
    Colors.lightGreenAccent,
    Colors.limeAccent,
    Colors.yellowAccent,
    Colors.amberAccent,
    Colors.orangeAccent,
    Colors.deepOrangeAccent,
    // Colors.brown,
      ]..toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette,
                color: Prefs().accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                L10n.of(context).settingsAppearanceAccentColor,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: themeColors.length,
            itemBuilder: (context, index) {
              final color = themeColors[index];
              final isSelected =
                  color.toARGB32() == Prefs().accentColor.toARGB32();

              return GestureDetector(
                onTap: () {
                  setState(() {
                    Prefs().saveAccentColor(color);
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                      if (isSelected)
                        BoxShadow(
                          color: color.withAlpha(100),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            },
          ),
        ],
      );
    }

    return Consumer<Prefs>(
      builder: (context, prefs, child) {
        return SingleChildScrollView(
          child: Column(
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(0),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withAlpha(50),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.palette_outlined,
                      size: 30,
                      color: Prefs().secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    L10n.of(context).settingsAppearance,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    L10n.of(context).customizeYourExperience, // customizeYourExperience
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(150),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              buildLanguageSelector(),
              // const SizedBox(height: 12),
              // Row(
              //   children: [
              //     Icon(
              //       Icons.contrast,
              //       color: Prefs().secondaryColor,
              //       size: 20,
              //     ),
              //     const SizedBox(width: 8),
              //     Expanded(
              //       child: Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Text(
              //             L10n.of(context).eInkMode, // eInkMode
              //             style: TextStyle(
              //               fontSize: 16,
              //               fontWeight: FontWeight.w600,
              //               color: Theme.of(context).colorScheme.onSurface,
              //             ),
              //           ),
              //           Text(
              //             L10n.of(context).optimizedForEInkDisplays, // optimizedForEInkDisplays
              //             style: TextStyle(
              //               fontSize: 12,
              //               color: Theme.of(context)
              //                   .colorScheme
              //                   .onSurface
              //                   .withAlpha(150),
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              //     Switch(
              //       value: prefs.eInkMode, // eInkMode
              //       onChanged: (value) {
              //         setState(() {
              //           if (value) {
              //             prefs.saveThemeMode('light');
              //           }
              //           prefs.eInkMode = value;
              //         });
              //       },
              //     ),
              //   ],
              // ),
              const SizedBox(height: 16),
              buildSecondaryThemeColorSelector(),
              const SizedBox(height: 16),
              buildAccentThemeColorSelector(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Prefs().secondaryColor.withAlpha(50),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Prefs().secondaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        L10n.of(context).moreDisplayOptionsTip, // moreDisplayOptionsTip
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(150),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageWithTip(String bodyText, String tipText) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          bodyText,
          style: TextStyle(
            fontSize: 17.0,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withAlpha(50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Prefs().secondaryColor.withAlpha(50),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Prefs().secondaryColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tipText,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(150),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onIntroEnd() async {
    widget.onComplete();
  }
}
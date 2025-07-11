import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_dash/audio/audio.dart';
import 'package:super_dash/globals.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double musicVolume = 0.5;
  double sfxVolume = 0.5;

  void _updateMusicVolume(double change) {
    setState(() {
      musicVolume = (musicVolume + change).clamp(0.0, 1.0);
    });
    audioController.setMusicVolume(musicVolume);
    _saveVolumeSettings(); // ⬅️ save it
  }

  void _updateSfxVolume(double change) {
    setState(() {
      sfxVolume = (sfxVolume + change).clamp(0.0, 1.0);
    });
    audioController.setSfxVolume(sfxVolume);
    _saveVolumeSettings(); // ⬅️ save it
  }


  Widget _buildVolumeRow({
    required String label,
    required double volume,
    required VoidCallback onIncrease,
    required VoidCallback onDecrease,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onDecrease,
          child: Image.asset('assets/images/decrease_button.png'),
        ),
        const SizedBox(width: 10),
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Image.asset('assets/images/voice_panel.png',),
            // Positioned(
            //   left: 8,
            //   child: Container(
            //     width: 96 * volume,
            //     height: 30,
            //     decoration: const BoxDecoration(
            //       image: DecorationImage(
            //         image: AssetImage('assets/images/voice_Controller.png'),
            //
            //       ),
            //     ),
            //   ),
            // ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                (volume *5).round(),
                    (index) => Image.asset(
                  'assets/images/voice_Controller.png',
                  height: 15,
                  width: 40,
                  fit: BoxFit.fill, // Optional: makes sure it fills tight space
                ),
              ),
            )

          ],
        ),

        GestureDetector(
          onTap: onIncrease,
          child: Image.asset('assets/images/incease_button.png'),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadVolumeSettings(); // ⬅️ Load saved volume
  }

  /// Loads volume levels from shared preferences
  void _loadVolumeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      musicVolume = prefs.getDouble('musicVolume') ?? 0.5;
      sfxVolume = prefs.getDouble('sfxVolume') ?? 0.5;
    });
    audioController.setMusicVolume(musicVolume);
    audioController.setSfxVolume(sfxVolume);
  }

  /// Saves volume levels to shared preferences
  void _saveVolumeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('musicVolume', musicVolume);
    await prefs.setDouble('sfxVolume', sfxVolume);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/component_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 10,
                left: 10,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Image.asset(
                    'assets/images/back_arrow.png',
                    height: 50,
                    width: 50,
                  ),
                ),
              ),
              Positioned(
                top: 200,
                left: 0,
                right: 0,
                child: Center(
                  child: Image.asset('assets/images/settings_banner.png'),
                ),
              ),
              Positioned(
                top: 330,
                left: 0,
                right: 0,
                child: _buildVolumeRow(
                  label: "Music",
                  volume: musicVolume,
                  onDecrease: () => _updateMusicVolume(-0.1),
                  onIncrease: () => _updateMusicVolume(0.1),
                ),
              ),
              Positioned(
                top: 400,
                left: 0,
                right: 0,
                child: _buildVolumeRow(
                  label: "SFX",
                  volume: sfxVolume,
                  onDecrease: () => _updateSfxVolume(-0.1),
                  onIncrease: () => _updateSfxVolume(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
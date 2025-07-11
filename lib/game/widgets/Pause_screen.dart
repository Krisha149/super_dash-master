// import 'package:flutter/material.dart';
// import 'package:super_dash/game/view/game_view.dart';
// import 'package:super_dash/game/widgets/settings_screen.dart'; // Ensure this exists
//
// class PauseDialog extends StatelessWidget {
//   const PauseDialog({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.transparent,
//       insetPadding: EdgeInsets.zero,
//       child: Stack(
//         children: [
//           // Background image
//           Container(
//             width: double.infinity,
//             height: double.infinity,
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage('assets/images/component_bg.png'),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//
//           // Back button
//           Positioned(
//             top: 10,
//             left: 10,
//             child: GestureDetector(
//               onTap: () => Navigator.pop(context),
//               child: Image.asset(
//                 'assets/images/back_arrow.png',
//                 height: 50,
//                 width: 50,
//               ),
//             ),
//           ),
//
//           // Pause banner
//           Positioned(
//             top: 100,
//             left: 0,
//             right: 0,
//             child: Center(
//               child: Image.asset(
//                 'assets/images/Pause_banner.png',
//                 height: 561,
//                 width: 316,
//               ),
//             ),
//           ),
//
//           // Buttons
//           Positioned(
//             left: 0,
//             right: 0,
//             top: 190,
//             child: Column(
//               children: [
//                 GestureDetector(
//                   onTap: () => Navigator.pop(context), // Resume
//                   child: Image.asset(
//                     'assets/images/Resume_button.png',
//                     height: 95,
//                     width: 260,
//                   ),
//                 ),
//                 GestureDetector(
//                   onTap: () {
//                     Navigator.pop(context); // Close dialog
//                     Navigator.pop(context); // Close game
//                     Navigator.push(context, Game.route()); // Restart
//                   },
//                   child: Image.asset(
//                     'assets/images/Restart_button.png',
//                     height: 95,
//                     width: 260,
//                   ),
//                 ),
//                 GestureDetector(
//                   onTap: () {
//                     Navigator.push(context, MaterialPageRoute(builder: (context)=>SettingsScreen()));
//                   },
//                   child: Image.asset(
//                     'assets/images/settings_button.png',
//                     height: 95,
//                     width: 260,
//                   ),
//                 ),
//                 GestureDetector(
//                   onTap: () {
//                     Navigator.pop(context); // Close dialog
//                     Navigator.pop(context); // Exit game
//                   },
//                   child: Image.asset(
//                     'assets/images/Quit_button.png',
//                     height: 95,
//                     width: 260,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_dash/game/view/game_view.dart';
import 'package:super_dash/game/widgets/settings_screen.dart';

class PauseDialog extends StatefulWidget {
  const PauseDialog({super.key});

  @override
  State<PauseDialog> createState() => _PauseDialogState();
}

class _PauseDialogState extends State<PauseDialog> {
  bool _isFirstTime = true;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasOpenedBefore = prefs.getBool('hasOpenedPauseDialog') ?? false;

    if (!hasOpenedBefore) {
      // First time
      await prefs.setBool('hasOpenedPauseDialog', true);
    }

    setState(() {
      _isFirstTime = !hasOpenedBefore;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/component_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Back button
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

          // Pause banner
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/Pause_banner.png',
                height: 561,
                width: 316,
              ),
            ),
          ),

          // Buttons
          Positioned(
            left: 0,
            right: 0,
            top: 190,
            child: Column(
              children: [
                if (!_isFirstTime) ...[
                  GestureDetector(
                    onTap: () => Navigator.pop(context), // Resume
                    child: Image.asset(
                      'assets/images/Resume_button.png',
                      height: 95,
                      width: 260,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                      Navigator.push(context, Game.route()); // Restart
                    },
                    child: Image.asset(
                      'assets/images/Restart_button.png',
                      height: 95,
                      width: 260,
                    ),
                  ),
                ],
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                  child: Image.asset(
                    'assets/images/settings_button.png',
                    height: 95,
                    width: 260,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Exit game
                  },
                  child: Image.asset(
                    'assets/images/Quit_button.png',
                    height: 95,
                    width: 260,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

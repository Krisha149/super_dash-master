import 'package:app_ui/app_ui.dart';
import 'package:flow_builder/flow_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:super_dash/game/game.dart';
import 'package:super_dash/game_intro/game_intro.dart';
import 'package:super_dash/gen/assets.gen.dart';
import 'package:super_dash/l10n/l10n.dart';
import 'package:super_dash/score/score.dart';
import 'package:super_dash/utils/utils.dart';
//

class GameOverPage extends StatelessWidget {
  const GameOverPage({super.key});

  static Page<void> page() {
    return const MaterialPage(
      child: GameOverPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = context.select((ScoreBloc bloc) => bloc.score);

    return PageWithBackground(
      background: const GameBackground(),
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: Assets.images.gameOverBg.provider(),
                  fit: BoxFit.cover,
                  alignment: isDesktop
                      ? const Alignment(0, -.5)
                      : Alignment.topCenter,
                ),
              ),
            ),
          ),

          // Top Left - Coins Box
          Positioned(
            top: 190,
            left: 50,
            child: _ScoreBox(
              icon: Image.asset(
                'assets/images/Group (10).png',
                width: 24,
                height: 24,
              ),
              value: '$score',
              label: 'Coins',
            ),
          ),

          // Top Right - Distance Box (without trophy)
          Positioned(
            top: 190,
            right: 50,
            child: _ScoreBox(
              icon: null, // no trophy
              value: '$score mtrs',
              label: 'Distance',
            ),
          ),

          // Center Content
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),

                // Continue Button
                GestureDetector(
                  onTap: context.flow<ScoreState>().complete,
                  child: Image.asset(
                    'assets/images/Group 839.png',
                    width: 260,
                  ),
                ),

                const SizedBox(height: 16),

                // Coin + Score Below Continue Button
                Container(
                  width: 88,
                  height: 48,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/Group (11).png'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/Group (10).png',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontFamily: 'altivoblack',
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Quit Button
          Positioned(
            bottom: 180,
            left: 100,
            child: GestureDetector(
              onTap: SystemNavigator.pop,
              child: Image.asset(
                'assets/images/Group 838.png',
                height: 100,
                width: 180,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final Widget? icon;
  final String value;
  final String label;

  const _ScoreBox({
    this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Group (11).png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) icon!,
          if (icon != null) const SizedBox(width: 6),
          Stack(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'altivoblack',
                  fontSize: 22,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 2
                    ..color = Colors.black,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'altivoblack',
                  fontSize: 22,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 4.0,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}




// import 'package:app_ui/app_ui.dart';
// import 'package:flow_builder/flow_builder.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';
// import 'package:super_dash/game/game.dart';
// import 'package:super_dash/game_intro/game_intro.dart';
// import 'package:super_dash/gen/assets.gen.dart';
// import 'package:super_dash/l10n/l10n.dart';
// import 'package:super_dash/score/score.dart';
// import 'package:super_dash/utils/utils.dart';
//
// class GameOverPage extends StatelessWidget {
//   const GameOverPage({super.key});
//
//   static Page<void> page() {
//     return const MaterialPage(
//       child: GameOverPage(),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final l10n = context.l10n;
//     final textTheme = Theme.of(context).textTheme;
//     const titleColor = Color(0xFF18274C);
//
//     return PageWithBackground(
//       background: const GameBackground(),
//       child: DecoratedBox(
//         decoration: BoxDecoration(
//           image: DecorationImage(
//             image: Assets.images.gameOverBg.provider(),
//             fit: BoxFit.cover,
//             alignment:
//                 isDesktop ? const Alignment(0, -.5) : Alignment.topCenter,
//           ),
//         ),
//         child: Column(
//           children: [
//             const Spacer(flex: 15),
//             Text(
//               l10n.gameOver,
//               style: textTheme.headlineMedium?.copyWith(
//                 color: titleColor,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             Text(
//               l10n.betterLuckNextTime,
//               style: textTheme.bodyLarge?.copyWith(
//                 color: titleColor,
//               ),
//             ),
//             const Spacer(flex: 4),
//             Text(
//               l10n.totalScore,
//               style: textTheme.bodyLarge?.copyWith(
//                 color: titleColor,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const Spacer(flex: 2),
//             const _ScoreWidget(),
//             const Spacer(flex: 4),
//             GameElevatedButton(
//               label: l10n.submitScore,
//               onPressed: () {
//                 context.read<ScoreBloc>().add(const ScoreSubmitted());
//               },
//             ),
//             const Spacer(flex: 3),
//             GameElevatedButton.icon(
//               label: l10n.playAgain,
//               icon: const Icon(Icons.refresh, size: 16),
//               onPressed: context.flow<ScoreState>().complete,
//               gradient: const LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   Color(0xFFA6C3DF),
//                   Color(0xFF79AACA),
//                 ],
//               ),
//             ),
//             const Spacer(flex: 40),
//          //   const BottomBar(),
//             const SizedBox(height: 16),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _ScoreWidget extends StatelessWidget {
//   const _ScoreWidget();
//
//   @override
//   Widget build(BuildContext context) {
//     final l10n = context.l10n;
//     final textTheme = Theme.of(context).textTheme;
//     final score = context.select((ScoreBloc bloc) => bloc.score);
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             Color(0x80EAFFFE),
//             Color(0x80C9D9F1),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(100),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Assets.images.trophy.image(width: 40, height: 40),
//           const SizedBox(width: 8),
//           RichText(
//             text: TextSpan(
//               style: textTheme.headlineMedium?.copyWith(
//                 color: const Color(0xFF4D5B92),
//                 fontWeight: FontWeight.bold,
//               ),
//               children: [
//                 TextSpan(text: '${formatScore(score)} '),
//                 TextSpan(
//                   text: l10n.pts,
//                   style: const TextStyle(fontSize: 24),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String formatScore(int score) {
//     final formatter = NumberFormat('#,###');
//     return formatter.format(score);
//   }
// }
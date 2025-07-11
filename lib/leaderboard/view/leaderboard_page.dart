import 'package:app_ui/app_ui.dart';
import 'package:flame/cache.dart';
import 'package:flame/image_composition.dart';
import 'package:flame/widgets.dart';
import 'package:flow_builder/flow_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:leaderboard_repository/leaderboard_repository.dart';
import 'package:super_dash/game/game.dart';
import 'package:super_dash/gen/assets.gen.dart';
import 'package:super_dash/l10n/l10n.dart';
import 'package:super_dash/leaderboard/bloc/leaderboard_bloc.dart';
import 'package:super_dash/score/score.dart';

enum LeaderboardStep { gameIntro, gameScore }

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({
    this.step = LeaderboardStep.gameIntro,
    super.key,
  });

  static Page<void> page([
    LeaderboardStep step = LeaderboardStep.gameScore,
  ]) {
    return MaterialPage(
      child: LeaderboardPage(step: step),
    );
  }

  static PageRoute<void> route([
    LeaderboardStep step = LeaderboardStep.gameIntro,
  ]) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => LeaderboardPage(step: step),
    );
  }

  final LeaderboardStep step;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LeaderboardBloc(
        leaderboardRepository: context.read<LeaderboardRepository>(),
      )..add(const LeaderboardTop10Requested()),
      child: LeaderboardView(step: step),
    );
  }
}

class LeaderboardView extends StatelessWidget {
  const LeaderboardView({
    required this.step,
    super.key,
  });

  final LeaderboardStep step;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PageWithBackground(
      background: const GameBackground(),
      child: Stack(
        children: [
          // Background and leaderboard content
          DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: Assets.images.leaderboardBg.provider(),
                fit: BoxFit.fill,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * .08,
                ),
                const Leaderboard(),
              ],
            ),
          ),

          // Back button in top-left corner
          Positioned(
            top: 40,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Image.asset('assets/images/Group 865.png', // Replace with your correct asset reference
                width: 40,
                height: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Leaderboard extends StatelessWidget {
  const Leaderboard({super.key});

  static const width =440.0;
  static const height = 660.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      //margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Group (8).png'), // 🟤 your brown board image
          fit: BoxFit.fill,
        ),
      ),
      child: BlocBuilder<LeaderboardBloc, LeaderboardState>(
        builder: (context, state) => switch (state) {
          LeaderboardInitial() => const SizedBox.shrink(),
          LeaderboardLoading() =>
          const Center(child: LeaderboardLoadingWidget()),
          LeaderboardError() => const Center(child: LeaderboardErrorWidget()),
          LeaderboardLoaded(entries: final entries) =>
              LeaderboardContent(entries: entries),
        },
      ),
    );
  }
}

@visibleForTesting
class LeaderboardErrorWidget extends StatelessWidget {
  const LeaderboardErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // SizedBox.square(
        //   dimension: 64,
        //   child: SpriteAnimationWidget.asset(
        //     images: Images(prefix: ''),
        //  //   path: Assets.map.anim.spritesheetDashDeathFaintPn
        //     //   g.path,
        //     data: SpriteAnimationData.sequenced(
        //       amount: 16,
        //       stepTime: 0.042,
        //       textureSize: Vector2.all(64), // Game's tile size.
        //       amountPerRow: 8,
        //       loop: false,
        //     ),
        //   ),
        // ),
        const SizedBox(height: 24),
        Text(context.l10n.leaderboardPageLeaderboardErrorText),
      ],
    );
  }
}

@visibleForTesting
class LeaderboardLoadingWidget extends StatelessWidget {
  const LeaderboardLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 64,
      child: SpriteAnimationWidget.asset(
        images: Images(prefix: ''),
        path: Assets.map.anim.spritesheetDashRunPng.path,
        data: SpriteAnimationData.sequenced(
          amount: 16,
          stepTime: 0.042,
          textureSize: Vector2.all(64), // Game's tile size.
          amountPerRow: 8,
        ),
      ),
    );
  }
}

@visibleForTesting
class LeaderboardContent extends StatelessWidget {
  const LeaderboardContent({
    required this.entries,
    super.key,
  });

  final List<LeaderboardEntryData> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Center(
          child: Container(
            width: Leaderboard.width,
            height: Leaderboard.height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Group (8).png'), // 🟤 your brown board image
                fit: BoxFit.fill,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 60, bottom: 20, left: 16, right: 16),
              child: Column(
                children: [
                  if (entries.isEmpty)
                    Center(
                      child: Text(
                        context.l10n.leaderboardPageLeaderboardNoEntries,
                        style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white,fontFamily:' altivoBold'),
                      ),
                    )
                  else
                    Expanded(
                      child: _LeaderboardEntries(entries: entries),
                    ),
                ],
              ),
            ),
          ),
        ),

        // 🟠 LEADERBOARD title image placed above the brown box
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          // bottom: 570,
          child: Center(
            child: Image.asset(
              'assets/images/leaderboard_title.png',
              height: 80,
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardEntries extends StatelessWidget {
  const _LeaderboardEntries({required this.entries});

  final List<LeaderboardEntryData> entries;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isTopThree = index < 3;

        // Trophy icon for top 3
        Widget? leadingIcon;
        if (isTopThree) {
          leadingIcon = Image.asset(
            'assets/images/rank_${index + 1}.png',
            height: 32,
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isTopThree
                ? const Color(0xFFFFDF80)  // yellow for top 3
                : const Color(0xFFAA9563), // brown for others
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                leadingIcon,
                const SizedBox(width: 8),
              ],

              if(leadingIcon == null) ...[
                const SizedBox(width: 32,),
              ],

              // Avatar
              // Plain rectangular image (not circle)
              Image.asset(
                'assets/images/player_icon.png',
                height: 36,
                width: 36,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),

              // Player Name
              Text(
                entry.playerInitials,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: ' altivoBold',
                  shadows: [
                    Shadow(
                      offset: Offset(2.0, 2.0), // shadow ni position
                      blurRadius: 4.0, // shadow no blur
                      color: Colors.grey.withOpacity(0.5), // shadow no color
                    ),
                  ],                ),
              ),

              const Spacer(),

              // Score
              Text(
                '${entry.score} mtrs',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: ' altivoBold',
                  shadows: [
                    Shadow(
                      offset: Offset(2.0, 2.0), // shadow ni position
                      blurRadius: 4.0, // shadow no blur
                      color: Colors.grey.withOpacity(0.5), // shadow no color
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
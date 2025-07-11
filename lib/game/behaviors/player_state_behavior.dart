import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:super_dash/game/entities/player.dart';
import 'package:super_dash/game/game.dart';

enum DashState {
  idle,
  running,

  phoenixIdle,
  phoenixRunning,

  deathPit,
  deathFaint,

  jump,
  phoenixJump,

  phoenixDoubleJump,
}

class PlayerStateBehavior extends Behavior<Player> {
  DashState? _state;
  late final Map<DashState, PositionComponent> _stateMap;

  DashState get state => _state ?? DashState.idle;

  static const _needResetStates = {
    DashState.deathPit,
    DashState.deathFaint,
    DashState.jump,
    DashState.phoenixJump,
    DashState.phoenixDoubleJump,
  };

  void updateSpritePaintColor(Color color) {
    for (final component in _stateMap.values) {
      if (component is HasPaint) {
        (component as HasPaint).paint.color = color;
      }
    }
  }

  void fadeOut({VoidCallback? onComplete}) {
    final component = _stateMap[state];
    if (component != null && component is HasPaint) {
      component.add(
        OpacityEffect.fadeOut(
          EffectController(duration: .5),
          onComplete: onComplete,
        ),
      );
    }
  }

  void fadeIn({VoidCallback? onComplete}) {
    final component = _stateMap[state];
    if (component != null && component is HasPaint) {
      component.add(
        OpacityEffect.fadeIn(
          EffectController(duration: .5, startDelay: .8),
          onComplete: onComplete,
        ),
      );
    }
  }

  set state(DashState state) {
    if (state != _state) {
      final current = _stateMap[_state];
      if (current != null) {
        current.removeFromParent();
        if (_needResetStates.contains(_state)) {
          if (current is SpriteAnimationComponent) {
            current.animationTicker?.reset();
          }
        }
      }
      final replacement = _stateMap[state];
      if (replacement != null) {
        if (replacement is SpriteAnimationComponent &&
            _needResetStates.contains(state)) {
          replacement.animationTicker?.reset();
        }
        parent.add(replacement);
      }
      _state = state;
    }
  }

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    final [
    idleAnimation,
    runAnimation,
    jumpAnimation,
    deadAnimation,
    ] = await Future.wait([
      parent.gameRef.loadSpriteAnimation(
        'DogSpritee/idel-Sheet.png',
        SpriteAnimationData.sequenced(
          amount: 10,
          stepTime: 0.042,
          textureSize: Vector2(147, 140),
        ),
      ),
      parent.gameRef.loadSpriteAnimation(
        'DogSpritee/run.png',
        SpriteAnimationData.sequenced(
          amount: 8,
          stepTime: 0.042,
          textureSize: Vector2(146, 128),
        ),
      ),
      parent.gameRef.loadSpriteAnimation(
        'DogSpritee/jump-Sheet.png',
        SpriteAnimationData.sequenced(
          amount: 10,
          stepTime: 0.042,
          textureSize: Vector2(134, 128),
          loop: false,
        ),
      ),
      parent.gameRef.loadSpriteAnimation(
        'DogSpritee/dead-Sheet.png',
        SpriteAnimationData.sequenced(
          amount: 10,
          stepTime: 0.042,
          textureSize: Vector2(168, 128),
          loop: false,
        ),
      ),
    ]);

    final paint = Paint()..isAntiAlias = false;
    final centerPosition = Vector2(parent.size.x / 2, parent.size.y); // bottom center



    _stateMap = {
      DashState.idle: _makeAnim(idleAnimation, centerPosition, paint),
      DashState.running: _makeAnim(runAnimation, centerPosition, paint),

      // Fallback phoenix animations
      DashState.phoenixIdle: _makeAnim(idleAnimation, centerPosition, paint),
      DashState.phoenixRunning: _makeAnim(runAnimation, centerPosition, paint),

      DashState.jump: _makeAnim(jumpAnimation, centerPosition, paint),
      DashState.phoenixJump: _makeAnim(jumpAnimation, centerPosition, paint),
      DashState.phoenixDoubleJump: _makeAnim(jumpAnimation.clone(), centerPosition, paint),

      DashState.deathPit: _makeAnim(deadAnimation, centerPosition, paint),
      DashState.deathFaint: _makeAnim(deadAnimation.clone(), centerPosition, paint),
    };

    state = DashState.idle;
  }

  SpriteAnimationComponent _makeAnim(
      SpriteAnimation animation,
      Vector2 position,
      Paint paint,
      ) {
    return SpriteAnimationComponent(
      animation: animation,
      anchor: Anchor.bottomCenter,      // 👈 fixes shifting
      position: Vector2(parent.size.x / 2, parent.size.y), // 👈 bottom center
      size: parent.size*4,            // 👈 scaling up doggo
      paint: paint,
    );
  }
}
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/sprite.dart';
import 'package:flame/src/components/core/component_tree_root.dart';
import 'package:flame/src/game/flame_game.dart';
import 'package:flame/src/game/game_render_box.dart';
import 'package:flame/src/game/game_widget/gesture_detector_builder.dart';
import 'package:flame/src/game/overlay_manager.dart';
import 'package:flame/text.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/rendering/object.dart';
import 'package:leap/leap.dart';
import 'package:super_dash/audio/audio.dart';
import 'package:super_dash/game/entities/item.dart';
import 'package:super_dash/game/entities/player.dart';
import 'package:super_dash/game/game.dart';
import 'package:super_dash/score/score.dart';

bool _tsxPackingFilter(Tileset tileset) {
  return !(tileset.source ?? '').startsWith('anim');
}

Paint _layerPaintFactory(double opacity) {
  return Paint()
    ..color = Color.fromRGBO(255, 255, 255, opacity)
    ..isAntiAlias = false;
}

class SuperDashGame extends LeapGame
    with TapDetector, HasKeyboardHandlerComponents {
  SuperDashGame({
    required this.gameBloc,
    required this.audioController,
    this.customBundle,
    this.inMapTester = false,
  }) : super(
    tileSize: 64,
    configuration: const LeapConfiguration(
      tiled: TiledOptions(
        atlasMaxX: 4048,
        atlasMaxY: 4048,
        tsxPackingFilter: _tsxPackingFilter,
        layerPaintFactory: _layerPaintFactory,
        atlasPackingSpacingX: 4,
        atlasPackingSpacingY: 4,
      ),
    ),
  );


  static final _cameraViewport = Vector2(592, 1024);
  static const prefix = 'assets/map/';
  static const _sections = [
    'flutter_runnergame_map_A.tmx',
    'flutter_runnergame_map_B.tmx',
    'flutter_runnergame_map_C.tmx',
  ];
  static const _sectionsBackgroundColor = [
    (Color(0xFFDADEF6), Color(0xFFEAF0E3)),
    (Color(0xFFEBD6E1), Color(0xFFC9C8E9)),
    (Color(0xFF002052), Color(0xFF0055B4)),
  ];

  final GameBloc gameBloc;
  final AssetBundle? customBundle;
  final AudioController audioController;
  final List<VoidCallback> _inputListener = [];

  late final SpriteSheet itemsSpritesheet;
  final bool inMapTester;

  GameState get state => gameBloc.state;

  Player? get player => world.firstChild<Player>();

  List<Tileset> get tilesets => leapMap.tiledMap.tileMap.map.tilesets;

  Tileset get itemsTileset {
    return tilesets.firstWhere(
          (tileset) => tileset.name == 'tile_items_v2',
    );
  }

  Tileset get enemiesTileset {
    return tilesets.firstWhere(
          (tileset) => tileset.name == 'tile_enemies_v2',
    );
  }

  void addInputListener(VoidCallback listener) {
    _inputListener.add(listener);
  }

  void removeInputListener(VoidCallback listener) {
    _inputListener.remove(listener);
  }

  void _triggerInputListeners() {
    for (final listener in _inputListener) {
      listener();
    }
  }

  @override
  void onTapDown(TapDownInfo info) {
    super.onTapDown(info);

    _triggerInputListeners();
    overlays.remove('tapToJump');
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    if (inMapTester) {
      _addMapTesterFeatures();
    }

    if (kIsWeb && audioController.isMusicEnabled) {
      audioController.startMusic();
    }

    camera = CameraComponent.withFixedResolution(
      width: _cameraViewport.x,
      height: _cameraViewport.y,
    )
      ..world = world;

    images = Images(
      prefix: prefix,
      bundle: customBundle,
    );

    itemsSpritesheet = SpriteSheet(
      image: await images.load('objects/tile_items_v2.png'),
      srcSize: Vector2.all(tileSize),
    );

    await loadWorldAndMap(
      images: images,
      prefix: prefix,
      bundle: customBundle,
      tiledMapPath: _sections.first,
    );
    _setSectionBackground();

    final player = Player(
      levelSize: leapMap.tiledMap.size.clone(),
      cameraViewport: _cameraViewport,
    );
    unawaited(
      world.addAll([player]),
    );

    await _addSpawners();
    _addTreeHouseFrontLayer();
    _addTreeHouseSign();

    add(
      KeyboardListenerComponent(
        keyDown: {
          LogicalKeyboardKey.space: (_) {
            _triggerInputListeners();
            overlays.remove('tapToJump');
            return false;
          },
        },
        keyUp: {
          LogicalKeyboardKey.space: (_) {
            return false;
          },
        },
      ),
    );
  }

  void _addTreeHouseSign() {
    world.add(
      TreeSign(
        position: Vector2(
          448,
          1862,
        ),
      ),
    );
  }

  void _addTreeHouseFrontLayer() {
    final layer = leapMap.tiledMap.tileMap.renderableLayers.last;
    world.add(TreeHouseFront(renderFront: layer.render));
  }

  void _setSectionBackground() {
    final colors = _sectionsBackgroundColor[state.currentSection];
    camera.backdrop = RectangleComponent(
      size: size.clone(),
      paint: Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.x, size.y),
          [
            colors.$1,
            colors.$2,
          ],
        ),
    );
  }

  void gameOver() {
    gameBloc.add(const GameOver());
    // Removed since the result didn't ended up good.
    // Leaving in comment if we decide to bring it back.
    // audioController.stopBackgroundSfx();

    world.firstChild<Player>()?.removeFromParent();

    _resetEntities();

    Future<void>.delayed(
      const Duration(seconds: 1),
          () async {
        await loadWorldAndMap(
          images: images,
          prefix: prefix,
          bundle: customBundle,
          tiledMapPath: _sections.first,
        );
        if (isLastSection || isFirstSection) {
          _addTreeHouseFrontLayer();
        }

        if (isFirstSection) {
          _addTreeHouseSign();
        }
        final newPlayer = Player(
          levelSize: leapMap.tiledMap.size.clone(),
          cameraViewport: _cameraViewport,
        );
        await world.add(newPlayer);

        await newPlayer.mounted;
        await _addSpawners();
        overlays.add('tapToJump');
      },
    );

    if (buildContext != null) {
      final score = gameBloc.state.score;
      Navigator.of(buildContext!).push(
        ScorePage.route(score: score),
      );
    }
  }

  void _resetEntities() {
    children.whereType<ObjectGroupProximityBuilder<Player>>().forEach(
          (spawner) => spawner.removeFromParent(),
    );
    world.firstChild<TreeHouseFront>()?.removeFromParent();
    world.firstChild<TreeSign>()?.removeFromParent();

    leapMap.children
        .whereType<Enemy>()
        .forEach((enemy) => enemy.removeFromParent());
    leapMap.children
        .whereType<Item>()
        .forEach((enemy) => enemy.removeFromParent());
  }

  Future<void> _addSpawners() async {
    await addAll([
      ObjectGroupProximityBuilder<Player>(
        proximity: _cameraViewport.x * 1.5,
        tileLayerName: 'items',
        tileset: itemsTileset,
        componentBuilder: Item.new,
      ),
      ObjectGroupProximityBuilder<Player>(
        proximity: _cameraViewport.x * 1.5,
        tileLayerName: 'enemies',
        tileset: enemiesTileset,
        componentBuilder: Enemy.new,
      ),
    ]);
  }

  Future<void> _loadNewSection() async {
    final nextSectionIndex = state.currentSection + 1 < _sections.length
        ? state.currentSection + 1
        : 0;

    final nextSection = _sections[nextSectionIndex];

    _resetEntities();

    await loadWorldAndMap(
      images: images,
      prefix: prefix,
      bundle: customBundle,
      tiledMapPath: nextSection,
    );

    if (isFirstSection) {
      _addTreeHouseSign();
    }

    if (isLastSection || isFirstSection) {
      _addTreeHouseFrontLayer();
    }

    await _addSpawners();
  }

  @override
  void onMapUnload(LeapMap map) {
    player?.velocity.setZero();
  }

  @override
  void onMapLoaded(LeapMap map) {
    player?.loadSpawnPoint();
    player?.loadRespawnPoints();
    player?.walking = true;
    player?.spritePaintColor(Colors.white);
    player?.isPlayerTeleporting = false;

    _setSectionBackground();
  }

  void sectionCleared() {
    if (isLastSection) {
      player?.spritePaintColor(Colors.transparent);
      player?.walking = false;
    }

    _loadNewSection();

    gameBloc..add(GameScoreIncreased(by: 1000 * state.currentLevel))..add(
        GameSectionCompleted(sectionCount: _sections.length));
  }

  bool get isLastSection => state.currentSection == _sections.length - 1;

  bool get isFirstSection => state.currentSection == 0;

  void addCameraDebugger() {
    if (descendants()
        .whereType<CameraDebugger>()
        .isEmpty) {
      final player = world.firstChild<Player>()!;

      final cameraDebugger = CameraDebugger(
        position: player.position.clone(),
      );
      world.add(cameraDebugger);

      final anchor = PlayerCameraAnchor(
        levelSize: leapMap.tiledMap.size.clone(),
        cameraViewport: _cameraViewport,
      );
      cameraDebugger.add(anchor);
      camera.follow(anchor);

      final proximityBuilders =
      descendants().whereType<ObjectGroupProximityBuilder<Player>>();
      for (final proximityBuilder in proximityBuilders) {
        proximityBuilder.currentReference = cameraDebugger;
      }

      player.removeFromParent();
    }
  }

  void toggleInvincibility() {
    player?.isPlayerInvincible = !(player?.isPlayerInvincible ?? false);
  }

  void teleportPlayerToEnd() {
    player?.x = leapMap.tiledMap.size.x - (player?.size.x ?? 0) * 10 * 4;
    if (state.currentSection == 2) {
      player?.y = (player?.y ?? 0) - (tileSize * 4);
    }
  }

  void showHitBoxes() {
    void show() {
      descendants()
          .whereType<PhysicalEntity>()
          .where(
            (element) =>
        element is Player || element is Item || element is Enemy,
      )
          .forEach((entity) => entity.debugMode = true);
    }

    show();
    add(
      TimerComponent(
        period: 1,
        repeat: true,
        onTick: show,
      ),
    );
  }

  void _addMapTesterFeatures() {
    add(FpsComponent());
    add(
      FpsTextComponent(
        position: Vector2(0, 0),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}
//
//   @override
//  late AssetsCache assets;
//
//   @override
//  late CameraComponent camera;
//
//   @override
//  late ui.Color debugColor;
//
//   @override
//   late int? debugCoordinatesPrecision;
//
//   @override
//  late bool debugMode;
//
//   @override
//  late Images images;
//
//   @override
//   late MouseCursor mouseCursor;
//
//   @override
//   late void Function(PointerHoverEvent event)? mouseDetector;
//
//   @override
//   late Component? parent;
//
//   @override
//   late bool pauseWhenBackgrounded;
//
//   @override
//   late  bool paused;
//
//   @override
//   late  int priority;
//
//   @override
//   late World world;
//
//   @override
//   FutureOr<void> add(Component component) {
//     // TODO: implement add
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<void> addAll(Iterable<Component> components) {
//     // TODO: implement addAll
//     throw UnimplementedError();
//   }
//
//   @override
//   void addGameStateListener(ui.VoidCallback callback) {
//     // TODO: implement addGameStateListener
//   }
//
//   @override
//   FutureOr<void> addToParent(Component parent) {
//     // TODO: implement addToParent
//     throw UnimplementedError();
//   }
//
//   @override
//   Iterable<Component> ancestors({bool includeSelf = false}) {
//     // TODO: implement ancestors
//     throw UnimplementedError();
//   }
//
//   @override
//   void assertHasLayout() {
//     // TODO: implement assertHasLayout
//   }
//
//   @override
//   void attach(PipelineOwner owner, GameRenderBox gameRenderBox) {
//     // TODO: implement attach
//   }
//
//   @override
//   ui.Color backgroundColor() {
//     // TODO: implement backgroundColor
//     throw UnimplementedError();
//   }
//
//   @override
//   // TODO: implement buildContext
//   BuildContext? get buildContext => throw UnimplementedError();
//
//   @override
//   // TODO: implement canvasSize
//   Vector2 get canvasSize => throw UnimplementedError();
//
//   @override
//   // TODO: implement children
//   ComponentSet get children => throw UnimplementedError();
//
//   @override
//   Iterable<Component> componentsAtLocation<T>(T locationContext, List<T>? nestedContexts, T? Function(CoordinateTransform p1, T p2) transformContext, bool Function(Component p1, T p2) checkContains) {
//     // TODO: implement componentsAtLocation
//     throw UnimplementedError();
//   }
//
//   @override
//   Iterable<Component> componentsAtPoint(Vector2 point, [List<Vector2>? nestedPoints]) {
//     // TODO: implement componentsAtPoint
//     throw UnimplementedError();
//   }
//
//   @override
//   ComponentsNotifier<T> componentsNotifier<T extends Component>() {
//     // TODO: implement componentsNotifier
//     throw UnimplementedError();
//   }
//
//   @override
//   bool contains(Component c) {
//     // TODO: implement contains
//     throw UnimplementedError();
//   }
//
//   @override
//   bool containsLocalPoint(Vector2 point) {
//     // TODO: implement containsLocalPoint
//     throw UnimplementedError();
//   }
//
//   @override
//   bool containsPoint(Vector2 point) {
//     // TODO: implement containsPoint
//     throw UnimplementedError();
//   }
//
//   @override
//   Vector2 convertGlobalToLocalCoordinate(Vector2 point) {
//     // TODO: implement convertGlobalToLocalCoordinate
//     throw UnimplementedError();
//   }
//
//   @override
//   Vector2 convertLocalToGlobalCoordinate(Vector2 point) {
//     // TODO: implement convertLocalToGlobalCoordinate
//     throw UnimplementedError();
//   }
//
//   @override
//   ComponentSet createComponentSet() {
//     // TODO: implement createComponentSet
//     throw UnimplementedError();
//   }
//
//   @override
//   double currentTime() {
//     // TODO: implement currentTime
//     throw UnimplementedError();
//   }
//
//   @override
//   // TODO: implement debugPaint
//   ui.Paint get debugPaint => throw UnimplementedError();
//
//   @override
//   // TODO: implement debugTextPaint
//   TextPaint get debugTextPaint => throw UnimplementedError();
//
//   @override
//   void dequeueAdd(Component child, Component parent) {
//     // TODO: implement dequeueAdd
//   }
//
//   @override
//   void dequeueRemove(Component child) {
//     // TODO: implement dequeueRemove
//   }
//
//   @override
//   Iterable<Component> descendants({bool includeSelf = false, bool reversed = false}) {
//     // TODO: implement descendants
//     throw UnimplementedError();
//   }
//
//   @override
//   void detach() {
//     // TODO: implement detach
//   }
//
//   @override
//   void enqueueAdd(Component child, Component parent) {
//     // TODO: implement enqueueAdd
//   }
//
//   @override
//   void enqueueMove(Component child, Component newParent) {
//     // TODO: implement enqueueMove
//   }
//
//   @override
//   void enqueueRebalance(Component parent) {
//     // TODO: implement enqueueRebalance
//   }
//
//   @override
//   void enqueueRemove(Component child, Component parent) {
//     // TODO: implement enqueueRemove
//   }
//
//   @override
//   void finalizeRemoval() {
//     // TODO: implement finalizeRemoval
//   }
//
//   @override
//   T? findByKey<T extends Component>(ComponentKey key) {
//     // TODO: implement findByKey
//     throw UnimplementedError();
//   }
//
//   @override
//   T? findByKeyName<T extends Component>(String name) {
//     // TODO: implement findByKeyName
//     throw UnimplementedError();
//   }
//
//   @override
//   FlameGame<World>? findGame() {
//     // TODO: implement findGame
//     throw UnimplementedError();
//   }
//
//   @override
//   T? findParent<T extends Component>({bool includeSelf = false}) {
//     // TODO: implement findParent
//     throw UnimplementedError();
//   }
//
//   @override
//   FlameGame<World>? findRootGame() {
//     // TODO: implement findRootGame
//     throw UnimplementedError();
//   }
//
//   @override
//   T? firstChild<T extends Component>() {
//     // TODO: implement firstChild
//     throw UnimplementedError();
//   }
//
//   @override
//   // TODO: implement gameStateListeners
//   List<ui.VoidCallback> get gameStateListeners => throw UnimplementedError();
//
//   @override
//   // TODO: implement gestureDetectors
//   GestureDetectorBuilder get gestureDetectors => throw UnimplementedError();
//
//   @override
//   LifecycleEventStatus handleLifecycleEventAdd(Component parent) {
//     // TODO: implement handleLifecycleEventAdd
//     throw UnimplementedError();
//   }
//
//   @override
//   LifecycleEventStatus handleLifecycleEventMove(Component newParent) {
//     // TODO: implement handleLifecycleEventMove
//     throw UnimplementedError();
//   }
//
//   @override
//   LifecycleEventStatus handleLifecycleEventRemove(Component parent) {
//     // TODO: implement handleLifecycleEventRemove
//     throw UnimplementedError();
//   }
//
//   @override
//   void handleResize(Vector2 size) {
//     // TODO: implement handleResize
//   }
//
//   @override
//   // TODO: implement hasChildren
//   bool get hasChildren => throw UnimplementedError();
//
//   @override
//   // TODO: implement hasLayout
//   bool get hasLayout => throw UnimplementedError();
//
//   @override
//   // TODO: implement hasLifecycleEvents
//   bool get hasLifecycleEvents => throw UnimplementedError();
//
//   @override
//   // TODO: implement isAttached
//   bool get isAttached => throw UnimplementedError();
//
//   @override
//   // TODO: implement isLoaded
//   bool get isLoaded => throw UnimplementedError();
//
//   @override
//   // TODO: implement isLoading
//   bool get isLoading => throw UnimplementedError();
//
//   @override
//   // TODO: implement isMounted
//   bool get isMounted => throw UnimplementedError();
//
//   @override
//   // TODO: implement isMounting
//   bool get isMounting => throw UnimplementedError();
//
//   @override
//   // TODO: implement isRemoved
//   bool get isRemoved => throw UnimplementedError();
//
//   @override
//   // TODO: implement isRemoving
//   bool get isRemoving => throw UnimplementedError();
//
//   @override
//   // TODO: implement key
//   ComponentKey? get key => throw UnimplementedError();
//
//   @override
//   T? lastChild<T extends Component>() {
//     // TODO: implement lastChild
//     throw UnimplementedError();
//   }
//
//   @override
//   void lifecycleStateChange(ui.AppLifecycleState state) {
//     // TODO: implement lifecycleStateChange
//   }
//
//   @override
//   FutureOr<void> load() {
//     // TODO: implement load
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<Sprite> loadSprite(String path, {Vector2? srcSize, Vector2? srcPosition}) {
//     // TODO: implement loadSprite
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<SpriteAnimation> loadSpriteAnimation(String path, SpriteAnimationData data) {
//     // TODO: implement loadSpriteAnimation
//     throw UnimplementedError();
//   }
//
//   @override
//   // TODO: implement loaded
//   Future<void> get loaded => throw UnimplementedError();
//
//   @override
//   void mount() {
//     // TODO: implement mount
//   }
//
//   @override
//   // TODO: implement mounted
//   Future<void> get mounted => throw UnimplementedError();
//
//   @override
//   // TODO: implement notifiers
//   List<ComponentsNotifier<Component>> get notifiers => throw UnimplementedError();
//
//   @override
//   void onAttach() {
//     // TODO: implement onAttach
//   }
//
//   @override
//   void onChildrenChanged(Component child, ChildrenChangeType type) {
//     // TODO: implement onChildrenChanged
//   }
//
//   @override
//   void onDetach() {
//     // TODO: implement onDetach
//   }
//
//   @override
//   void onDispose() {
//     // TODO: implement onDispose
//   }
//
//   @override
//   void onGameResize(Vector2 size) {
//     // TODO: implement onGameResize
//   }
//
//   @override
//   void onMount() {
//     // TODO: implement onMount
//   }
//
//   @override
//   void onParentResize(Vector2 maxSize) {
//     // TODO: implement onParentResize
//   }
//
//   @override
//   void onRemove() {
//     // TODO: implement onRemove
//   }
//
//   @override
//   // TODO: implement overlays
//   OverlayManager get overlays => throw UnimplementedError();
//
//   @override
//   void pauseEngine() {
//     // TODO: implement pauseEngine
//   }
//
//   @override
//   void processLifecycleEvents() {
//     // TODO: implement processLifecycleEvents
//   }
//
//   @override
//   void processRebalanceEvents() {
//     // TODO: implement processRebalanceEvents
//   }
//
//   @override
//   void propagateToApplicableNotifiers(Component component, void Function(ComponentsNotifier<Component> p1) callback) {
//     // TODO: implement propagateToApplicableNotifiers
//   }
//
//   @override
//   bool propagateToChildren<T extends Component>(bool Function(T p1) handler, {bool includeSelf = false}) {
//     // TODO: implement propagateToChildren
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<void> ready() {
//     // TODO: implement ready
//     throw UnimplementedError();
//   }
//
//   @override
//   void refreshWidget({bool isInternalRefresh = true}) {
//     // TODO: implement refreshWidget
//   }
//
//   @override
//   void registerKey(ComponentKey key, Component component) {
//     // TODO: implement registerKey
//   }
//
//   @override
//   void remove(Component component) {
//     // TODO: implement remove
//   }
//
//   @override
//   void removeAll(Iterable<Component> components) {
//     // TODO: implement removeAll
//   }
//
//   @override
//   void removeFromParent() {
//     // TODO: implement removeFromParent
//   }
//
//   @override
//   void removeGameStateListener(ui.VoidCallback callback) {
//     // TODO: implement removeGameStateListener
//   }
//
//   @override
//   void removeWhere(bool Function(Component component) test) {
//     // TODO: implement removeWhere
//   }
//
//   @override
//   // TODO: implement removed
//   Future<void> get removed => throw UnimplementedError();
//
//   @override
//   void render(ui.Canvas canvas) {
//     // TODO: implement render
//   }
//
//   @override
//   // TODO: implement renderBox
//   GameRenderBox get renderBox => throw UnimplementedError();
//
//   @override
//   void renderDebugMode(ui.Canvas canvas) {
//     // TODO: implement renderDebugMode
//   }
//
//   @override
//   void renderTree(ui.Canvas canvas) {
//     // TODO: implement renderTree
//   }
//
//   @override
//   void resumeEngine() {
//     // TODO: implement resumeEngine
//   }
//
//   @override
//   void setLoaded() {
//     // TODO: implement setLoaded
//   }
//
//   @override
//   void setMounted() {
//     // TODO: implement setMounted
//   }
//
//   @override
//   void setRemoved() {
//     // TODO: implement setRemoved
//   }
//
//   @override
//   // TODO: implement size
//   Vector2 get size => throw UnimplementedError();
//
//   @override
//   void stepEngine({double stepTime = 1 / 60}) {
//     // TODO: implement stepEngine
//   }
//
//   @override
//   FutureOr<void> toBeLoaded() {
//     // TODO: implement toBeLoaded
//     throw UnimplementedError();
//   }
//
//   @override
//   void unregisterKey(ComponentKey key) {
//     // TODO: implement unregisterKey
//   }
//
//   @override
//   void update(double dt) {
//     // TODO: implement update
//   }
//
//   @override
//   void updateTree(double dt) {
//     // TODO: implement updateTree
//   }
// }
//
//   @override
//  late AssetsCache assets;
//
//   @override
//  late CameraComponent camera;
//
//   @override
//  late ui.Color debugColor;
//
//   @override
//   late int? debugCoordinatesPrecision;
//
//   @override
//  late bool debugMode;
//
//   @override
//  late Images images;
//
//   @override
//   late MouseCursor mouseCursor;
//
//   @override
//   late void Function(PointerHoverEvent event)? mouseDetector;
//
//   @override
//   late Component? parent;
//
//   @override
//   late bool pauseWhenBackgrounded;
//
//   @override
//   late  bool paused;
//
//   @override
//   late  int priority;
//
//   @override
//   late World world;
//
//   @override
//   FutureOr<void> add(Component component) {
//     // TODO: implement add
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<void> addAll(Iterable<Component> components) {
//     // TODO: implement addAll
//     throw UnimplementedError();
//   }
//
//   @override
//   void addGameStateListener(ui.VoidCallback callback) {
//     // TODO: implement addGameStateListener
//   }
//
//   @override
//   FutureOr<void> addToParent(Component parent) {
//     // TODO: implement addToParent
//     throw UnimplementedError();
//   }
//
//   @override
//   Iterable<Component> ancestors({bool includeSelf = false}) {
//     // TODO: implement ancestors
//     throw UnimplementedError();
//   }
//
//   @override
//   void assertHasLayout() {
//     // TODO: implement assertHasLayout
//   }
//
//   @override
//   void attach(PipelineOwner owner, GameRenderBox gameRenderBox) {
//     // TODO: implement attach
//   }
//
//   @override
//   ui.Color backgroundColor() {
//     // TODO: implement backgroundColor
//     throw UnimplementedError();
//   }
//
//   @override
//   // TODO: implement buildContext
//   BuildContext? get buildContext => throw UnimplementedError();
//
//   @override
//   // TODO: implement canvasSize
//   Vector2 get canvasSize => throw UnimplementedError();
//
//   @override
//   // TODO: implement children
//   ComponentSet get children => throw UnimplementedError();
//
//   @override
//   Iterable<Component> componentsAtLocation<T>(T locationContext, List<T>? nestedContexts, T? Function(CoordinateTransform p1, T p2) transformContext, bool Function(Component p1, T p2) checkContains) {
//     // TODO: implement componentsAtLocation
//     throw UnimplementedError();
//   }
//
//   @override
//   Iterable<Component> componentsAtPoint(Vector2 point, [List<Vector2>? nestedPoints]) {
//     // TODO: implement componentsAtPoint
//     throw UnimplementedError();
//   }
//
//   @override
//   ComponentsNotifier<T> componentsNotifier<T extends Component>() {
//     // TODO: implement componentsNotifier
//     throw UnimplementedError();
//   }
//
//   @override
//   bool contains(Component c) {
//     // TODO: implement contains
//     throw UnimplementedError();
//   }
//
//   @override
//   bool containsLocalPoint(Vector2 point) {
//     // TODO: implement containsLocalPoint
//     throw UnimplementedError();
//   }
//
//   @override
//   bool containsPoint(Vector2 point) {
//     // TODO: implement containsPoint
//     throw UnimplementedError();
//   }
//
//   @override
//   Vector2 convertGlobalToLocalCoordinate(Vector2 point) {
//     // TODO: implement convertGlobalToLocalCoordinate
//     throw UnimplementedError();
//   }
//
//   @override
//   Vector2 convertLocalToGlobalCoordinate(Vector2 point) {
//     // TODO: implement convertLocalToGlobalCoordinate
//     throw UnimplementedError();
//   }
//
//   @override
//   ComponentSet createComponentSet() {
//     // TODO: implement createComponentSet
//     throw UnimplementedError();
//   }
//
//   @override
//   double currentTime() {
//     // TODO: implement currentTime
//     throw UnimplementedError();
//   }
//
//   @override
//   // TODO: implement debugPaint
//   ui.Paint get debugPaint => throw UnimplementedError();
//
//   @override
//   // TODO: implement debugTextPaint
//   TextPaint get debugTextPaint => throw UnimplementedError();
//
//   @override
//   void dequeueAdd(Component child, Component parent) {
//     // TODO: implement dequeueAdd
//   }
//
//   @override
//   void dequeueRemove(Component child) {
//     // TODO: implement dequeueRemove
//   }
//
//   @override
//   Iterable<Component> descendants({bool includeSelf = false, bool reversed = false}) {
//     // TODO: implement descendants
//     throw UnimplementedError();
//   }
//
//   @override
//   void detach() {
//     // TODO: implement detach
//   }
//
//   @override
//   void enqueueAdd(Component child, Component parent) {
//     // TODO: implement enqueueAdd
//   }
//
//   @override
//   void enqueueMove(Component child, Component newParent) {
//     // TODO: implement enqueueMove
//   }
//
//   @override
//   void enqueueRebalance(Component parent) {
//     // TODO: implement enqueueRebalance
//   }
//
//   @override
//   void enqueueRemove(Component child, Component parent) {
//     // TODO: implement enqueueRemove
//   }
//
//   @override
//   void finalizeRemoval() {
//     // TODO: implement finalizeRemoval
//   }
//
//   @override
//   T? findByKey<T extends Component>(ComponentKey key) {
//     // TODO: implement findByKey
//     throw UnimplementedError();
//   }
//
//   @override
//   T? findByKeyName<T extends Component>(String name) {
//     // TODO: implement findByKeyName
//     throw UnimplementedError();
//   }
//
//   @override
//   FlameGame<World>? findGame() {
//     // TODO: implement findGame
//     throw UnimplementedError();
//   }
//
//   @override
//   T? findParent<T extends Component>({bool includeSelf = false}) {
//     // TODO: implement findParent
//     throw UnimplementedError();
//   }
//
//   @override
//   FlameGame<World>? findRootGame() {
//     // TODO: implement findRootGame
//     throw UnimplementedError();
//   }
//
//   @override
//   T? firstChild<T extends Component>() {
//     // TODO: implement firstChild
//     throw UnimplementedError();
//   }
//
//   @override
//   // TODO: implement gameStateListeners
//   List<ui.VoidCallback> get gameStateListeners => throw UnimplementedError();
//
//   @override
//   // TODO: implement gestureDetectors
//   GestureDetectorBuilder get gestureDetectors => throw UnimplementedError();
//
//   @override
//   LifecycleEventStatus handleLifecycleEventAdd(Component parent) {
//     // TODO: implement handleLifecycleEventAdd
//     throw UnimplementedError();
//   }
//
//   @override
//   LifecycleEventStatus handleLifecycleEventMove(Component newParent) {
//     // TODO: implement handleLifecycleEventMove
//     throw UnimplementedError();
//   }
//
//   @override
//   LifecycleEventStatus handleLifecycleEventRemove(Component parent) {
//     // TODO: implement handleLifecycleEventRemove
//     throw UnimplementedError();
//   }
//
//   @override
//   void handleResize(Vector2 size) {
//     // TODO: implement handleResize
//   }
//
//   @override
//   // TODO: implement hasChildren
//   bool get hasChildren => throw UnimplementedError();
//
//   @override
//   // TODO: implement hasLayout
//   bool get hasLayout => throw UnimplementedError();
//
//   @override
//   // TODO: implement hasLifecycleEvents
//   bool get hasLifecycleEvents => throw UnimplementedError();
//
//   @override
//   // TODO: implement isAttached
//   bool get isAttached => throw UnimplementedError();
//
//   @override
//   // TODO: implement isLoaded
//   bool get isLoaded => throw UnimplementedError();
//
//   @override
//   // TODO: implement isLoading
//   bool get isLoading => throw UnimplementedError();
//
//   @override
//   // TODO: implement isMounted
//   bool get isMounted => throw UnimplementedError();
//
//   @override
//   // TODO: implement isMounting
//   bool get isMounting => throw UnimplementedError();
//
//   @override
//   // TODO: implement isRemoved
//   bool get isRemoved => throw UnimplementedError();
//
//   @override
//   // TODO: implement isRemoving
//   bool get isRemoving => throw UnimplementedError();
//
//   @override
//   // TODO: implement key
//   ComponentKey? get key => throw UnimplementedError();
//
//   @override
//   T? lastChild<T extends Component>() {
//     // TODO: implement lastChild
//     throw UnimplementedError();
//   }
//
//   @override
//   void lifecycleStateChange(ui.AppLifecycleState state) {
//     // TODO: implement lifecycleStateChange
//   }
//
//   @override
//   FutureOr<void> load() {
//     // TODO: implement load
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<Sprite> loadSprite(String path, {Vector2? srcSize, Vector2? srcPosition}) {
//     // TODO: implement loadSprite
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<SpriteAnimation> loadSpriteAnimation(String path, SpriteAnimationData data) {
//     // TODO: implement loadSpriteAnimation
//     throw UnimplementedError();
//   }
//
//   @override
//   // TODO: implement loaded
//   Future<void> get loaded => throw UnimplementedError();
//
//   @override
//   void mount() {
//     // TODO: implement mount
//   }
//
//   @override
//   // TODO: implement mounted
//   Future<void> get mounted => throw UnimplementedError();
//
//   @override
//   // TODO: implement notifiers
//   List<ComponentsNotifier<Component>> get notifiers => throw UnimplementedError();
//
//   @override
//   void onAttach() {
//     // TODO: implement onAttach
//   }
//
//   @override
//   void onChildrenChanged(Component child, ChildrenChangeType type) {
//     // TODO: implement onChildrenChanged
//   }
//
//   @override
//   void onDetach() {
//     // TODO: implement onDetach
//   }
//
//   @override
//   void onDispose() {
//     // TODO: implement onDispose
//   }
//
//   @override
//   void onGameResize(Vector2 size) {
//     // TODO: implement onGameResize
//   }
//
//   @override
//   void onMount() {
//     // TODO: implement onMount
//   }
//
//   @override
//   void onParentResize(Vector2 maxSize) {
//     // TODO: implement onParentResize
//   }
//
//   @override
//   void onRemove() {
//     // TODO: implement onRemove
//   }
//
//   @override
//   // TODO: implement overlays
//   OverlayManager get overlays => throw UnimplementedError();
//
//   @override
//   void pauseEngine() {
//     // TODO: implement pauseEngine
//   }
//
//   @override
//   void processLifecycleEvents() {
//     // TODO: implement processLifecycleEvents
//   }
//
//   @override
//   void processRebalanceEvents() {
//     // TODO: implement processRebalanceEvents
//   }
//
//   @override
//   void propagateToApplicableNotifiers(Component component, void Function(ComponentsNotifier<Component> p1) callback) {
//     // TODO: implement propagateToApplicableNotifiers
//   }
//
//   @override
//   bool propagateToChildren<T extends Component>(bool Function(T p1) handler, {bool includeSelf = false}) {
//     // TODO: implement propagateToChildren
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<void> ready() {
//     // TODO: implement ready
//     throw UnimplementedError();
//   }
//
//   @override
//   void refreshWidget({bool isInternalRefresh = true}) {
//     // TODO: implement refreshWidget
//   }
//
//   @override
//   void registerKey(ComponentKey key, Component component) {
//     // TODO: implement registerKey
//   }
//
//   @override
//   void remove(Component component) {
//     // TODO: implement remove
//   }
//
//   @override
//   void removeAll(Iterable<Component> components) {
//     // TODO: implement removeAll
//   }
//
//   @override
//   void removeFromParent() {
//     // TODO: implement removeFromParent
//   }
//
//   @override
//   void removeGameStateListener(ui.VoidCallback callback) {
//     // TODO: implement removeGameStateListener
//   }
//
//   @override
//   void removeWhere(bool Function(Component component) test) {
//     // TODO: implement removeWhere
//   }
//
//   @override
//   // TODO: implement removed
//   Future<void> get removed => throw UnimplementedError();
//
//   @override
//   void render(ui.Canvas canvas) {
//     // TODO: implement render
//   }
//
//   @override
//   // TODO: implement renderBox
//   GameRenderBox get renderBox => throw UnimplementedError();
//
//   @override
//   void renderDebugMode(ui.Canvas canvas) {
//     // TODO: implement renderDebugMode
//   }
//
//   @override
//   void renderTree(ui.Canvas canvas) {
//     // TODO: implement renderTree
//   }
//
//   @override
//   void resumeEngine() {
//     // TODO: implement resumeEngine
//   }
//
//   @override
//   void setLoaded() {
//     // TODO: implement setLoaded
//   }
//
//   @override
//   void setMounted() {
//     // TODO: implement setMounted
//   }
//
//   @override
//   void setRemoved() {
//     // TODO: implement setRemoved
//   }
//
//   @override
//   // TODO: implement size
//   Vector2 get size => throw UnimplementedError();
//
//   @override
//   void stepEngine({double stepTime = 1 / 60}) {
//     // TODO: implement stepEngine
//   }
//
//   @override
//   FutureOr<void> toBeLoaded() {
//     // TODO: implement toBeLoaded
//     throw UnimplementedError();
//   }
//
//   @override
//   void unregisterKey(ComponentKey key) {
//     // TODO: implement unregisterKey
//   }
//
//   @override
//   void update(double dt) {
//     // TODO: implement update
//   }
//
//   @override
//   void updateTree(double dt) {
//     // TODO: implement updateTree
//   }
// }
//   @override
//  late AssetsCache assets;
//
//   @override
//  late CameraComponent camera;
//
//   @override
//  late ui.Color debugColor;
//
//   @override
//   late int? debugCoordinatesPrecision;
//
//   @override
//  late bool debugMode;
//
//   @override
//  late Images images;
//
//   @override
//   late MouseCursor mouseCursor;
//
//   @override
//   late void Function(PointerHoverEvent event)? mouseDetector;
//
//   @override
//   late Component? parent;
//
//   @override
//   late bool pauseWhenBackgrounded;
//
//   @override
//   late  bool paused;
//
//   @override
//   late  int priority;
//
//   @override
//   late World world;
//
//   @override
//   FutureOr<void> add(Component component) {
//     // TODO: implement add
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<void> addAll(Iterable<Component> components) {
//     // TODO: implement addAll
//     throw UnimplementedError();
//   }
//
//   @override
//   void addGameStateListener(ui.VoidCallback callback) {
//     // TODO: implement addGameStateListener
//   }
//
//   @override
//   FutureOr<void> addToParent(Component parent) {
//     // TODO: implement addToParent
//     throw UnimplementedError();
//   }
//
//   @override
//   Iterable<Component> ancestors({bool includeSelf = false}) {
//     // TODO: implement ancestors
//     throw UnimplementedError();
//   }
//
//   @override
//   void assertHasLayout() {
//     // TODO: implement assertHasLayout
//   }
//
//   @override
//   void attach(PipelineOwner owner, GameRenderBox gameRenderBox) {
//     // TODO: implement attach
//   }
//
//   @override
//   ui.Color backgroundColor() {
//     // TODO: implement backgroundColor
//     throw UnimplementedError();
//   }
//
//   @override
//   // TODO: implement buildContext
//   BuildContext? get buildContext => throw UnimplementedError();
//
//   @override
//   // TODO: implement canvasSize
//   Vector2 get canvasSize => throw UnimplementedError();
//
//   @override
//   // TODO: implement children
//   ComponentSet get children => throw UnimplementedError();
//
//   @override
//   Iterable<Component> componentsAtLocation<T>(T locationContext, List<T>? nestedContexts, T? Function(CoordinateTransform p1, T p2) transformContext, bool Function(Component p1, T p2) checkContains) {
//     // TODO: implement componentsAtLocation
//     throw UnimplementedError();
//   }
//
//   @override
//   Iterable<Component> componentsAtPoint(Vector2 point, [List<Vector2>? nestedPoints]) {
//     // TODO: implement componentsAtPoint
//     throw UnimplementedError();
//   }
//
//   @override
//   ComponentsNotifier<T> componentsNotifier<T extends Component>() {
//     // TODO: implement componentsNotifier
//     throw UnimplementedError();
//   }
//
//   @override
//   bool contains(Component c) {
//     // TODO: implement contains
//     throw UnimplementedError();
//   }
//
//   @override
//   bool containsLocalPoint(Vector2 point) {
//     // TODO: implement containsLocalPoint
//     throw UnimplementedError();
//   }
//
//   @override
//   bool containsPoint(Vector2 point) {
//     // TODO: implement containsPoint
//     throw UnimplementedError();
//   }
//
//   @override
//   Vector2 convertGlobalToLocalCoordinate(Vector2 point) {
//     // TODO: implement convertGlobalToLocalCoordinate
//     throw UnimplementedError();
//   }
//
//   @override
//   Vector2 convertLocalToGlobalCoordinate(Vector2 point) {
//     // TODO: implement convertLocalToGlobalCoordinate
//     throw UnimplementedError();
//   }
//
//   @override
//   ComponentSet createComponentSet() {
//     // TODO: implement createComponentSet
//     throw UnimplementedError();
//   }
//
//   @override
//   double currentTime() {
//     // TODO: implement currentTime
//     throw UnimplementedError();
//   }
//
//   @override
//   // TODO: implement debugPaint
//   ui.Paint get debugPaint => throw UnimplementedError();
//
//   @override
//   // TODO: implement debugTextPaint
//   TextPaint get debugTextPaint => throw UnimplementedError();
//
//   @override
//   void dequeueAdd(Component child, Component parent) {
//     // TODO: implement dequeueAdd
//   }
//
//   @override
//   void dequeueRemove(Component child) {
//     // TODO: implement dequeueRemove
//   }
//
//   @override
//   Iterable<Component> descendants({bool includeSelf = false, bool reversed = false}) {
//     // TODO: implement descendants
//     throw UnimplementedError();
//   }
//
//   @override
//   void detach() {
//     // TODO: implement detach
//   }
//
//   @override
//   void enqueueAdd(Component child, Component parent) {
//     // TODO: implement enqueueAdd
//   }
//
//   @override
//   void enqueueMove(Component child, Component newParent) {
//     // TODO: implement enqueueMove
//   }
//
//   @override
//   void enqueueRebalance(Component parent) {
//     // TODO: implement enqueueRebalance
//   }
//
//   @override
//   void enqueueRemove(Component child, Component parent) {
//     // TODO: implement enqueueRemove
//   }
//
//   @override
//   void finalizeRemoval() {
//     // TODO: implement finalizeRemoval
//   }
//
//   @override
//   T? findByKey<T extends Component>(ComponentKey key) {
//     // TODO: implement findByKey
//     throw UnimplementedError();
//   }
//
//   @override
//   T? findByKeyName<T extends Component>(String name) {
//     // TODO: implement findByKeyName
//     throw UnimplementedError();
//   }
//
//   @override
//   FlameGame<World>? findGame() {
//     // TODO: implement findGame
//     throw UnimplementedError();
//   }
//
//   @override
//   T? findParent<T extends Component>({bool includeSelf = false}) {
//     // TODO: implement findParent
//     throw UnimplementedError();
//   }
//
//   @override
//   FlameGame<World>? findRootGame() {
//     // TODO: implement findRootGame
//     throw UnimplementedError();
//   }
//
//   @override
//   T? firstChild<T extends Component>() {
//     // TODO: implement firstChild
//     throw UnimplementedError();
//   }
//
//   @override
//   // TODO: implement gameStateListeners
//   List<ui.VoidCallback> get gameStateListeners => throw UnimplementedError();
//
//   @override
//   // TODO: implement gestureDetectors
//   GestureDetectorBuilder get gestureDetectors => throw UnimplementedError();
//
//   @override
//   LifecycleEventStatus handleLifecycleEventAdd(Component parent) {
//     // TODO: implement handleLifecycleEventAdd
//     throw UnimplementedError();
//   }
//
//   @override
//   LifecycleEventStatus handleLifecycleEventMove(Component newParent) {
//     // TODO: implement handleLifecycleEventMove
//     throw UnimplementedError();
//   }
//
//   @override
//   LifecycleEventStatus handleLifecycleEventRemove(Component parent) {
//     // TODO: implement handleLifecycleEventRemove
//     throw UnimplementedError();
//   }
//
//   @override
//   void handleResize(Vector2 size) {
//     // TODO: implement handleResize
//   }
//
//   @override
//   // TODO: implement hasChildren
//   bool get hasChildren => throw UnimplementedError();
//
//   @override
//   // TODO: implement hasLayout
//   bool get hasLayout => throw UnimplementedError();
//
//   @override
//   // TODO: implement hasLifecycleEvents
//   bool get hasLifecycleEvents => throw UnimplementedError();
//
//   @override
//   // TODO: implement isAttached
//   bool get isAttached => throw UnimplementedError();
//
//   @override
//   // TODO: implement isLoaded
//   bool get isLoaded => throw UnimplementedError();
//
//   @override
//   // TODO: implement isLoading
//   bool get isLoading => throw UnimplementedError();
//
//   @override
//   // TODO: implement isMounted
//   bool get isMounted => throw UnimplementedError();
//
//   @override
//   // TODO: implement isMounting
//   bool get isMounting => throw UnimplementedError();
//
//   @override
//   // TODO: implement isRemoved
//   bool get isRemoved => throw UnimplementedError();
//
//   @override
//   // TODO: implement isRemoving
//   bool get isRemoving => throw UnimplementedError();
//
//   @override
//   // TODO: implement key
//   ComponentKey? get key => throw UnimplementedError();
//
//   @override
//   T? lastChild<T extends Component>() {
//     // TODO: implement lastChild
//     throw UnimplementedError();
//   }
//
//   @override
//   void lifecycleStateChange(ui.AppLifecycleState state) {
//     // TODO: implement lifecycleStateChange
//   }
//
//   @override
//   FutureOr<void> load() {
//     // TODO: implement load
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<Sprite> loadSprite(String path, {Vector2? srcSize, Vector2? srcPosition}) {
//     // TODO: implement loadSprite
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<SpriteAnimation> loadSpriteAnimation(String path, SpriteAnimationData data) {
//     // TODO: implement loadSpriteAnimation
//     throw UnimplementedError();
//   }
//
//   @override
//   // TODO: implement loaded
//   Future<void> get loaded => throw UnimplementedError();
//
//   @override
//   void mount() {
//     // TODO: implement mount
//   }
//
//   @override
//   // TODO: implement mounted
//   Future<void> get mounted => throw UnimplementedError();
//
//   @override
//   // TODO: implement notifiers
//   List<ComponentsNotifier<Component>> get notifiers => throw UnimplementedError();
//
//   @override
//   void onAttach() {
//     // TODO: implement onAttach
//   }
//
//   @override
//   void onChildrenChanged(Component child, ChildrenChangeType type) {
//     // TODO: implement onChildrenChanged
//   }
//
//   @override
//   void onDetach() {
//     // TODO: implement onDetach
//   }
//
//   @override
//   void onDispose() {
//     // TODO: implement onDispose
//   }
//
//   @override
//   void onGameResize(Vector2 size) {
//     // TODO: implement onGameResize
//   }
//
//   @override
//   void onMount() {
//     // TODO: implement onMount
//   }
//
//   @override
//   void onParentResize(Vector2 maxSize) {
//     // TODO: implement onParentResize
//   }
//
//   @override
//   void onRemove() {
//     // TODO: implement onRemove
//   }
//
//   @override
//   // TODO: implement overlays
//   OverlayManager get overlays => throw UnimplementedError();
//
//   @override
//   void pauseEngine() {
//     // TODO: implement pauseEngine
//   }
//
//   @override
//   void processLifecycleEvents() {
//     // TODO: implement processLifecycleEvents
//   }
//
//   @override
//   void processRebalanceEvents() {
//     // TODO: implement processRebalanceEvents
//   }
//
//   @override
//   void propagateToApplicableNotifiers(Component component, void Function(ComponentsNotifier<Component> p1) callback) {
//     // TODO: implement propagateToApplicableNotifiers
//   }
//
//   @override
//   bool propagateToChildren<T extends Component>(bool Function(T p1) handler, {bool includeSelf = false}) {
//     // TODO: implement propagateToChildren
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<void> ready() {
//     // TODO: implement ready
//     throw UnimplementedError();
//   }
//
//   @override
//   void refreshWidget({bool isInternalRefresh = true}) {
//     // TODO: implement refreshWidget
//   }
//
//   @override
//   void registerKey(ComponentKey key, Component component) {
//     // TODO: implement registerKey
//   }
//
//   @override
//   void remove(Component component) {
//     // TODO: implement remove
//   }
//
//   @override
//   void removeAll(Iterable<Component> components) {
//     // TODO: implement removeAll
//   }
//
//   @override
//   void removeFromParent() {
//     // TODO: implement removeFromParent
//   }
//
//   @override
//   void removeGameStateListener(ui.VoidCallback callback) {
//     // TODO: implement removeGameStateListener
//   }
//
//   @override
//   void removeWhere(bool Function(Component component) test) {
//     // TODO: implement removeWhere
//   }
//
//   @override
//   // TODO: implement removed
//   Future<void> get removed => throw UnimplementedError();
//
//   @override
//   void render(ui.Canvas canvas) {
//     // TODO: implement render
//   }
//
//   @override
//   // TODO: implement renderBox
//   GameRenderBox get renderBox => throw UnimplementedError();
//
//   @override
//   void renderDebugMode(ui.Canvas canvas) {
//     // TODO: implement renderDebugMode
//   }
//
//   @override
//   void renderTree(ui.Canvas canvas) {
//     // TODO: implement renderTree
//   }
//
//   @override
//   void resumeEngine() {
//     // TODO: implement resumeEngine
//   }
//
//   @override
//   void setLoaded() {
//     // TODO: implement setLoaded
//   }
//
//   @override
//   void setMounted() {
//     // TODO: implement setMounted
//   }
//
//   @override
//   void setRemoved() {
//     // TODO: implement setRemoved
//   }
//
//   @override
//   // TODO: implement size
//   Vector2 get size => throw UnimplementedError();
//
//   @override
//   void stepEngine({double stepTime = 1 / 60}) {
//     // TODO: implement stepEngine
//   }
//
//   @override
//   FutureOr<void> toBeLoaded() {
//     // TODO: implement toBeLoaded
//     throw UnimplementedError();
//   }
//
//   @override
//   void unregisterKey(ComponentKey key) {
//     // TODO: implement unregisterKey
//   }
//
//   @override
//   void update(double dt) {
//     // TODO: implement update
//   }
//
//   @override
//   void updateTree(double dt) {
//     // TODO: implement updateTree
//   }
// }

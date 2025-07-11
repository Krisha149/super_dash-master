import 'dart:ui';

import 'package:tiled/tiled.dart';

/// A configurable class that allows the developer to
/// customize different options that Leap will use
/// when reading the map.
class LeapConfiguration {
  const LeapConfiguration({
    this.tiled = const TiledOptions(),
  });

  /// The tiled options, change it to configure how Leap
  /// interpret the tiled map.
  final TiledOptions tiled;
}

/// A configurable class specifically about Tiled names, classes and etc.
class TiledOptions {
  const TiledOptions({
    this.groundLayerName = 'Ground',
    this.metadataLayerName = 'Metadata',
    this.playerSpawnClass = 'PlayerSpawn',
    this.hazardClass = 'Hazard',
    this.damageProperty = 'Damage',
    this.platformClass = 'Platform',
    this.slopeType = 'Slope',
    this.slopeRightTopProperty = 'RightTop',
    this.slopeLeftTopProperty = 'LeftTop',
    this.atlasMaxX,
    this.atlasMaxY,
    this.tsxPackingFilter,
    this.layerPaintFactory,
    this.atlasPackingSpacingX = 0,
    this.atlasPackingSpacingY = 0,
  });

  final String groundLayerName;
  final String metadataLayerName;
  final String playerSpawnClass;
  final String hazardClass;
  final String damageProperty;
  final String platformClass;
  final String slopeType;
  final String slopeRightTopProperty;
  final String slopeLeftTopProperty;

  final double? atlasMaxX;
  final double? atlasMaxY;

  /// Add these missing fields
  final bool Function(Tileset)? tsxPackingFilter;
  final Paint Function(double opacity)? layerPaintFactory;
  final double atlasPackingSpacingX;
  final double atlasPackingSpacingY;
}

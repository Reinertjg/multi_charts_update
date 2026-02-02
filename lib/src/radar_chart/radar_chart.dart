import 'package:flutter/material.dart';

import 'utils/painters/radar_chart_painter.dart';

/// A dataset to be plotted on the radar chart.
///
/// Each dataset is rendered as a polygon with its own fill color and tick color.
/// The [values] list must contain at least 3 values, and every value must be
/// less than or equal to the chart's [RadarChartGraphic.maxValue].
class DataSet {
  /// Creates a dataset for the radar chart.
  DataSet({
    required this.fillColor,
    required this.tickColor,
    required this.values,
  });

  /// The fill color used to paint the dataset polygon area.
  final Color fillColor;

  /// The color used to paint the dataset tick marks / points.
  final Color tickColor;

  /// Data points for this dataset.
  ///
  /// Must contain at least 3 values.
  /// Each value must be <= the chart's [RadarChartGraphic.maxValue].
  List<double> values;
}

/// A radar (spider-web) chart widget.
///
/// A radar chart plots multiple dimensions as axes originating from a common
/// center and connects the values to form a polygon.
///
/// ## Data
/// Provide one or more [DataSet]s via [dataSets]. Each dataset will be plotted
/// on the same chart. The chart scale is defined by [maxValue].
///
/// ## Labels
/// If [labels] is provided, its length must match the number of values for
/// each dataset. If [labels] is not provided, the painter may fall back to
/// values as labels (implementation-dependent).
///
/// ## Sizing
/// The widget uses a [CustomPaint] canvas whose size defaults to [Size.infinite]
/// and is constrained by its parent. If no parent constraints are applied,
/// [maxWidth] and [maxHeight] can be used as upper bounds.
///
/// ## Animation
/// This widget supports one-shot animation through an event-style trigger:
/// [animationTrigger]. Each time [animationTrigger] changes, the chart can
/// replay its animation if [dataAnimation] and/or [outlineAnimation] are enabled.
///
/// This design avoids unintended replays during regular rebuilds, since rebuilds
/// alone do not change [animationTrigger].
class RadarChartGraphic extends StatefulWidget {
  /// Creates a radar chart.
  RadarChartGraphic({
    Key? key,
    required this.dataSets,
    this.labels,
    required this.maxValue,
    this.size = Size.infinite,
    this.strokeColor = Colors.black87,
    this.labelColor = Colors.black,
    this.labelStyle = const TextStyle(color: Colors.black),
    this.maxWidth = 200,
    this.maxHeight = 200,
    this.textScaleFactor = 0.04,
    this.labelWidth,
    this.maxLinesForLabels,
    this.dataAnimation = false,
    this.outlineAnimation = false,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.curve = Curves.easeIn,
    this.animationTrigger = 0,
    this.chartRadiusFactor = 0.8,
  }) : super(key: key);

  /// Datasets to be plotted on the chart.
  ///
  /// Each dataset must have at least 3 values. All values must be <= [maxValue].
  final List<DataSet> dataSets;

  /// Axis labels shown around the chart.
  ///
  /// When provided, the number of labels must match the number of values in
  /// each dataset.
  final List<String>? labels;

  /// The maximum value of the chart scale.
  ///
  /// All dataset values must be <= [maxValue]. The chart is rendered with
  /// concentric levels between 0 and [maxValue].
  final double maxValue;

  /// The size of the painting canvas.
  ///
  /// Defaults to [Size.infinite] and is constrained by the parent widget.
  final Size size;

  /// The color used to draw the chart outline and grid.
  ///
  /// Defaults to [Colors.black87].
  final Color strokeColor;

  /// The color used to draw the label text.
  ///
  /// Defaults to [Colors.black].
  final Color labelColor;

  /// The text style used for axis labels.
  ///
  /// Defaults to `TextStyle(color: Colors.black)`.
  final TextStyle labelStyle;

  /// Maximum width when no parent constraints are applied.
  ///
  /// If the parent provides constraints, this value is ignored.
  final double maxWidth;

  /// Maximum height when no parent constraints are applied.
  ///
  /// If the parent provides constraints, this value is ignored.
  final double maxHeight;

  /// Scales label text size relative to the available space.
  ///
  /// The effective label size is computed from the average of the parent width
  /// and height multiplied by this factor.
  ///
  /// Defaults to `0.04`.
  final double textScaleFactor;

  /// Maximum width for each label.
  ///
  /// If null, an internal heuristic may be used to determine label width.
  final double? labelWidth;

  /// Maximum number of lines allowed for each label.
  ///
  /// If null, a heuristic based on the container height may be used.
  final int? maxLinesForLabels;

  /// Whether to animate dataset polygons when [animationTrigger] changes.
  ///
  /// Defaults to `false`.
  final bool dataAnimation;

  /// Whether to animate the outline/grid when [animationTrigger] changes.
  ///
  /// Defaults to `false`.
  final bool outlineAnimation;

  /// The duration of the animation when enabled.
  ///
  /// Defaults to 1500ms.
  final Duration animationDuration;

  /// The animation curve used when animating.
  ///
  /// Defaults to [Curves.easeIn].
  final Curve curve;

  /// An event-style token that triggers a one-shot animation.
  ///
  /// Each time this value changes (e.g. you increment it), the widget will replay
  /// the animation if [dataAnimation] and/or [outlineAnimation] are enabled.
  ///
  /// This is intentionally an `int` so consumers can do:
  /// `setState(() => trigger++)` to emit a pulse.
  ///
  /// Defaults to `0`.
  final int animationTrigger;

  /// A factor applied to the chart radius relative to the smallest dimension.
  ///
  /// For example, `0.8` means the chart radius will be 80% of the available
  /// min(width, height). Defaults to `0.8`.
  final double chartRadiusFactor;

  @override
  State<RadarChartGraphic> createState() => _RadarChartGraphicState();
}

class _RadarChartGraphicState extends State<RadarChartGraphic>
    with TickerProviderStateMixin {
  late final AnimationController _dataAnimationController;
  late final AnimationController _outlineAnimationController;

  late Animation<double> _dataAnimation;
  late Animation<double> _outlineAnimation;

  double dataAnimationPercent = 0.0;
  double outlineAnimationPercent = 0.0;

  late Animation curve;

  @override
  void initState() {
    super.initState();

    // Validate input early to fail fast in development.
    for (final dataSet in widget.dataSets) {
      if (dataSet.values.any((v) => v > widget.maxValue)) {
        throw ArgumentError('All values must be <= maxValue.');
      }
      if (dataSet.values.length < 3) {
        throw ArgumentError('Radar charts require at least 3 values.');
      }
      if (widget.labels != null && dataSet.values.length != widget.labels!.length) {
        throw ArgumentError('Values and labels must have the same length.');
      }
    }

    _dataAnimationController = AnimationController(
      vsync: this,
      duration: widget.dataAnimation || widget.outlineAnimation
          ? widget.animationDuration
          : const Duration(milliseconds: 1),
    )..forward();

    _outlineAnimationController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.dataAnimation || widget.outlineAnimation ? 500 : 1,
      ),
    )..forward();

    curve = CurvedAnimation(parent: _dataAnimationController, curve: widget.curve);
  }

  @override
  void dispose() {
    _dataAnimationController.dispose();
    _outlineAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RadarChartGraphic oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Re-validate whenever configuration or data changes.
    for (final dataSet in widget.dataSets) {
      if (dataSet.values.any((v) => v > widget.maxValue)) {
        _dataAnimationController.reset();
        _outlineAnimationController.reset();
        throw ArgumentError('All values must be <= maxValue.');
      }
      if (dataSet.values.length < 3) {
        throw ArgumentError('Radar charts require at least 3 values.');
      }
      if (widget.labels != null && dataSet.values.length != widget.labels!.length) {
        throw ArgumentError('Values and labels must have the same length.');
      }
    }

    // Update animation configuration if needed.
    if (oldWidget.animationDuration != widget.animationDuration) {
      _dataAnimationController.duration = widget.animationDuration;
    }

    if (oldWidget.curve != widget.curve) {
      curve = CurvedAnimation(parent: _dataAnimationController, curve: widget.curve);
    }

    // Event-style pulse: replay animation only when the trigger changes.
    if (oldWidget.animationTrigger != widget.animationTrigger) {
      if (widget.dataAnimation) {
        _dataAnimationController
          ..reset()
          ..forward();
      }
      if (widget.outlineAnimation) {
        _outlineAnimationController
          ..reset()
          ..forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // NOTE:
    // Creating animations/listeners inside build can lead to duplicated listeners
    // across rebuilds. For a production-quality library implementation,
    // consider creating animations once in initState (or using AnimatedBuilder).
    _dataAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve as Animation<double>)
      ..addListener(() {
        setState(() => dataAnimationPercent = _dataAnimation.value);
      });

    _outlineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_outlineAnimationController)
      ..addListener(() {
        setState(() => outlineAnimationPercent = _outlineAnimation.value);
      });

    return LimitedBox(
      maxWidth: widget.maxWidth,
      maxHeight: widget.maxHeight,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CustomPaint(
          painter: RadarChartPainter(
            widget.dataSets,
            widget.labels,
            widget.maxValue,
            widget.strokeColor,
            widget.labelColor,
            widget.labelStyle,
            widget.textScaleFactor,
            widget.labelWidth,
            widget.maxLinesForLabels,
            widget.dataAnimation ? dataAnimationPercent : 1.0,
            widget.outlineAnimation ? outlineAnimationPercent : 1.0,
            widget.chartRadiusFactor,
          ),
          size: widget.size,
        ),
      ),
    );
  }
}

import 'dart:math' show cos, min, pi, sin;

import 'package:flutter/material.dart';

import '../../../common/common_paint_utils.dart';
import '../../radar_chart.dart';
import '../radar_chart_draw_utils.dart';

/// Custom Painter class for drawing the chart. Depends on various parameters like
/// [RadarChartGraphic.values], [RadarChartGraphic.labels], [RadarChartGraphic.maxValue], [RadarChartGraphic.fillColor],
/// [RadarChartGraphic.strokeColor], [RadarChartGraphic.legendTextColor], [RadarChartGraphic.textScaleFactor], [RadarChartGraphic.labelWidth],
/// [RadarChartGraphic.maxLinesForLabels], [RadarChartGraphic.chartRadiusFactor].
///
/// It also has [dataAnimationPercent] and [outlineAnimationPercent] which defines the
/// animation of the chart data and outlines.
class RadarChartPainter extends CustomPainter {
  final List<DataSet> dataSets;
  final List<String>? labels;
  final double maxValue;
  final Color strokeColor;
  final Color labelColor;
  final TextStyle labelStyle;
  final double textScaleFactor;
  final double? labelWidth;
  final int? maxLinesForLabels;
  final double dataAnimationPercent;
  final double outlineAnimationPercent;
  final double chartRadiusFactor;

  RadarChartPainter(
      this.dataSets,
      this.labels,
      this.maxValue,
      this.strokeColor,
      this.labelColor,
      this.labelStyle,
      this.textScaleFactor,
      this.labelWidth,
      this.maxLinesForLabels,
      this.dataAnimationPercent,
      this.outlineAnimationPercent,
      this.chartRadiusFactor);

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2.0, size.height / 2.0);
    double angle = (2 * pi) / dataSets[0].values.length;

    for (var dataSet in dataSets) {
      var valuePoints = <Offset>[];
      valuePoints = calcValuePoints(dataSet.values, center, angle);

      var outerPoints = RadarChartDrawUtils.drawChartOutline(
          canvas,
          center,
          angle,
          strokeColor,
          maxValue,
          dataSet.values.length,
          outlineAnimationPercent,
          (min(center.dx, center.dy) * chartRadiusFactor));
      RadarChartDrawUtils.drawFillPaintGraphData(
          canvas, valuePoints, dataSet.fillColor);
      RadarChartDrawUtils.drawLabels(
          canvas,
          center,
          labels ?? dataSet.values.map((v) => v.toString()).toList(),
          outerPoints,
          CommonPaintUtils.getTextSize(size, textScaleFactor),
          labelWidth ??
              CommonPaintUtils.getDefaultLabelWidth(size, center, angle),
          maxLinesForLabels ?? CommonPaintUtils.getDefaultMaxLinesForLabels(size),
          labelColor,
          labelStyle,
      );
    }

    for (var dataSet in dataSets) {
      var valuePoints = <Offset>[];
      valuePoints = calcValuePoints(dataSet.values, center, angle);

      RadarChartDrawUtils.drawStrokePaintGraphData(
          canvas, valuePoints, dataSet.tickColor);
    }

  }

  @override
  bool shouldRepaint(RadarChartPainter oldDelegate) {
    return oldDelegate.dataAnimationPercent != dataAnimationPercent;
  }

  List<Offset> calcValuePoints (List<double> values,  Offset center, double angle) {
    var valuePoints = <Offset>[];

    for (var i = 0; i < values.length; i++) {
      var radius = (values[i] / maxValue) *
          (min(center.dx, center.dy) * chartRadiusFactor);
      var x = dataAnimationPercent * radius * cos(angle * i - pi / 2);
      var y = dataAnimationPercent * radius * sin(angle * i - pi / 2);

      valuePoints.add(Offset(x, y) + center);
    }

    return valuePoints;
  }
}

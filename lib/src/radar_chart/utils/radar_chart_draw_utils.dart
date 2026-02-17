import 'dart:math' show cos, pi, sin;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../common/common_paint_utils.dart';


/// Helper class to draw the different radar chart elements.
class RadarChartDrawUtils {
  /// Draws the labels at the given offset positions at the outside of the graph.
  static void drawLabels(
      Canvas canvas,
      Offset center,
      List<String> labels,
      List<Offset> labelPoints,
      double textSize,
      double labelWidth,
      int maxLinesForLabels,
      Color labelColor,
      TextStyle? labelStyle) {
    var textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < labelPoints.length; i++) {
      textPainter.text = TextSpan(
          text: labels[i],
          style: labelStyle);
      textPainter.maxLines = maxLinesForLabels;
      textPainter.textAlign = TextAlign.center;

      textPainter.layout(maxWidth: labelWidth);
      //top-left
      if (labelPoints[i].dx < center.dx && labelPoints[i].dy < center.dy) {
        textPainter.paint(
            canvas,
            labelPoints[i].translate(
                -(textPainter.size.width + CommonPaintUtils.LABEL_X_PADDING),
                -CommonPaintUtils.LABEL_Y_PADDING));
      }
      //bottom-right
      else if (labelPoints[i].dx > center.dx && labelPoints[i].dy > center.dy) {
        textPainter.paint(
            canvas,
            labelPoints[i].translate(CommonPaintUtils.LABEL_X_PADDING,
                -CommonPaintUtils.LABEL_Y_PADDING / 2));
      }
      //top-right
      else if (labelPoints[i].dx > center.dx && labelPoints[i].dy < center.dy) {
        textPainter.paint(
            canvas,
            labelPoints[i].translate(CommonPaintUtils.LABEL_X_PADDING,
                -textPainter.size.height / 2));
      }
      //bottom-left
      else if (labelPoints[i].dx < center.dx && labelPoints[i].dy > center.dy) {
        textPainter.paint(
            canvas,
            labelPoints[i].translate(
                -(textPainter.size.width +
                    CommonPaintUtils.LABEL_X_PADDING / 2),
                -CommonPaintUtils.LABEL_Y_PADDING / 2));
      }
      //top-center
      else if (labelPoints[i].dx == center.dx &&
          labelPoints[i].dy < center.dy) {
        textPainter.paint(
            canvas,
            labelPoints[i].translate(
                -(textPainter.size.width / 2),
                -(textPainter.size.height +
                    CommonPaintUtils.LABEL_Y_PADDING / 2)));
      }
      //bottom-center
      else if (labelPoints[i].dx == center.dx &&
          labelPoints[i].dy > center.dy) {
        textPainter.paint(
            canvas,
            labelPoints[i].translate(-(textPainter.size.width / 2),
                CommonPaintUtils.LABEL_Y_PADDING));
      }
      //right-center
      else if (labelPoints[i].dx > center.dx &&
          labelPoints[i].dy == center.dy) {
        textPainter.paint(
            canvas,
            labelPoints[i].translate(CommonPaintUtils.LABEL_X_PADDING,
                -(textPainter.size.height / 2)));
      }
      //left-center
      else if (labelPoints[i].dx < center.dx &&
          labelPoints[i].dy == center.dy) {
        textPainter.paint(
            canvas,
            labelPoints[i].translate(
                -(textPainter.size.width + CommonPaintUtils.LABEL_X_PADDING),
                -(textPainter.size.height / 2)));
      }
    }
  }

  /// Draws the outlines of the chart based on the [RadarChart.maxValue].
  static List<Offset> drawChartOutline(
      Canvas canvas,
      Offset center,
      double angle,
      Color strokeColor,
      double maxValue,
      int noOfPoints,
      double animationPercent,
      double chartRadius,
      ) {
    // Prevents division by zero and invalid drawing
    if (maxValue <= 0) return <Offset>[];

    final int rings = maxValue.clamp(1, 10).floor();

    final boundaryPoints = <Offset>[];
    final outerPoints = <Offset>[];

    // Iterates through each ring of the radar chart
    for (int ring = 0; ring <= rings; ring++) {
      boundaryPoints.clear();

      // Calculates the radial scale for the current ring
      // ring = 0 represents the outermost ring
      // ring = rings represents the innermost ring
      final double progress = ring / rings;
      final double scale = 1.0 - progress;

      // Iterates through each axis (point) of the radar
      for (int pointIndex = 0; pointIndex < noOfPoints; pointIndex++) {
        // Computes X and Y coordinates based on angle and scale
        final double x = animationPercent *
            chartRadius *
            scale *
            cos(angle * pointIndex - pi / 2);

        final double y = animationPercent *
            chartRadius *
            scale *
            sin(angle * pointIndex - pi / 2);

        final Offset point = Offset(x, y) + center;
        boundaryPoints.add(point);

        // Stores the outermost ring points for label positioning
        if (ring == 0) outerPoints.add(point);

        // Draws radial lines from the center to each point
        canvas.drawLine(
          center,
          point,
          CommonPaintUtils.getStrokePaint(strokeColor, 150, 0.3),
        );
      }

      // Closes the polygon by connecting the last point to the first
      boundaryPoints.add(boundaryPoints.first);

      // Draws the polygon outline for the current ring
      canvas.drawPoints(
        PointMode.polygon,
        boundaryPoints,
        CommonPaintUtils.getStrokePaint(strokeColor, 150, 0.8),
      );
    }

    // Draws the center dot of the radar chart
    canvas.drawCircle(
      center,
      2.0,
      CommonPaintUtils.getFillPaint(strokeColor, alpha: 50),
    );

    return outerPoints;
  }



  /// Draws the graph data for all the value points with the background color defined by
  /// [RadarChart.fillColor].
  static void drawGraphData(Canvas canvas, List<Offset> valuePoints,
      Color fillColor, Color tickColor) {
    final Path valuePath = Path()..addPolygon(valuePoints, true);

    canvas.drawPath(
      valuePath,
      CommonPaintUtils.getFillPaint(fillColor, alpha: 100),
    );

    canvas.drawPath(
      valuePath,
      CommonPaintUtils.getStrokePaint(tickColor, 255, 1.75),
    );
  }

  static void drawStrokePaintGraphData(Canvas canvas, List<Offset> valuePoints, Color tickColor) {
    final Path valuePath = Path()..addPolygon(valuePoints, true);

    canvas.drawPath(
      valuePath,
      CommonPaintUtils.getStrokePaint(tickColor, 255, 1.75),
    );
  }
  static void drawFillPaintGraphData(Canvas canvas, List<Offset> valuePoints, Color fillColor) {
    final Path valuePath = Path()..addPolygon(valuePoints, true);

    canvas.drawPath(
      valuePath,
      CommonPaintUtils.getFillPaint(fillColor, alpha: 100),
    );
  }
}

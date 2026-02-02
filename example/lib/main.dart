import 'package:flutter/material.dart';
import 'package:multi_charts/multi_charts.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radar Chart Trigger Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RadarChartTestPage(),
    );
  }
}

class RadarChartTestPage extends StatefulWidget {
  const RadarChartTestPage();

  @override
  State<RadarChartTestPage> createState() => _RadarChartTestPageState();
}

class _RadarChartTestPageState extends State<RadarChartTestPage> {
  /// A rebuild counter just to prove that rebuilding the widget tree
  /// should NOT retrigger the animation when using `animationTrigger`.
  int rebuildCounter = 0;

  /// This is the "event token". Each increment is a pulse.
  int radarTrigger = 0;

  /// Current chart values (must have at least 3 points).
  List<double> values = const [1, 2, 4, 7, 9, 0, 6];

  /// A second dataset to switch to, so we can visually confirm updates.
  static const List<double> _altValues = [5, 6, 7, 8, 0, 3, 3];

  /// Triggers a single animation pulse AND updates the chart data.
  /// Note: using two separate setState calls is unnecessary; we update both at once.
  void pulse() {
    setState(() {
      radarTrigger++;

      // Toggle between two value sets to confirm the chart is actually updating.
      final isUsingAlt = _listEquals(values, _altValues);
      values = isUsingAlt ? const [1, 2, 4, 7, 9, 0, 6] : _altValues;

      rebuildCounter++;
    });
  }

  /// Forces a rebuild without changing the trigger or the data.
  /// If the trigger implementation is correct, this should NOT animate again.
  void forceRebuild() {
    setState(() => rebuildCounter++);
  }

  /// Resets trigger and data to initial state.
  void reset() {
    setState(() {
      radarTrigger = 0;
      values = const [1, 2, 4, 7, 9, 0, 6];
      rebuildCounter = 0;
    });
  }

  /// Lightweight list equality (same length + same elements).
  bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Radar Chart Trigger Demo')),
      body: Column(
        children: [
          const SizedBox(height: 12),

          /// Debug info to confirm the trigger is changing only on pulses.
          Text(
            'trigger=$radarTrigger | rebuilds=$rebuildCounter | values=${values.join(", ")}',
            style: const TextStyle(fontSize: 13),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          /// Controls: Pulse / Force rebuild / Reset
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: pulse,
                child: const Text('Pulse (trigger++)'),
              ),
              OutlinedButton(
                onPressed: forceRebuild,
                child: const Text('Force rebuild'),
              ),
              TextButton(
                onPressed: reset,
                child: const Text('Reset'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: Center(
              child: Container(
                width: 450,
                height: 450,
                padding: const EdgeInsets.all(8),

                /// The chart itself
                child: RadarChartGraphic(
                  dataSets: [
                    DataSet(
                      fillColor: Colors.blue,
                      tickColor: Colors.blue,
                      values: values,
                    ),
                  ],
                  labels: const [
                    'Label1',
                    'Label2',
                    'Label3',
                    'Label4',
                    'Label5',
                    'Label6',
                    'Label7',
                  ],
                  labelStyle: const TextStyle(fontSize: 14),
                  maxValue: 10,
                  chartRadiusFactor: 0.7,

                  /// ✅ Trigger-based animation: only animates when this integer changes.
                  animationTrigger: radarTrigger,

                  /// Whether the chart should animate when a trigger arrives.
                  dataAnimation: true,
                  outlineAnimation: false,

                  /// Faster animation for testing.
                  animationDuration: const Duration(milliseconds: 500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

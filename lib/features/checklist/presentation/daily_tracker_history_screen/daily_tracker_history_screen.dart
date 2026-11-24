import 'package:flutter/material.dart';
import '../../data/models/daily_model.dart';

class DailyTrackerHistoryScreen extends StatefulWidget {
  final DailySubject subject;

  const DailyTrackerHistoryScreen({
    super.key,
    required this.subject,
  });

  @override
  State<DailyTrackerHistoryScreen> createState() => _DailyTrackerHistoryScreenState();
}

class _DailyTrackerHistoryScreenState extends State<DailyTrackerHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.subjectName),
      ),
      body: const Center(
        child: Text('History Screen'),
      ),
    );
  }
}

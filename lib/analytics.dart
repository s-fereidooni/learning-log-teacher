import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherAnalyticsPage extends StatefulWidget {
  const TeacherAnalyticsPage({Key? key}) : super(key: key);

  @override
  _TeacherAnalyticsPageState createState() => _TeacherAnalyticsPageState();
}

class _TeacherAnalyticsPageState extends State<TeacherAnalyticsPage> {
  late Future<Map<String, dynamic>> _analyticsData;

  @override
  void initState() {
    super.initState();
    _analyticsData = _fetchAnalyticsData();
  }

  Future<Map<String, dynamic>> _fetchAnalyticsData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? teacherId = prefs.getString('teacherId');
    if (teacherId == null) return {};

    QuerySnapshot studentDocs = await FirebaseFirestore.instance
        .collection('student_codes')
        .where('teacherId', isEqualTo: teacherId)
        .get();

    int totalSessions = 0;
    int totalStudyTime = 0;
    int totalRatings = 0;
    int ratingCount = 0;
    Map<String, int> studyMethodCounts = {};
    Map<String, int> sessionsPerDay = {};

    for (var studentDoc in studentDocs.docs) {
      QuerySnapshot studySessions = await studentDoc.reference
          .collection('study_sessions')
          .orderBy('timestamp', descending: false)
          .get();

      for (var session in studySessions.docs) {
        totalSessions++;
        totalStudyTime += ((session['actual_study_time'] ?? 0) as num).toInt();
        if (session['rating'] != null) {
          totalRatings += (session['rating'] as num).toInt();
          ratingCount++;
        }

        List<dynamic> methodsUsed = session['study_methods_used'] ?? [];
        for (var method in methodsUsed) {
          studyMethodCounts[method] = (studyMethodCounts[method] ?? 0) + 1;
        }

        DateTime sessionDate = (session['timestamp'] as Timestamp).toDate();
        String dateKey = "${sessionDate.year}-${sessionDate.month}-${sessionDate.day}";
        sessionsPerDay[dateKey] = (sessionsPerDay[dateKey] ?? 0) + 1;
      }
    }

    return {
      'totalSessions': totalSessions,
      'averageStudyTime': totalSessions > 0 ? (totalStudyTime / totalSessions) : 0,
      'averageRating': ratingCount > 0 ? (totalRatings / ratingCount) : 0,
      'studyMethodCounts': studyMethodCounts,
      'sessionsPerDay': sessionsPerDay,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Study Analytics'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _analyticsData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available.'));
          }

          final data = snapshot.data!;
          final studyMethods = data['studyMethodCounts'] as Map<String, int>;
          final sessionsPerDay = data['sessionsPerDay'] as Map<String, int>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatCard('Total Study Sessions', data['totalSessions'].toString()),
              _buildStatCard('Avg Study Time', '${data['averageStudyTime'].toStringAsFixed(2)} min'),
              _buildStatCard('Avg Rating', '${data['averageRating'].toStringAsFixed(1)} / 5'),
              _buildStudyMethodsChart(studyMethods),
              _buildStudyTrendsChart(sessionsPerDay),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(value, style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _buildStudyMethodsChart(Map<String, int> studyMethods) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Most Used Study Methods', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: studyMethods.entries.map((entry) {
                  return BarChartGroupData(
                    x: studyMethods.keys.toList().indexOf(entry.key),
                    barRods: [BarChartRodData(toY: entry.value.toDouble(), width: 15)],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyTrendsChart(Map<String, int> sessionsPerDay) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Study Trends Over Time', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: sessionsPerDay.entries.map((entry) {
                      return FlSpot(sessionsPerDay.keys.toList().indexOf(entry.key).toDouble(), entry.value.toDouble());
                    }).toList(),
                    isCurved: true,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

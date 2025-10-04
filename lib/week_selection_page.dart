import 'package:flutter/material.dart';
import 'questions_management_page.dart'; // Import the questions management page

class WeekSelectionPage extends StatelessWidget {
  const WeekSelectionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Practice Questions'),
      ),
      body: ListView.builder(
        itemCount: 10, // There are 10 weeks
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Week ${index + 1}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      QuestionsManagementPage(weekNumber: index + 1),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

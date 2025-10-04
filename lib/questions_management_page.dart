import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionsManagementPage extends StatefulWidget {
  final int weekNumber;

  const QuestionsManagementPage({Key? key, required this.weekNumber})
      : super(key: key);

  @override
  _QuestionsManagementPageState createState() =>
      _QuestionsManagementPageState();
}

class _QuestionsManagementPageState extends State<QuestionsManagementPage> {
  final TextEditingController _questionController = TextEditingController();

  // Function to add a new question
  Future<void> _addQuestion() async {
    if (_questionController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('week_questions')
          .doc('week${widget.weekNumber}')
          .collection('questions')
          .add({
        'question': _questionController.text,
      });

      _questionController.clear();
    }
  }

  // Function to delete a question
  Future<void> _deleteQuestion(String questionId) async {
    await FirebaseFirestore.instance
        .collection('week_questions')
        .doc('week${widget.weekNumber}')
        .collection('questions')
        .doc(questionId)
        .delete();
  }

  // Function to edit a question
  Future<void> _editQuestion(String questionId, String updatedQuestion) async {
    await FirebaseFirestore.instance
        .collection('week_questions')
        .doc('week${widget.weekNumber}')
        .collection('questions')
        .doc(questionId)
        .update({
      'question': updatedQuestion,
    });
  }

  // Show a dialog for editing a question
  Future<void> _showEditDialog(
      String questionId, String currentQuestion) async {
    final TextEditingController _editController = TextEditingController();
    _editController.text = currentQuestion;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Question'),
          content: TextField(
            controller: _editController,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _editQuestion(questionId, _editController.text);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Week ${widget.weekNumber} - Manage Questions'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('week_questions')
                  .doc('week${widget.weekNumber}')
                  .collection('questions')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final questions = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];

                    return ListTile(
                      title: Text(question['question']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _showEditDialog(
                                  question.id, question['question']);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              _deleteQuestion(question.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: const InputDecoration(
                      labelText: 'Add a new question',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addQuestion,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

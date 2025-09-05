// lib/quick_find_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuickFindPage extends StatelessWidget {
  const QuickFindPage({super.key});

  Stream<QuerySnapshot> _employeeStream() {
    return FirebaseFirestore.instance
        .collection('userlog')
        .where('accountType', isEqualTo: 'Employee')
        .orderBy('createdAt', descending: true) // optional
        .snapshots();
  }

  String _timestampToString(dynamic t) {
    try {
      if (t == null) return '';
      if (t is Timestamp) return t.toDate().toString();
      if (t is String) return t;
      return t.toString();
    } catch (e) {
      return t.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Find'),
        backgroundColor: Colors.purple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _employeeStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No employees found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final firstName = data['firstName'] ?? '';
              final lastName = data['lastName'] ?? '';
              final city = data['city'] ?? '';
              final district = data['district'] ?? '';
              final contactNumber = data['contactNumber'] ?? '';
              final rating = (data['rating'] ?? 0).toString();
              final ratedCount = (data['ratedCount'] ?? 0).toString();
              final serviceLocation = data['serviceLocation'] ?? '';
              final createdAt = _timestampToString(data['createdAt']);

              // skills can be a List of maps
              List<Widget> skillWidgets = [];
              if (data['skills'] is List) {
                for (var s in List.from(data['skills'])) {
                  if (s is Map) {
                    final skill = s['skill'] ?? '';
                    final exp = s['experience'] ?? '';
                    skillWidgets.add(Text('$skill • $exp'));
                  }
                }
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(child: Icon(Icons.person)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$firstName $lastName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('$city, $district'),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('⭐ $rating', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('($ratedCount)'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (contactNumber != '') Text('Contact: $contactNumber'),
                      if (serviceLocation != '') Text('Location coords: $serviceLocation'),
                      if (createdAt != '') Text('Joined: $createdAt'),
                      if (skillWidgets.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Skills:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...skillWidgets,
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

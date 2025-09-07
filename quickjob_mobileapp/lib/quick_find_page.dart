import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickFindPage extends StatefulWidget {
  const QuickFindPage({super.key});

  @override
  State<QuickFindPage> createState() => _QuickFindPageState();
}

class _QuickFindPageState extends State<QuickFindPage> {
  String nameFilter = '';
  String districtFilter = '';
  String skillFilter = '';
  List<String> allDistricts = [];
  List<String> allSkills = [];

  @override
  void initState() {
    super.initState();
    // Try to fetch master district list from Firestore 'map' collection (as documents)
    FirebaseFirestore.instance
        .collection('map')
        .get()
        .then((snapshot) {
      final districts = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['district'] != null && data['district'].toString().isNotEmpty) {
          districts.add(data['district'].toString());
        }
        // If using a list field, also check for 'districts' array
        if (data['districts'] is List) {
          for (var d in List.from(data['districts'])) {
            if (d != null && d.toString().isNotEmpty) {
              districts.add(d.toString());
            }
          }
        }
      }
      // Fallback: if no districts found, use userlog
      if (districts.isEmpty) {
        FirebaseFirestore.instance
            .collection('userlog')
            .where('accountType', isEqualTo: 'Employee')
            .get()
            .then((snapshot) {
          final fallbackDistricts = <String>{};
          for (var doc in snapshot.docs) {
            final data = doc.data();
            if (data['district'] != null && data['district'].toString().isNotEmpty) {
              fallbackDistricts.add(data['district'].toString());
            }
          }
          setState(() {
            allDistricts = fallbackDistricts.toList();
          });
        });
      } else {
        setState(() {
          allDistricts = districts.toList();
        });
      }
    });

    // Fetch master job category list from Firestore 'jobcategory' collection
    FirebaseFirestore.instance
        .collection('jobcategory')
        .get()
        .then((snapshot) {
      final skills = <String>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['name'] != null && data['name'].toString().isNotEmpty) {
          skills.add(data['name'].toString());
        }
      }
      setState(() {
        allSkills = skills;
      });
    });
  }

  Stream<QuerySnapshot> _employeeStream() {
    return FirebaseFirestore.instance
        .collection('userlog')
        .where('accountType', isEqualTo: 'Employee')
        .orderBy('createdAt', descending: true)
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

  Future<void> _callNumber(String number) async {
    final Uri url = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  bool _matchesFilters(Map<String, dynamic> data) {
    final name =
        ((data['firstName'] ?? '') + ' ' + (data['lastName'] ?? '')).toLowerCase();
    final district = (data['district'] ?? '').toString();
    final skills = (data['skills'] is List)
        ? List.from(data['skills'])
            .map((s) => s is Map ? (s['skill'] ?? '').toString() : '')
            .toList()
        : <String>[];
    bool matches = true;
    if (nameFilter.isNotEmpty) {
      matches &= name.contains(nameFilter.toLowerCase());
    }
    if (districtFilter.isNotEmpty) {
      matches &= district == districtFilter;
    }
    if (skillFilter.isNotEmpty) {
      matches &= skills.contains(skillFilter);
    }
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/background.png',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.6)),
          Column(
            children: [
              // AppBar section
              AppBar(
                backgroundColor: Colors.black.withOpacity(0.7),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    const Text('Quick Find',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                    const Spacer(),
                    Image.asset('assets/logo.png', height: 36),
                  ],
                ),
              ),

              // Filters go here
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24, width: 0.5),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Filter by Name',
                          hintStyle: TextStyle(color: Colors.white70, fontSize: 12),
                          fillColor: Colors.transparent,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white24, width: 0.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        ),
                        controller: TextEditingController(text: nameFilter.isEmpty ? '' : nameFilter),
                        onChanged: (val) => setState(() => nameFilter = val),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        dropdownColor: Colors.black.withOpacity(0.8),
                        value: districtFilter.isEmpty ? '' : districtFilter,
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('All Districts', style: TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          ...allDistricts.map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(
                              d,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                        ],
                        onChanged: (val) => setState(() => districtFilter = val ?? ''),
                        decoration: InputDecoration(
                          fillColor: Colors.transparent,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white24, width: 0.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        dropdownColor: Colors.black.withOpacity(0.8),
                        value: skillFilter.isEmpty ? '' : skillFilter,
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('All Skills', style: TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          ...allSkills.map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                        ],
                        onChanged: (val) => setState(() => skillFilter = val ?? ''),
                        decoration: InputDecoration(
                          fillColor: Colors.transparent,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white24, width: 0.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              // Employee list
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _employeeStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.white)));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    final filteredDocs = docs
                        .where((doc) =>
                            _matchesFilters(doc.data() as Map<String, dynamic>))
                        .toList();
                    if (filteredDocs.isEmpty) {
                      return const Center(
                          child: Text('No employees found.',
                              style: TextStyle(color: Colors.white)));
                    }

                    return ListView.builder(
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final firstName = data['firstName'] ?? '';
                        final lastName = data['lastName'] ?? '';
                        final city = data['city'] ?? '';
                        final district = data['district'] ?? '';
                        final contactNumber = data['contactNumber'] ?? '';
                        final rating = (data['rating'] ?? 0).toString();
                        final ratedCount = (data['ratedCount'] ?? 0).toString();
                        final createdAt =
                            _timestampToString(data['createdAt']);
                        final serviceLocation =
                            data['serviceLocation']?.toString();

                        List<Widget> skillWidgets = [];
                        if (data['skills'] is List) {
                          for (var s in List.from(data['skills'])) {
                            if (s is Map) {
                              final skill = s['skill'] ?? '';
                              final exp = s['experience'] ?? '';
                              skillWidgets.add(
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: Colors.purpleAccent, size: 18),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(skill,
                                            style: const TextStyle(
                                                color: Colors.purpleAccent,
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Experience: ',
                                          style:
                                              TextStyle(color: Colors.white70),
                                          overflow: TextOverflow.ellipsis),
                                      Text(exp,
                                          style: const TextStyle(
                                              color: Colors.lightBlueAccent,
                                              fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              );
                            }
                          }
                        }

                        return Card(
                          color: Colors.black.withOpacity(0.7),
                          elevation: 8,
                          margin: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('$firstName $lastName',
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Text('District: ',
                                                  style: TextStyle(
                                                      color: Colors.white70)),
                                              Text(district,
                                                  style: const TextStyle(
                                                      color: Colors.greenAccent,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              const SizedBox(width: 12),
                                              const Text('City: ',
                                                  style: TextStyle(
                                                      color: Colors.white70)),
                                              Text(city,
                                                  style: const TextStyle(
                                                      color: Colors.greenAccent,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.star,
                                                color: Colors.amber, size: 20),
                                            Text(rating,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.amber,
                                                    fontSize: 16)),
                                          ],
                                        ),
                                        Text('($ratedCount ratings)',
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (contactNumber != '')
                                  Row(
                                    children: [
                                      const Icon(Icons.phone,
                                          color: Colors.lightGreenAccent,
                                          size: 18),
                                      const SizedBox(width: 6),
                                      Text(contactNumber,
                                          style: const TextStyle(
                                              color: Colors.white)),
                                    ],
                                  ),
                                if (createdAt != '')
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          color: Colors.blueAccent, size: 18),
                                      const SizedBox(width: 6),
                                      const Text('Joined: ',
                                          style:
                                              TextStyle(color: Colors.white70)),
                                      Text(createdAt.split(' ').first,
                                          style: const TextStyle(
                                              color: Colors.white)),
                                    ],
                                  ),
                                if (skillWidgets.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  const Text('Skills & Experience',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 16)),
                                  ...skillWidgets,
                                ],
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                        icon: const Icon(Icons.person_add),
                                        label: const Text('Hire Now',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (dialogContext) {
                                              return Dialog(
                                                backgroundColor:
                                                    Colors.black.withOpacity(
                                                        0.95),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            24)),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      horizontal: 24,
                                                      vertical: 28),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          const Text(
                                                              'Contact Employee',
                                                              style: TextStyle(
                                                                  fontSize: 22,
                                                                  fontWeight:
                                                                      FontWeight.bold,
                                                                  color: Colors.purpleAccent)),
                                                          IconButton(
                                                            icon: const Icon(
                                                                Icons.close,
                                                                color: Colors.white70),
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                        context)
                                                                    .pop(),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                          height: 18),
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.black
                                                              .withOpacity(0.7),
                                                          borderRadius:
                                                              BorderRadius.circular(16),
                                                          border: Border.all(
                                                              color: Colors.white12),
                                                        ),
                                                        padding: const EdgeInsets.all(18),
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              decoration: BoxDecoration(
                                                                color: Colors.purpleAccent,
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                              padding: const EdgeInsets.all(8),
                                                              child: const Icon(Icons.phone,
                                                                  color: Colors.white,
                                                                  size: 28),
                                                            ),
                                                            const SizedBox(width: 16),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text('$firstName',
                                                                      style: const TextStyle(
                                                                          fontSize: 18,
                                                                          fontWeight: FontWeight.bold,
                                                                          color: Colors.white)),
                                                                  const Text(
                                                                      'Professional Service Provider',
                                                                      style: TextStyle(
                                                                          color: Colors.white70)),
                                                                  const SizedBox(height: 12),
                                                                  const Text('Contact Number:',
                                                                      style: TextStyle(
                                                                          color: Colors.white70)),
                                                                  Text(contactNumber,
                                                                      style: const TextStyle(
                                                                          color: Colors.greenAccent,
                                                                          fontSize: 18,
                                                                          fontWeight: FontWeight.bold)),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 18),
                                                      Center(
                                                        child: Text(
                                                            'Call or message $firstName to discuss your requirements',
                                                            style: const TextStyle(
                                                                color: Colors.white70),
                                                            textAlign: TextAlign.center),
                                                      ),
                                                      const SizedBox(height: 18),
                                                      SizedBox(
                                                        width: double.infinity,
                                                        child: ElevatedButton.icon(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.green,
                                                            foregroundColor: Colors.white,
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(10)),
                                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                                          ),
                                                          icon: const Icon(Icons.call),
                                                          label: const Text('Call Now',
                                                              style: TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 18)),
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                            _callNumber(contactNumber);
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                        icon: const Icon(Icons.directions),
                                        label: const Text('Get Directions',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis),
                                        onPressed: () async {
                                          String urlStr = "";
                                          if (serviceLocation != null &&
                                              serviceLocation
                                                  .trim()
                                                  .isNotEmpty) {
                                            final coords =
                                                serviceLocation.split(',');
                                            if (coords.length == 2) {
                                              final lat = coords[0].trim();
                                              final lng = coords[1].trim();
                                              urlStr =
                                                  "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
                                            }
                                          } else {
                                            String query = "";
                                            if (city.isNotEmpty &&
                                                district.isNotEmpty) {
                                              query = "$district, $city";
                                            } else if (city.isNotEmpty) {
                                              query = city;
                                            } else if (district.isNotEmpty) {
                                              query = district;
                                            }
                                            if (query.isNotEmpty) {
                                              urlStr =
                                                  "https://www.google.com/maps/search/?api=1&query=$query";
                                            }
                                          }
                                          if (urlStr.isNotEmpty) {
                                            final Uri url = Uri.parse(urlStr);
                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(url,
                                                  mode: LaunchMode.externalApplication);
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

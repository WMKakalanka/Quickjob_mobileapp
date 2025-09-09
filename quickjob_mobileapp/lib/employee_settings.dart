// employee_settings.dart
// - Employee account settings screen.
// - Reads/writes the `userlog` document for the authenticated user.
// - Features:
//   * Editable first/last name and email (email is read-only; sourced from auth)
//   * District -> City dynamic dropdowns loaded from `map` collection
//   * Dynamic skills list (add/remove) stored as array of maps in `userlog`
//   * Get Location uses Geolocator to save coordinates as "lat,lng" to `serviceLocation`
//   * Save validation and merge-write to Firestore
// Notes:
// - Geolocator requires native permissions (AndroidManifest / Info.plist). Use flutter clean + full restart after adding the plugin.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'employee.dart';

class EmployeeSettingsPage extends StatefulWidget {
  const EmployeeSettingsPage({Key? key}) : super(key: key);

  @override
  _EmployeeSettingsPageState createState() => _EmployeeSettingsPageState();
}

class _EmployeeSettingsPageState extends State<EmployeeSettingsPage> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _serviceLocationCtrl = TextEditingController();
  final _contactNumberCtrl = TextEditingController();

  String? _district;
  String? _city;
  bool _saving = false;
  double _rating = 0.0;

  final List<String> _districts = ['Select District'];
  List<String> _cities = ['Select district first'];
  final Map<String, List<String>> _citiesByDistrict = {};
  final List<String> _skills = [
    'Select Skill',
    'Painter - Vehicle',
    'Carpenter',
    'Driving',
    'Plumber',
    'Helper',
    'Electrician - Vehicle',
    'Photography',
    'Electrician',
    'Cook',
    'Mechanic',
    'Builder'
  ];
  // dynamic list of chosen skills (each entry: { 'skill': String, 'experience': String })
  final List<Map<String, String>> _skillsList = [];
  final Color _fieldFillColor = Colors.white12;

  @override
  void initState() {
    super.initState();
    _district = _districts.first;
    _city = _cities.first;
    _loadMapAndUser();
  }

  Future<void> _loadMapAndUser() async {
    try {
      // load districts and cities from 'map' collection
      final mapSnap = await FirebaseFirestore.instance.collection('map').get();
      final districts = <String>[];
      for (final d in mapSnap.docs) {
        final data = d.data();
        final name = (data['districtName'] ?? data['name'] ?? d.id).toString();
        districts.add(name);
        final cities = <String>[];
        if (data['cities'] is Iterable) {
          for (final c in (data['cities'] as Iterable)) {
            cities.add(c.toString());
          }
        }
        _citiesByDistrict[name] = cities.isNotEmpty ? cities : ['Select district first'];
      }
      setState(() {
        _districts.clear();
        _districts.add('Select District');
        _districts.addAll(districts);
      });

      // load userlog for current user (prefill form)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _emailCtrl.text = user.email ?? '';
        final doc = await FirebaseFirestore.instance.collection('userlog').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
              // load rating if present
              if (data['rating'] != null) {
                final r = data['rating'];
                if (r is num) {
                  _rating = r.toDouble();
                } else {
                  _rating = double.tryParse(r.toString()) ?? 0.0;
                }
              }
          if (data['firstName'] != null) _firstCtrl.text = data['firstName'].toString();
          if (data['lastName'] != null) _lastCtrl.text = data['lastName'].toString();
          if (data['district'] != null) {
            final d = data['district'].toString();
            if (_districts.contains(d)) {
              _district = d;
              _cities = List<String>.from(_citiesByDistrict[d] ?? ['Select district first']);
            }
          }
          if (data['city'] != null) _city = data['city'].toString();
          if (data['serviceLocation'] != null) _serviceLocationCtrl.text = data['serviceLocation'].toString();
          if (data['contactNumber'] != null) _contactNumberCtrl.text = data['contactNumber'].toString();
          // load skills array if present
          if (data['skills'] is Iterable) {
            _skillsList.clear();
            for (final s in (data['skills'] as Iterable)) {
              if (s is Map) {
                _skillsList.add({
                  'skill': s['skill']?.toString() ?? _skills.first,
                  'experience': s['experience']?.toString() ?? ''
                });
              }
            }
          }
        }
      }
  // if user had no skills saved, leave the list empty; user can add skills
      setState(() {});
    } catch (e) {
      // ignore load errors silently
    }
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _serviceLocationCtrl.dispose();
    _contactNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _onGetLocation() async {
    // Use Geolocator to request permission and get current position.
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Location services are disabled.'),
          action: SnackBarAction(
            label: 'Open settings',
            onPressed: () async {
              // try to open location settings
              try {
                await Geolocator.openLocationSettings();
              } catch (_) {}
            },
          ),
        ));
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Location permissions are permanently denied.'),
          action: SnackBarAction(
            label: 'App settings',
            onPressed: () async {
              try {
                await Geolocator.openAppSettings();
              } catch (_) {}
            },
          ),
        ));
      }
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final coords = '${pos.latitude.toStringAsFixed(8)},${pos.longitude.toStringAsFixed(8)}';
      setState(() => _serviceLocationCtrl.text = coords);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('userlog').doc(user.uid).set({'serviceLocation': coords}, SetOptions(merge: true));
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location saved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get location: ${e.toString()}')));
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // Validate required fields
      final first = _firstCtrl.text.trim();
      final last = _lastCtrl.text.trim();
      final serviceLoc = _serviceLocationCtrl.text.trim();
      final contact = _contactNumberCtrl.text.trim();
      final districtOk = _district != null && _district != 'Select District';
      final cityOk = _city != null && _city != 'Select district first' && _city!.isNotEmpty;

      var skillsOk = _skillsList.isNotEmpty;
      for (final e in _skillsList) {
        if ((e['skill'] == null || e['skill'] == '' || e['skill'] == 'Select Skill') || (e['experience'] == null || e['experience'] == '')) {
          skillsOk = false;
          break;
        }
      }

      if (first.isEmpty || last.isEmpty || !districtOk || !cityOk || !skillsOk || serviceLoc.isEmpty || contact.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all Fields..')));
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      final data = {
        'firstName': first,
        'lastName': last,
        'email': _emailCtrl.text.trim(),
        'district': _district,
        'city': _city,
        'serviceLocation': serviceLoc,
        'contactNumber': contact,
        'accountType': 'Employee',
        'updatedAt': FieldValue.serverTimestamp(),
        // skills as array of maps
        'skills': _skillsList.map((e) => {'skill': e['skill'], 'experience': e['experience']}).toList(),
      };

      if (user != null) {
        await FirebaseFirestore.instance.collection('userlog').doc(user.uid).set(data, SetOptions(merge: true));
      } else {
        await FirebaseFirestore.instance.collection('userlog').add(data);
      }

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
      // navigate back to dashboard
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade900, Colors.purple.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Card(
                color: Colors.black.withOpacity(0.45),
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.82),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                                  onPressed: () {
                                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const EmployeePage()));
                                  },
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.settings, color: Colors.purple.shade100),
                                const SizedBox(width: 8),
                                const Text('Employee Account Settings', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                              ]),
                              const SizedBox.shrink(),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: const BoxDecoration(shape: BoxShape.circle),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: List.generate(5, (i) {
                                            final filled = i < _rating.round();
                                            return Icon(Icons.star, size: 18, color: filled ? Colors.amber : Colors.white24);
                                          }),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(_rating > 0 ? _rating.toStringAsFixed(2) : '-', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        const Text('Rating', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: _buildLabeledText('First name', TextField(style: const TextStyle(color: Colors.white), controller: _firstCtrl, decoration: InputDecoration(fillColor: _fieldFillColor, filled: true, hintStyle: const TextStyle(color: Colors.white54), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildLabeledText('Last name', TextField(style: const TextStyle(color: Colors.white), controller: _lastCtrl, decoration: InputDecoration(fillColor: _fieldFillColor, filled: true, hintStyle: const TextStyle(color: Colors.white54), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)))))
                          ]),
                          const SizedBox(height: 12),
                          _buildLabeledText('Email', TextField(style: const TextStyle(color: Colors.white70), controller: _emailCtrl, readOnly: true, decoration: InputDecoration(fillColor: _fieldFillColor, filled: true, hintStyle: const TextStyle(color: Colors.white54), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)))),
                          const SizedBox(height: 12),
                          const Text('Location', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          LayoutBuilder(builder: (ctx, constraints) {
                            if (constraints.maxWidth < 520) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    isDense: true,
                                    decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), filled: true, fillColor: _fieldFillColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                                    value: _district,
                                    items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))).toList(),
                                    onChanged: (v) {
                                      setState(() {
                                        _district = v;
                                        // update cities available for this district
                                        _cities = List<String>.from(_citiesByDistrict[v] ?? ['Select district first']);
                                        _city = _cities.isNotEmpty ? _cities.first : 'Select district first';
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    isDense: true,
                                    decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), filled: true, fillColor: _fieldFillColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                                    value: _city,
                                    items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                                    onChanged: (v) => setState(() => _city = v),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    isDense: true,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      filled: true,
                                      fillColor: _fieldFillColor,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                    ),
                                    value: _district,
                                    items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))).toList(),
                                    onChanged: (v) {
                                      setState(() {
                                        _district = v;
                                        _cities = List<String>.from(_citiesByDistrict[v] ?? ['Select district first']);
                                        _city = _cities.isNotEmpty ? _cities.first : 'Select district first';
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    isDense: true,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      filled: true,
                                      fillColor: Colors.black26,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                    ),
                                    value: _city,
                                    items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                                    onChanged: (v) => setState(() => _city = v),
                                  ),
                                ),
                              ],
                            );
                          }),
                          const SizedBox(height: 12),
                          const Text('Skills & Experience', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          // dynamic skills list
                          Column(
                            children: [
                              for (var i = 0; i < _skillsList.length; i++)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: _skillsList[i]['skill'] ?? _skills.first,
                                          isExpanded: true,
                                          decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), filled: true, fillColor: _fieldFillColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                                          items: _skills.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                          onChanged: (v) => setState(() => _skillsList[i]['skill'] = v ?? _skills.first),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 140,
                                        child: TextField(
                                          controller: TextEditingController(text: _skillsList[i]['experience']),
                                          decoration: InputDecoration(hintText: 'Experience', filled: true, fillColor: _fieldFillColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                                          onChanged: (v) => _skillsList[i]['experience'] = v,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                                        onPressed: () {
                                          setState(() {
                                            _skillsList.removeAt(i);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(onPressed: () => setState(() => _skillsList.add({'skill': _skills.first, 'experience': ''})), icon: Icon(Icons.add, color: Colors.purple.shade200), label: Text('+ Add Skill', style: TextStyle(color: Colors.purple.shade200))),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            style: const TextStyle(color: Colors.white),
                            controller: _serviceLocationCtrl,
                            decoration: InputDecoration(
                              hintText: 'Service Location (or use GPS)',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              filled: true,
                              fillColor: _fieldFillColor,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              suffixIcon: SizedBox(
                                width: 120,
                                child: TextButton(
                                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                  onPressed: _onGetLocation,
                                  child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.location_on, color: Colors.purple.shade50, size: 18), const SizedBox(width: 6), Flexible(child: Text('Get Location', style: TextStyle(color: Colors.purple.shade50, fontSize: 13)))]),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(style: const TextStyle(color: Colors.white), controller: _contactNumberCtrl, decoration: InputDecoration(hintText: 'Contact Number (e.g., +94 77 123 4567)', fillColor: _fieldFillColor, filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
                          const SizedBox(height: 18),
                          LayoutBuilder(builder: (ctx, constraints) {
                            final available = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.of(context).size.width;
                            final buttonWidth = (available - 12) / 2;
                            return Row(
                              children: [
                                SizedBox(
                                  width: buttonWidth,
                                  child: OutlinedButton(
                                    onPressed: _saving
                                        ? null
                                        : () async {
                                            // clear local fields
                                            _firstCtrl.clear();
                                            _lastCtrl.clear();
                                            _serviceLocationCtrl.clear();
                                            _contactNumberCtrl.clear();
                                            setState(() {
                                              _district = _districts.first;
                                              _city = _cities.first;
                                              _skillsList.clear();
                                            });

                                            // also clear user's Firestore userlog
                                            final user = FirebaseAuth.instance.currentUser;
                                            if (user != null) {
                                              try {
                                                await FirebaseFirestore.instance.collection('userlog').doc(user.uid).set({
                                                  'firstName': FieldValue.delete(),
                                                  'lastName': FieldValue.delete(),
                                                  'district': FieldValue.delete(),
                                                  'city': FieldValue.delete(),
                                                  'serviceLocation': FieldValue.delete(),
                                                  'contactNumber': FieldValue.delete(),
                                                  'skills': FieldValue.delete(),
                                                }, SetOptions(merge: true));
                                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Form cleared')));
                                              } catch (e) {
                                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to clear: ${e.toString()}')));
                                              }
                                            }
                                          },
                                    child: const Text('Clear Form'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: buttonWidth,
                                  child: ElevatedButton(
                                    onPressed: _saving ? null : _save,
                                    child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Info'),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledText(String label, Widget child) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)), const SizedBox(height: 6), child]);
  }
}


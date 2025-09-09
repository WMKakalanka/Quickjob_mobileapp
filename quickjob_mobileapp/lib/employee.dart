// employee.dart
// - Main employee dashboard page (EmployeePage) shown after login.
// - Displays job lists, filters, search, and navigation to settings.
// - Uses Firestore collections: jobposts, jobcategory, map to build UI and filters.
// Important functions: _loadFilters(), _mapDocToJob(), and the _JobCard widget.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'employee_settings.dart';

class EmployeePage extends StatefulWidget {
  const EmployeePage({Key? key}) : super(key: key);

  @override
  _EmployeePageState createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  // search & filters state
  String search = '';
  List<String> categories = ['All Categories'];
  String selectedCategory = 'All Categories';

  List<String> districts = [];
  List<Map<String, dynamic>> mapDocs = [];
  String selectedDistrict = 'All Districts';

  final jobpostsRef = FirebaseFirestore.instance.collection('jobposts');
  final jobcategoryRef = FirebaseFirestore.instance.collection('jobcategory');
  final mapRef = FirebaseFirestore.instance.collection('map');
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    try {
      final catSnap = await jobcategoryRef.get();
      final cats = catSnap.docs.map((d) => (d.data()['name'] ?? d.id).toString()).toList();
      // load map/districts
      final mapSnap = await mapRef.get();
      final md = mapSnap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'districtName': (data['districtName'] ?? data['name'] ?? d.id).toString(),
          'cities': data['cities'] ?? []
        };
      }).toList();

      setState(() {
        categories = ['All Categories'] + cats;
        mapDocs = md.cast<Map<String, dynamic>>().toList();
        districts = mapDocs.map((m) => m['districtName'].toString()).toList();
        selectedDistrict = 'All Districts';
      });
    } catch (e) {
      // ignore load errors for now
      // print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = FirebaseAuth.instance.currentUser?.displayName?.split(' ').first ?? '';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // header
                Row(
                  children: [
                    // left arrow back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white70),
                      tooltip: 'Back',
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    Image.asset('assets/logo2.png', width: 64, height: 64),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Welcome ${firstName.isNotEmpty ? firstName : ''}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                   
                  ],
                ),

                const SizedBox(height: 12),

                // Search & filters (responsive)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 520;

                    final dropdowns = Row(
                      children: [
                        // Category
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                              onChanged: (v) => setState(() => selectedCategory = v ?? 'All Categories'),
                              dropdownColor: Colors.black87,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // District
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedDistrict,
                              items: (['All Districts'] + districts).map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(color: Colors.white)))).toList(),
                              onChanged: (v) {
                                final val = v ?? 'All Districts';
                                setState(() {
                                  selectedDistrict = val;
                                });
                              },
                              dropdownColor: Colors.black87,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    );

                    if (narrow) {
                      // Single horizontal line: search + filters (scrollable)
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Container(
                              width: constraints.maxWidth * 0.65,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextField(
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  icon: Icon(Icons.search, color: Colors.white70),
                                  hintText: 'Search jobs...',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  border: InputBorder.none,
                                ),
                                onChanged: (v) => setState(() => search = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            dropdowns,
                          ],
                        ),
                      );
                    }

                    // wide layout
                    return Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                icon: Icon(Icons.search, color: Colors.white70),
                                hintText: 'Search jobs...',
                                hintStyle: TextStyle(color: Colors.white54),
                                border: InputBorder.none,
                              ),
                              onChanged: (v) => setState(() => search = v),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // let the dropdowns size themselves instead of using Expanded with flex:0
                        dropdowns,
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Content (live from Firestore) with server-side filters
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: (() {
                      Query q = jobpostsRef;
                      if (selectedCategory != 'All Categories') {
                        q = q.where('category', arrayContains: selectedCategory);
                      }
                      if (selectedDistrict != 'All Districts') {
                        // filter by top-level 'location' field per request
                        q = q.where('location', isEqualTo: selectedDistrict);
                      }
                      q = q.orderBy('createdAt', descending: true);
                      return q.snapshots();
                    })(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No jobs found', style: TextStyle(color: Colors.white70)));
                      }

                      // Map documents to job maps
                      final docs = snapshot.data!.docs;
                      final jobs = docs.map((d) => _mapDocToJob(d)).where((j) {
                        final title = (j['title'] as String).toLowerCase();
                        final q = search.toLowerCase();
                        return q.isEmpty || title.contains(q);
                      }).toList();

                      return LayoutBuilder(builder: (context, constraints) {
                        final crossAxis = constraints.maxWidth > 700 ? 2 : 1;
                        // Make single-column cards taller to avoid overflow on small screens
                        final childAspect = crossAxis == 1 ? 1.0 : 1.6;
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxis,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: childAspect,
                          ),
                          itemCount: jobs.length,
                          itemBuilder: (context, index) {
                            final job = jobs[index];
                            return _JobCard(job: job);
                          },
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: Colors.black.withOpacity(1),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: (i) {
          if (i == 1) {
            // Open settings page
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmployeeSettingsPage()));
          }
          setState(() => _selectedIndex = i);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Map<String, dynamic> _mapDocToJob(DocumentSnapshot d) {
    final data = d.data() as Map<String, dynamic>? ?? {};
    // title
    final title = (data['title'] ?? data['jobTitle'] ?? '') as String;
    // supplier/company
    final company = (data['supplier'] ?? data['company'] ?? '') as String;
    // category array -> tags
    final tags = <String>[];
    try {
      final cat = data['category'];
      if (cat is List) tags.addAll(cat.map((e) => e.toString()));
    } catch (_) {}
    // excerpt/description
    final excerpt = (data['description'] ?? '') as String;
    // views
    final views = (data['views'] ?? 0) as int;
    // createdAt -> formatted
    String dateStr = '';
    try {
      final ts = data['createdAt'];
      if (ts is Timestamp) {
        final dt = ts.toDate();
        dateStr = '${dt.month}/${dt.day}/${dt.year}';
      }
    } catch (_) {}

    // district/location
    String district = '';
    try {
      final images = data['images'];
      if (images is Map && images['location'] != null) district = images['location'].toString();
      if (district.isEmpty && data['location'] != null) district = data['location'].toString();
    } catch (_) {}

    // try to find an image URL
    String? imageUrl;
    try {
      if (data['imageUrl'] is String && (data['imageUrl'] as String).isNotEmpty) imageUrl = data['imageUrl'] as String;
      else if (data['images'] is String && (data['images'] as String).isNotEmpty) imageUrl = data['images'] as String;
      else if (data['images'] is Map) {
        final imagesMap = data['images'] as Map<String, dynamic>;
        // try common keys
        if (imagesMap['imageUrl'] != null) imageUrl = imagesMap['imageUrl'].toString();
        else if (imagesMap['0'] != null) imageUrl = imagesMap['0'].toString();
      }
    } catch (_) {}

    // contact info
    String? phone;
    String? publisherEmail;
    try {
      if (data['phone'] != null) phone = data['phone'].toString();
      else if (data['contactPhone'] != null) phone = data['contactPhone'].toString();
      if (data['publisherEmail'] != null) publisherEmail = data['publisherEmail'].toString();
      else if (data['email'] != null) publisherEmail = data['email'].toString();
      else if (data['contactEmail'] != null) publisherEmail = data['contactEmail'].toString();
    } catch (_) {}

    return {
      'id': d.id,
      'title': title,
      'district': district,
      'company': company,
  'phone': phone,
  'publisherEmail': publisherEmail,
      'tags': tags.isNotEmpty ? tags : ['General'],
      'excerpt': excerpt,
      'views': views,
      'date': dateStr,
      'imageUrl': imageUrl,
    };
  }
}

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  const _JobCard({required this.job, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: open job details
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(colors: [Colors.purple.shade800.withOpacity(0.95), Colors.purple.shade600.withOpacity(0.9)]),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder area (your DB images go here)
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
              ),
              child: Builder(builder: (ctx) {
                // Prefer explicit imageUrl from the job document. If missing,
                // pick an asset based on the first tag (job category).
                final imageUrl = job['imageUrl'] as String?;
                final tags = <String>[];
                try {
                  final raw = job['tags'] as List<dynamic>?;
                  if (raw != null) tags.addAll(raw.map((e) => e.toString()));
                } catch (_) {}

                if (imageUrl != null && imageUrl.isNotEmpty) {
                  return Image.network(imageUrl, fit: BoxFit.cover);
                }

                // map of lowercase tag -> asset path (file names expected in assets/)
                final map = <String, String>{
                  'painter - vehicle': 'assets/Painter - Vehicle.jpg',
                  'carpenter': 'assets/carpenter.jpg',
                  'driving': 'assets/Driving.jpg',
                  'plumber': 'assets/Plumber.jpg',
                  'helper': 'assets/Helper.jpg',
                  'electrician - vehicle': 'assets/Electrician - Vehicle.jpg',
                  'photography': 'assets/Photographer.jpg',
                  'electrician': 'assets/Electrician.jpg',
                  'cook': 'assets/Cook.jpg',
                  'mechanic': 'assets/mechanic.jpg',
                  'builder': 'assets/Builder.jpg',
                };

                final firstTag = tags.isNotEmpty ? tags.first.toString().toLowerCase().trim() : '';
                final assetPath = map[firstTag] ?? 'assets/logo.png';

                // Try to find the actual asset file among common variants.
                return FutureBuilder<String?>(
                  future: (() async {
                    final candidates = <String>[];
                    // direct mapped name first
                    candidates.add(assetPath);
                    // common variants: lowercase filename, replace spaces with no-space, lower and capitalized
                    final nameOnly = assetPath.split('/').last;
                    final dir = assetPath.replaceFirst('/' + nameOnly, '');
                    final lower = nameOnly.toLowerCase();
                    final noSpaces = nameOnly.replaceAll(' ', '');
                    final underscored = nameOnly.replaceAll(' ', '_');
                    candidates.add('$dir/$lower');
                    candidates.add('$dir/$noSpaces');
                    candidates.add('$dir/$underscored');
                    // also try Title case variation
                    final title = nameOnly.splitMapJoin(RegExp(r'\s+'), onMatch: (_) => ' ', onNonMatch: (s) => s);
                    candidates.add('$dir/$title');

                    for (final p in candidates) {
                      try {
                        await rootBundle.load(p);
                        return p;
                      } catch (_) {
                        // not found, continue
                      }
                    }
                    return null;
                  })(),
                  builder: (ctx2, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final found = snap.data;
                    if (found != null) {
                      debugPrint('Using job asset: $found');
                      return Image.asset(found, fit: BoxFit.cover, errorBuilder: (c, e, s) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.image, color: Colors.white38, size: 36),
                            SizedBox(height: 6),
                            Text('Image', style: TextStyle(color: Colors.white38)),
                          ],
                        ),
                      ));
                    }
                    // fallback to logo
                    debugPrint('No category asset found, falling back to logo');
                    return Image.asset('assets/logo.png', fit: BoxFit.cover, errorBuilder: (c, e, s) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.image, color: Colors.white38, size: 36),
                          SizedBox(height: 6),
                          Text('Image', style: TextStyle(color: Colors.white38)),
                        ],
                      ),
                    ));
                  },
                );
              }),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(job['district'] ?? '', style: const TextStyle(color: Colors.white70)),
                        const SizedBox(width: 12),
                        const Icon(Icons.business, size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Expanded(child: Text(job['company'] ?? '', style: const TextStyle(color: Colors.white70))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Render tags in a horizontal scroll to avoid vertical growth
                    SizedBox(
                      height: 30,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: (job['tags'] as List<dynamic>)
                                .map((t) => Padding(
                                      padding: const EdgeInsets.only(right: 6.0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(1),
                                          borderRadius: BorderRadius.circular(16),
                                          // no border
                                        ),
                                        child: Text(
                                          t.toString(),
                                          style: const TextStyle(color: Colors.white),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ))
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // show a two-line preview and a "Read more" dialog for long excerpts
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job['excerpt'] ?? '',
                          style: const TextStyle(color: Colors.white70),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Builder(builder: (ctx) {
                          final full = (job['excerpt'] ?? '').toString();
                          // show Read more only when the text is reasonably long
                          if (full.length <= 120) return const SizedBox.shrink();
                          return Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                showDialog(
                                  context: ctx,
                                  builder: (_) => AlertDialog(
                                    backgroundColor: Colors.grey[900],
                                    title: const Text('Job details', style: TextStyle(color: Colors.white)),
                                    content: SingleChildScrollView(
                                      child: Text(full, style: const TextStyle(color: Colors.white70)),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
                                    ],
                                  ),
                                );
                              },
                              child: const Text('Read more', style: TextStyle(color: Colors.white70)),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [const Icon(Icons.remove_red_eye, size: 14, color: Colors.white70), const SizedBox(width: 6), Text('${job['views'] ?? 0} views', style: const TextStyle(color: Colors.white70))]),
                        Text(job['date'] ?? '', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Action buttons: Email, Contact, Apply Now
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        SizedBox(
                          width: 110,
                          child: ElevatedButton.icon(
                              onPressed: () {
                                final email = job['publisherEmail'] as String?;
                                final phone = job['phone'] as String?;
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => _ContactSheet(email: email, phone: phone),
                                );
                              },
                            icon: const Icon(Icons.email, size: 16, color: Colors.white),
                            label: const Text('Email', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.black45, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: const Size(0, 36), tapTargetSize: MaterialTapTargetSize.shrinkWrap, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          ),
                        ),
                        SizedBox(
                          width: 110,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final email = job['publisherEmail'] as String?;
                              final phone = job['phone'] as String?;
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (_) => _ContactSheet(email: email, phone: phone),
                              );
                            },
                            icon: const Icon(Icons.phone, size: 16, color: Colors.white),
                            label: const Text('Contact', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.black45, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: const Size(0, 36), tapTargetSize: MaterialTapTargetSize.shrinkWrap, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final title = (job['title'] ?? '').toString();
                              final tags = (job['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['General'];
                              final defaultCategory = tags.isNotEmpty ? tags.first : 'General';

                              final nameCtrl = TextEditingController();
                              final addrCtrl = TextEditingController();
                              final phoneCtrl = TextEditingController();

                              showDialog(
                                context: context,
                                builder: (dctx) {
                                  bool isSubmitting = false;
                                  return Dialog(
                                    backgroundColor: Colors.transparent,
                                    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                                    child: StatefulBuilder(
                                      builder: (ctx, setState) {
                                        return Container(
                                          constraints: const BoxConstraints(minWidth: 280, maxWidth: 560),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[900],
                                            borderRadius: BorderRadius.circular(14),
                                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 12)],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  Row(children: [const Icon(Icons.how_to_reg, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text('Apply for: $title', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))],),
                                                  const SizedBox(height: 12),
                                                  const Text('Full Name *', style: TextStyle(color: Colors.white70)),
                                                  const SizedBox(height: 6),
                                                  TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(fillColor: Colors.black45, filled: true, hintText: 'Enter your full name', hintStyle: const TextStyle(color: Colors.white38), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
                                                  const SizedBox(height: 12),
                                                  const Text('Address *', style: TextStyle(color: Colors.white70)),
                                                  const SizedBox(height: 6),
                                                  TextField(controller: addrCtrl, style: const TextStyle(color: Colors.white), maxLines: 3, decoration: InputDecoration(fillColor: Colors.black45, filled: true, hintText: 'Enter your full address', hintStyle: const TextStyle(color: Colors.white38), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
                                                  const SizedBox(height: 12),
                                                  const Text('Job Category', style: TextStyle(color: Colors.white70)),
                                                  const SizedBox(height: 6),
                                                  Builder(builder: (tagCtx) {
                                                    if (tags.length > 1) {
                                                      return SizedBox(
                                                        height: 36,
                                                        child: SingleChildScrollView(
                                                          scrollDirection: Axis.horizontal,
                                                          child: Row(
                                                            children: tags
                                                                .map((t) => Padding(
                                                                      padding: const EdgeInsets.only(right: 8.0),
                                                                      child: Container(
                                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                                                                        child: Text(t, style: const TextStyle(color: Colors.white70)),
                                                                      ),
                                                                    ))
                                                                .toList(),
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                    return TextField(enabled: false, controller: TextEditingController(text: defaultCategory), style: const TextStyle(color: Colors.white70), decoration: InputDecoration(fillColor: Colors.black26, filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)));
                                                  }),
                                                  const SizedBox(height: 12),
                                                  const Text('Contact Number *', style: TextStyle(color: Colors.white70)),
                                                  const SizedBox(height: 6),
                                                  TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white), decoration: InputDecoration(fillColor: Colors.black45, filled: true, hintText: 'Enter your phone number', hintStyle: const TextStyle(color: Colors.white38), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
                                                  const SizedBox(height: 16),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(ctx).pop();
                                                        },
                                                        child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.purple,
                                                          minimumSize: const Size(120, 40),
                                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                        ),
                                                        onPressed: isSubmitting
                                                            ? null
                                                            : () async {
                                                                final name = nameCtrl.text.trim();
                                                                final addr = addrCtrl.text.trim();
                                                                final phone = phoneCtrl.text.trim();
                                                                if (name.isEmpty || addr.isEmpty || phone.isEmpty) {
                                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill required fields')));
                                                                  return;
                                                                }
                                                                try {
                                                                  setState(() {
                                                                    isSubmitting = true;
                                                                  });

                                                                  final applicant = {
                                                                    'name': name,
                                                                    'address': addr,
                                                                    'contactNumber': phone,
                                                                    'jobTitle': title,
                                                                    'jobCategory': tags.join(', '),
                                                                    'appliedAt': Timestamp.now(),
                                                                  };
                                                                  final pubEmail = job['publisherEmail'] as String?;
                                                                  if (pubEmail != null && pubEmail.isNotEmpty) applicant['publisherEmail'] = pubEmail;

                                                                  await FirebaseFirestore.instance.collection('applicant').add(applicant);

                                                                  // close the apply dialog
                                                                  Navigator.of(ctx).pop();

                                                                  // show an animated, branded success dialog (purple gradient + scale+slide+fade)
                                                                  showGeneralDialog(
                                                                    context: context,
                                                                    barrierDismissible: false,
                                                                    barrierLabel: 'Application Submitted',
                                                                    transitionDuration: const Duration(milliseconds: 520),
                                                                    pageBuilder: (context2, anim1, anim2) => const SizedBox.shrink(),
                                                                    transitionBuilder: (context2, a1, a2, child) {
                                                                      return Opacity(
                                                                        opacity: a1.value,
                                                                        child: Transform.translate(
                                                                          offset: Offset(0, (1 - a1.value) * 30),
                                                                          child: Transform.scale(
                                                                            scale: 0.9 + 0.1 * a1.value,
                                                                            child: Center(
                                                                              child: Container(
                                                                                width: 320,
                                                                                padding: const EdgeInsets.all(20),
                                                                                decoration: BoxDecoration(
                                                                                  gradient: LinearGradient(colors: [Colors.purple.shade800.withOpacity(0.98), Colors.purple.shade600.withOpacity(0.95)]),
                                                                                  borderRadius: BorderRadius.circular(14),
                                                                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 6))],
                                                                                ),
                                                                                child: Column(
                                                                                  mainAxisSize: MainAxisSize.min,
                                                                                  children: [
                                                                                    Container(
                                                                                      decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                                                                                      padding: const EdgeInsets.all(6),
                                                                                      child: const Icon(Icons.check_circle, color: Colors.white, size: 56),
                                                                                    ),
                                                                                    const SizedBox(height: 12),
                                                                                    const Text(
                                                                                      'Your Application Submitted Successfully!..',
                                                                                      textAlign: TextAlign.center,
                                                                                      style: TextStyle(
                                                                                        color: Colors.white,
                                                                                        fontSize: 16,
                                                                                        fontWeight: FontWeight.bold,
                                                                                        decoration: TextDecoration.none,
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      );
                                                                    },
                                                                  );

                                                                  // auto-dismiss success dialog and redirect to EmployeePage
                                                                  await Future.delayed(const Duration(milliseconds: 1400));
                                                                  try {
                                                                    Navigator.of(context).pop(); // pop success dialog
                                                                  } catch (_) {}
                                                                  // navigate back to the employee dashboard (reset stack)
                                                                  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const EmployeePage()), (r) => false);
                                                                } catch (e) {
                                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submit failed: ${e.toString()}')));
                                                                } finally {
                                                                  try {
                                                                    setState(() {
                                                                      isSubmitting = false;
                                                                    });
                                                                  } catch (_) {}
                                                                }
                                                              },
                                                        child: isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit Application'),
                                                      ),
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.send, size: 16, color: Colors.white),
                            label: const Text('Apply Now', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: const Size(0, 36), tapTargetSize: MaterialTapTargetSize.shrinkWrap, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings - placeholder')),
    );
  }
}

class _ContactSheet extends StatelessWidget {
  final String? email;
  final String? phone;
  const _ContactSheet({this.email, this.phone, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 12),
            const Text('Contact', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (email != null) ...[
              Row(
                children: [
                  const Icon(Icons.email, color: Colors.white70),
                  const SizedBox(width: 12),
                  Expanded(child: Text(email!, style: const TextStyle(color: Colors.white70))),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white70),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: email!));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email copied')));
                    },
                  )
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (phone != null) ...[
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.white70),
                  const SizedBox(width: 12),
                  Expanded(child: Text(phone!, style: const TextStyle(color: Colors.white70))),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white70),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: phone!));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone copied')));
                    },
                  )
                ],
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
            )
          ],
        ),
      ),
    );
  }
}


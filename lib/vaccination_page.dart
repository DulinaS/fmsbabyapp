/* /* import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'vaccination_service.dart';
import 'vaccination_model.dart';
import 'child_model.dart';

class VaccinationPage extends StatefulWidget {
  final String childId;
  final Child? child;

  const VaccinationPage({
    Key? key, 
    required this.childId,
    this.child,
  }) : super(key: key);

  @override
  _VaccinationPageState createState() => _VaccinationPageState();
}

class _VaccinationPageState extends State<VaccinationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late VaccinationService _vaccinationService;
  List<Vaccination> _vaccinations = [];
  bool _isLoading = true;
  int _currentWeekFromBirth = 0;
  Set<String> _expandedDescriptions = {};

  final List<Map<String, String>> faqs = [
    {
      "question": "Why are baby vaccinations important?",
      "answer": "Vaccinations help protect babies from dangerous infectious diseases. They work by stimulating the immune system to recognize and fight specific pathogens, preventing serious illnesses that can cause complications or even death in young children.",
    },
    {
      "question": "Are there any side effects from vaccinations?",
      "answer": "Most babies experience mild side effects like low-grade fever, fussiness, or soreness at the injection site. These typically resolve within 1-2 days. Serious side effects are extremely rare. The benefits of vaccination far outweigh the risks.",
    },
    {
      "question": "Can I vaccinate my baby if they have a cold?",
      "answer": "Mild illnesses like a low-grade fever or cold are not reasons to postpone vaccination. However, if your baby has a moderate to severe illness, it's best to wait until they recover. Always consult with your healthcare provider if you're unsure.",
    },
    {
      "question": "What if we miss a scheduled vaccination?",
      "answer": "If you miss a scheduled vaccination, contact your healthcare provider as soon as possible to reschedule. Most vaccines can be given later, and the doctor can help you get back on schedule. There's usually no need to restart the entire series.",
    },
    {
      "question": "Can I space out my baby's vaccines instead of following the standard schedule?",
      "answer": "The recommended vaccination schedule is designed to protect infants when they're most vulnerable to diseases. Delaying vaccines leaves your child at risk. Medical organizations worldwide recommend following the standard schedule for optimal protection.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize vaccination service with current user ID
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _vaccinationService = VaccinationService(currentUser.uid);
      _loadVaccinationData();
    } else {
      // Handle not logged in case
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadVaccinationData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update vaccination statuses based on current date
      await _vaccinationService.updateVaccinationStatuses(widget.childId);
      
      // Calculate current week from birth
      if (widget.child != null) {
        final now = DateTime.now();
        _currentWeekFromBirth = _vaccinationService.calculateWeeksFromBirth(
          widget.child!.dateOfBirth, 
          now
        );
      }
      
      // Subscribe to vaccinations stream
      _vaccinationService.getVaccinations(widget.childId).listen((vaccinations) {
        if (mounted) {
          setState(() {
            _vaccinations = vaccinations;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading vaccinations: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _markVaccinationCompleted(String vaccinationId) async {
    try {
      await _vaccinationService.markVaccinationCompleted(
        widget.childId, 
        vaccinationId
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating vaccination: ${e.toString()}')),
      );
    }
  }

  Future<void> _markVaccinationNotCompleted(String vaccinationId) async {
    try {
      await _vaccinationService.markVaccinationNotCompleted(
        widget.childId, 
        vaccinationId
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating vaccination: ${e.toString()}')),
      );
    }
  }

  String _getShortDescription(String desc, {int limit = 70}) {
    return desc.length > limit ? desc.substring(0, limit) + "..." : desc;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'due':
        return Colors.red;
      case 'upcoming':
        return Color(0xFF1873EA);
      default:
        return Colors.grey;
    }
  }

  String _formatDueDate(DateTime? dueDate) {
    if (dueDate == null) return 'Unknown';
    return DateFormat('MMM d, yyyy').format(dueDate);
  }

  String _getVaccinationStatusText(Vaccination vaccination) {
    if (vaccination.completed) {
      return 'Completed on ${DateFormat('MMM d, yyyy').format(vaccination.dateCompleted!)}';
    } else if (vaccination.status == 'due') {
      return 'Due now (${_formatDueDate(vaccination.dueDate)})';
    } else {
      return 'Due on ${_formatDueDate(vaccination.dueDate)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Vaccination", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1873EA),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [Tab(text: "Vaccination List"), Tab(text: "FAQ")],
        ),
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVaccinationList(),
                _buildFaqList(),
              ],
            ),
    );
  }

  Widget _buildVaccinationList() {
    return _vaccinations.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No vaccinations available'),
                SizedBox(height: 8),
                TextButton(
                  onPressed: _loadVaccinationData,
                  child: Text('Refresh'),
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: _vaccinations.length,
            itemBuilder: (context, index) {
              final vaccine = _vaccinations[index];
              final isExpanded = _expandedDescriptions.contains(vaccine.id);
              final shortDesc = _getShortDescription(vaccine.description);
              final statusColor = _getStatusColor(vaccine.status);
              
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline column
                  Column(
                    children: [
                      Container(
                        width: 20,
                        child: Column(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            if (index != _vaccinations.length - 1)
                              Container(
                                width: 2,
                                height: 80,
                                color: Colors.grey[300],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    'assets/images/vaccine_icon.png',
                                    width: 30,
                                    height: 30,
                                    errorBuilder: (context, error, stackTrace) => 
                                      Icon(Icons.medical_services, size: 30, color: statusColor),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vaccine.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            fontFamily: 'Nunito',
                                          ),
                                        ),
                                        Text(
                                          "Week ${vaccine.weekDue}",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          _getVaccinationStatusText(vaccine),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Checkbox(
                                    value: vaccine.completed,
                                    activeColor: Colors.green,
                                    shape: CircleBorder(),
                                    onChanged: (bool? value) {
                                      if (value == true) {
                                        _markVaccinationCompleted(vaccine.id);
                                      } else {
                                        _markVaccinationNotCompleted(vaccine.id);
                                      }
                                    },
                                  ),
                                ],
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Text(
                                  isExpanded
                                      ? vaccine.description
                                      : shortDesc,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      if (isExpanded) {
                                        _expandedDescriptions.remove(vaccine.id);
                                      } else {
                                        _expandedDescriptions.add(vaccine.id);
                                      }
                                    });
                                  },
                                  child: Text(
                                    isExpanded ? "Show Less" : "Read More",
                                    style: TextStyle(color: Color(0xFF1873EA)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
  }

  Widget _buildFaqList() {
    return ListView.builder(
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        return ExpansionTile(
          title: Text(
            faqs[index]["question"]!,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                faqs[index]["answer"]!,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
} */
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'vaccination_service.dart';
import 'vaccination_model.dart';
import 'child_model.dart';
import 'child_service.dart';

class VaccinationPage extends StatefulWidget {
  final String childId;
  final Child? child; // Make child parameter optional

  const VaccinationPage({Key? key, required this.childId, this.child})
    : super(key: key);

  @override
  _VaccinationPageState createState() => _VaccinationPageState();
}

class _VaccinationPageState extends State<VaccinationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late VaccinationService _vaccinationService;
  late ChildService _childService;
  List<Vaccination> _vaccinations = [];
  bool _isLoading = true;
  int _currentWeekFromBirth = 0;
  Set<String> _expandedDescriptions = {};
  Child? _child;

  final List<Map<String, String>> faqs = [
    {
      "question": "Why are baby vaccinations important?",
      "answer":
          "Vaccinations help protect babies from dangerous infectious diseases. They work by stimulating the immune system to recognize and fight specific pathogens, preventing serious illnesses that can cause complications or even death in young children.",
    },
    {
      "question": "Are there any side effects from vaccinations?",
      "answer":
          "Most babies experience mild side effects like low-grade fever, fussiness, or soreness at the injection site. These typically resolve within 1-2 days. Serious side effects are extremely rare. The benefits of vaccination far outweigh the risks.",
    },
    {
      "question": "Can I vaccinate my baby if they have a cold?",
      "answer":
          "Mild illnesses like a low-grade fever or cold are not reasons to postpone vaccination. However, if your baby has a moderate to severe illness, it's best to wait until they recover. Always consult with your healthcare provider if you're unsure.",
    },
    {
      "question": "What if we miss a scheduled vaccination?",
      "answer":
          "If you miss a scheduled vaccination, contact your healthcare provider as soon as possible to reschedule. Most vaccines can be given later, and the doctor can help you get back on schedule. There's usually no need to restart the entire series.",
    },
    {
      "question":
          "Can I space out my baby's vaccines instead of following the standard schedule?",
      "answer":
          "The recommended vaccination schedule is designed to protect infants when they're most vulnerable to diseases. Delaying vaccines leaves your child at risk. Medical organizations worldwide recommend following the standard schedule for optimal protection.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize vaccination service with current user ID
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _vaccinationService = VaccinationService(currentUser.uid);
      _childService = ChildService(currentUser.uid);

      // If we already have the child object, use it
      _child = widget.child;

      _loadChildData();
    } else {
      // Handle not logged in case
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  Future<void> _loadChildData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // If child is not provided, fetch it
      if (_child == null) {
        _child = await _childService.getChild(widget.childId);
        if (_child == null) {
          throw Exception('Child not found');
        }
      }

      // Check and initialize vaccinations if needed
      await _vaccinationService
          .checkAndInitializeVaccinations(widget.childId, _child!.dateOfBirth);

      debugPrint('Vaccinations initialization attempted');

      // Update vaccination statuses based on current date
      await _vaccinationService.updateVaccinationStatuses(widget.childId);

      // Calculate current week from birth
      if (_child != null) {
        final now = DateTime.now();
        _currentWeekFromBirth = _vaccinationService.calculateWeeksFromBirth(
          _child!.dateOfBirth,
          now,
        );
      }

      // Subscribe to vaccinations stream
      _vaccinationService
          .getVaccinations(widget.childId)
          .listen(
            (vaccinations) {
              debugPrint('Received ${vaccinations.length} vaccinations');
              if (mounted) {
                setState(() {
                  _vaccinations = vaccinations;
                  _isLoading = false;
                });
              }
            },
            onError: (e) {
              debugPrint('Error in vaccinations stream: $e');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          );
    } catch (e) {
      debugPrint('Error loading child data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading vaccinations: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _markVaccinationCompleted(String vaccinationId) async {
    try {
      await _vaccinationService.markVaccinationCompleted(
        widget.childId,
        vaccinationId,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating vaccination: ${e.toString()}')),
      );
    }
  }

  Future<void> _markVaccinationNotCompleted(String vaccinationId) async {
    try {
      await _vaccinationService.markVaccinationNotCompleted(
        widget.childId,
        vaccinationId,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating vaccination: ${e.toString()}')),
      );
    }
  }

  String _getShortDescription(String desc, {int limit = 70}) {
    return desc.length > limit ? desc.substring(0, limit) + "..." : desc;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'due':
        return Colors.red;
      case 'upcoming':
        return Color(0xFF1873EA);
      default:
        return Colors.grey;
    }
  }

  String _formatDueDate(DateTime? dueDate) {
    if (dueDate == null) return 'Unknown';
    return DateFormat('MMM d, yyyy').format(dueDate);
  }

  String _getVaccinationStatusText(Vaccination vaccination) {
    if (vaccination.completed) {
      return 'Completed on ${DateFormat('MMM d, yyyy').format(vaccination.dateCompleted!)}';
    } else if (vaccination.status == 'due') {
      return 'Due now (${_formatDueDate(vaccination.dueDate)})';
    } else {
      return 'Due on ${_formatDueDate(vaccination.dueDate)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Vaccination", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1873EA),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [Tab(text: "Vaccination List"), Tab(text: "FAQ")],
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [_buildVaccinationList(), _buildFaqList()],
              ),
    );
  }

  Widget _buildVaccinationList() {
    return _vaccinations.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.medical_services_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text('No vaccinations available'),
              SizedBox(height: 8),
              TextButton(onPressed: _loadChildData, child: Text('Refresh')),
            ],
          ),
        )
        : ListView.builder(
          itemCount: _vaccinations.length,
          itemBuilder: (context, index) {
            final vaccine = _vaccinations[index];
            final isExpanded = _expandedDescriptions.contains(vaccine.id);
            final shortDesc = _getShortDescription(vaccine.description);
            final statusColor = _getStatusColor(vaccine.status);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline column
                Column(
                  children: [
                    Container(
                      width: 20,
                      child: Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (index != _vaccinations.length - 1)
                            Container(
                              width: 2,
                              height: 80,
                              color: Colors.grey[300],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.medical_services,
                                  size: 30,
                                  color: statusColor,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vaccine.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          fontFamily: 'Nunito',
                                        ),
                                      ),
                                      Text(
                                        "Week ${vaccine.weekDue}",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        _getVaccinationStatusText(vaccine),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Checkbox(
                                  value: vaccine.completed,
                                  activeColor: Colors.green,
                                  shape: CircleBorder(),
                                  onChanged: (bool? value) {
                                    if (value == true) {
                                      _markVaccinationCompleted(vaccine.id);
                                    } else {
                                      _markVaccinationNotCompleted(vaccine.id);
                                    }
                                  },
                                ),
                              ],
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                isExpanded ? vaccine.description : shortDesc,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    if (isExpanded) {
                                      _expandedDescriptions.remove(vaccine.id);
                                    } else {
                                      _expandedDescriptions.add(vaccine.id);
                                    }
                                  });
                                },
                                child: Text(
                                  isExpanded ? "Show Less" : "Read More",
                                  style: TextStyle(color: Color(0xFF1873EA)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
  }

  Widget _buildFaqList() {
    return ListView.builder(
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        return ExpansionTile(
          title: Text(
            faqs[index]["question"]!,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                faqs[index]["answer"]!,
                style: TextStyle(color: Colors.grey[800], fontSize: 14),
              ),
            ),
          ],
        );
      },
    );
  }
}
 */
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'vaccination_service.dart';
import 'vaccination_model.dart';
import 'child_model.dart';
import 'child_service.dart';

class VaccinationPage extends StatefulWidget {
  final String childId;
  final Child? child;

  const VaccinationPage({Key? key, required this.childId, this.child})
    : super(key: key);

  @override
  _VaccinationPageState createState() => _VaccinationPageState();
}

class _VaccinationPageState extends State<VaccinationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late VaccinationService _vaccinationService;
  late ChildService _childService;
  List<Vaccination> _vaccinations = [];
  bool _isLoading = true;
  int _currentWeekFromBirth = 0;
  Set<String> _expandedDescriptions = {};
  Child? _child;

  final List<Map<String, String>> faqs = [
    {
      "question": "Why are baby vaccinations important?",
      "answer":
          "Vaccinations help protect babies from dangerous infectious diseases. They work by stimulating the immune system to recognize and fight specific pathogens, preventing serious illnesses that can cause complications or even death in young children.",
    },
    {
      "question": "Are there any side effects from vaccinations?",
      "answer":
          "Most babies experience mild side effects like low-grade fever, fussiness, or soreness at the injection site. These typically resolve within 1-2 days. Serious side effects are extremely rare. The benefits of vaccination far outweigh the risks.",
    },
    {
      "question": "Can I vaccinate my baby if they have a cold?",
      "answer":
          "Mild illnesses like a low-grade fever or cold are not reasons to postpone vaccination. However, if your baby has a moderate to severe illness, it's best to wait until they recover. Always consult with your healthcare provider if you're unsure.",
    },
    {
      "question": "What if we miss a scheduled vaccination?",
      "answer":
          "If you miss a scheduled vaccination, contact your healthcare provider as soon as possible to reschedule. Most vaccines can be given later, and the doctor can help you get back on schedule. There's usually no need to restart the entire series.",
    },
    {
      "question":
          "Can I space out my baby's vaccines instead of following the standard schedule?",
      "answer":
          "The recommended vaccination schedule is designed to protect infants when they're most vulnerable to diseases. Delaying vaccines leaves your child at risk. Medical organizations worldwide recommend following the standard schedule for optimal protection.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize vaccination service with current user ID
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _vaccinationService = VaccinationService(currentUser.uid);
      _childService = ChildService(currentUser.uid);

      // If we already have the child object, use it
      _child = widget.child;

      _loadChildData();
    } else {
      // Handle not logged in case
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChildData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // If child is not provided, fetch it
      if (_child == null) {
        _child = await _childService.getChild(widget.childId);
        if (_child == null) {
          throw Exception('Child not found');
        }
      }

      // Check and initialize vaccinations if needed
      await _vaccinationService
          .checkAndInitializeVaccinations(widget.childId, _child!.dateOfBirth);

      debugPrint('Vaccinations initialization attempted');

      // Update vaccination statuses based on current date
      await _vaccinationService.updateVaccinationStatuses(widget.childId);

      // Calculate current week from birth
      if (_child != null) {
        final now = DateTime.now();
        _currentWeekFromBirth = _vaccinationService.calculateWeeksFromBirth(
          _child!.dateOfBirth,
          now,
        );
      }

      // Subscribe to vaccinations stream
      _vaccinationService
          .getVaccinations(widget.childId)
          .listen(
            (vaccinations) {
              debugPrint('Received ${vaccinations.length} vaccinations');
              if (mounted) {
                setState(() {
                  _vaccinations = vaccinations;
                  _isLoading = false;
                });
              }
            },
            onError: (e) {
              debugPrint('Error in vaccinations stream: $e');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          );
    } catch (e) {
      debugPrint('Error loading child data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading vaccinations: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  Future<void> _markVaccinationCompleted(String vaccinationId) async {
    try {
      // Show marking as in progress
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                )
              ),
              SizedBox(width: 12),
              Text('Updating...')
            ],
          ),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.blue.shade700,
        ),
      );
      
      await _vaccinationService.markVaccinationCompleted(
        widget.childId,
        vaccinationId,
      );
      
      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Vaccination marked as completed')
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Error updating vaccination: ${e.toString()}')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  Future<void> _markVaccinationNotCompleted(String vaccinationId) async {
    try {
      // Show marking as in progress
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                )
              ),
              SizedBox(width: 12),
              Text('Updating...')
            ],
          ),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.blue.shade700,
        ),
      );
      
      await _vaccinationService.markVaccinationNotCompleted(
        widget.childId,
        vaccinationId,
      );
      
      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Vaccination marked as not completed')
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Error updating vaccination: ${e.toString()}')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  String _getShortDescription(String desc, {int limit = 70}) {
    return desc.length > limit ? desc.substring(0, limit) + "..." : desc;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green.shade600;
      case 'due':
        return Colors.red.shade600;
      case 'upcoming':
        return Color(0xFF1873EA);
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatDueDate(DateTime? dueDate) {
    if (dueDate == null) return 'Unknown';
    return DateFormat('MMM d, yyyy').format(dueDate);
  }

  String _getVaccinationStatusText(Vaccination vaccination) {
    if (vaccination.completed) {
      return 'Completed on ${DateFormat('MMM d, yyyy').format(vaccination.dateCompleted!)}';
    } else if (vaccination.status == 'due') {
      return 'Due now (${_formatDueDate(vaccination.dueDate)})';
    } else {
      return 'Due on ${_formatDueDate(vaccination.dueDate)}';
    }
  }

  void _showVaccinationDetails(Vaccination vaccine) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: Offset(0, -1),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        vaccine.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(vaccine.status),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        vaccine.completed
                            ? 'Completed'
                            : (vaccine.status == 'due' ? 'Due Now' : 'Upcoming'),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _buildDetailItem(
                  icon: Icons.event,
                  title: "Due Week",
                  value: "Week ${vaccine.weekDue} after birth",
                ),
                SizedBox(height: 8),
                _buildDetailItem(
                  icon: Icons.calendar_today,
                  title: "Due Date",
                  value: _formatDueDate(vaccine.dueDate),
                ),
                if (vaccine.completed) ...[
                  SizedBox(height: 8),
                  _buildDetailItem(
                    icon: Icons.check_circle,
                    title: "Completed On",
                    value: DateFormat('MMM d, yyyy').format(vaccine.dateCompleted!),
                    valueColor: Colors.green.shade700,
                  ),
                ],
                SizedBox(height: 24),
                Text(
                  "About",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    vaccine.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    if (vaccine.completed) {
                      _markVaccinationNotCompleted(vaccine.id);
                    } else {
                      _showDatePickerForCompletion(vaccine);
                    }
                  },
                  icon: Icon(vaccine.completed ? Icons.undo : Icons.check_circle),
                  label: Text(
                    vaccine.completed
                        ? 'Mark as Not Completed'
                        : 'Mark as Completed',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: vaccine.completed
                        ? Colors.orange.shade600
                        : Colors.green.shade600,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Color(0xFF1873EA),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDatePickerForCompletion(Vaccination vaccine) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: _child!.dateOfBirth,
      lastDate: now,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF1873EA),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await _vaccinationService.markVaccinationCompleted(
        widget.childId,
        vaccine.id,
        completionDate: picked,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Vaccinations",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF1873EA),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: Color(0xFF1873EA),
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Loading vaccination data...",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  color: Color(0xFF1873EA),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withOpacity(0.7),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: [
                      Tab(text: "Schedule"),
                      Tab(text: "FAQ"),
                    ],
                  ),
                ),
                if (_child != null) _buildChildInfoBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _vaccinations.isEmpty
                          ? _buildEmptyVaccinationList()
                          : _buildVaccinationList(),
                      _buildFaqList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildChildInfoBar() {
    if (_child == null) return SizedBox.shrink();

    // Convert birth date to age
    final now = DateTime.now();
    final difference = now.difference(_child!.dateOfBirth);
    
    String ageText;
    if (difference.inDays < 30) {
      ageText = '${difference.inDays} days old';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      ageText = '$months ${months == 1 ? 'month' : 'months'} old';
    } else {
      final years = (difference.inDays / 365).floor();
      final remainingMonths = ((difference.inDays % 365) / 30).floor();
      if (remainingMonths > 0) {
        ageText = '$years yr, $remainingMonths mo';
      } else {
        ageText = '$years ${years == 1 ? 'year' : 'years'} old';
      }
    }
    
    final gender = _child!.gender.toLowerCase() == 'boy' ? 'male' : 'female';
    final genderIcon = gender == 'male' ? Icons.male : Icons.female;
    final genderColor = gender == 'male' ? Color(0xFF1873EA) : Color(0xFFF50ED6);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: genderColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              genderIcon,
              color: genderColor,
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _child!.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Text(
                ageText,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          Spacer(),
          Text(
            'Week ${_currentWeekFromBirth}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1873EA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyVaccinationList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FontAwesomeIcons.syringe, size: 20, color: Colors.grey.shade400),
          SizedBox(height: 24),
          Text(
            'No Vaccinations Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'The vaccination schedule has not been set up for this child.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              try {
                // Force initialize vaccinations
                await _vaccinationService.initializeVaccinations(
                  widget.childId,
                  _child!.dateOfBirth,
                );
                
                // Reload data
                await Future.delayed(Duration(milliseconds: 500));
                await _loadChildData();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Vaccination schedule created successfully!'),
                      ],
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green.shade700,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(child: Text('Error: ${e.toString()}')),
                      ],
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.red.shade800,
                  ),
                );
                setState(() {
                  _isLoading = false;
                });
              }
            },
            icon: Icon(CupertinoIcons.plus_circle_fill),
            label: Text('Initialize Vaccination Schedule'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1873EA),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          SizedBox(height: 16),
          TextButton.icon(
            onPressed: _loadChildData,
            icon: Icon(Icons.refresh, size: 18),
            label: Text('Refresh'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationList() {
    // Group vaccinations by status for better organization
    final completedVaccinations = _vaccinations.where((v) => v.completed).toList();
    final dueVaccinations = _vaccinations.where((v) => !v.completed && v.status == 'due').toList();
    final upcomingVaccinations = _vaccinations.where((v) => !v.completed && v.status == 'upcoming').toList();

    return ListView(
      padding: EdgeInsets.symmetric(vertical: 16),
      children: [
        if (dueVaccinations.isNotEmpty) ...[
          _buildVaccinationSection(
            'Due Now',
            dueVaccinations,
            Colors.red.shade100,
            Icons.warning_amber_rounded,
            Colors.red.shade700,
          ),
        ],
        if (upcomingVaccinations.isNotEmpty) ...[
          _buildVaccinationSection(
            'Upcoming',
            upcomingVaccinations,
            Colors.blue.shade50,
            Icons.calendar_month,
            Color(0xFF1873EA),
          ),
        ],
        if (completedVaccinations.isNotEmpty) ...[
          _buildVaccinationSection(
            'Completed',
            completedVaccinations,
            Colors.green.shade50,
            Icons.check_circle,
            Colors.green.shade700,
          ),
        ],
      ],
    );
  }

  Widget _buildVaccinationSection(
    String title,
    List<Vaccination> vaccinations,
    Color backgroundColor,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
              SizedBox(width: 8),
              Text(
                '(${vaccinations.length})',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: vaccinations.length,
          itemBuilder: (context, index) {
            final vaccine = vaccinations[index];
            return _buildVaccinationCard(vaccine, backgroundColor);
          },
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildVaccinationCard(Vaccination vaccine, Color backgroundColor) {
    final statusColor = _getStatusColor(vaccine.status);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showVaccinationDetails(vaccine),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(FontAwesomeIcons.syringe, size: 20, color: statusColor)
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vaccine.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Week ${vaccine.weekDue}",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              _getVaccinationStatusText(vaccine),
                              style: TextStyle(
                                fontSize: 13,
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  vaccine.completed
                      ? Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.green.shade700,
                          ),
                        )
                      : Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: vaccine.status == 'due'
                                  ? Colors.red.shade400
                                  : Colors.blue.shade400,
                              width: 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _markVaccinationCompleted(vaccine.id);
                              },
                              customBorder: CircleBorder(),
                              child: Container(),
                            ),
                          ),
                        ),
                ],
              ),
              if (!_expandedDescriptions.contains(vaccine.id)) ...[
                SizedBox(height: 8),
                Text(
                  _getShortDescription(vaccine.description),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _expandedDescriptions.add(vaccine.id);
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: Color(0xFF1873EA),
                  ),
                  child: Text(
                    "Read More",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ] else ...[
                SizedBox(height: 8),
                Text(
                  vaccine.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _expandedDescriptions.remove(vaccine.id);
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: Color(0xFF1873EA),
                  ),
                  child: Text(
                    "Show Less",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 12),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              colorScheme: ColorScheme.light(
                primary: Color(0xFF1873EA),
              ),
            ),
            child: ExpansionTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.help_outline,
                  size: 20,
                  color: Color(0xFF1873EA),
                ),
              ),
              title: Text(
                faqs[index]["question"]!,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              childrenPadding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    faqs[index]["answer"]!,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
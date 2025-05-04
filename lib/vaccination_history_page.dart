import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'vaccination_service.dart';
import 'vaccination_model.dart';
import 'child_model.dart';

class VaccinationHistoryPage extends StatefulWidget {
  final String childId;
  final Child child;

  const VaccinationHistoryPage({
    Key? key, 
    required this.childId,
    required this.child,
  }) : super(key: key);

  @override
  _VaccinationHistoryPageState createState() => _VaccinationHistoryPageState();
}

class _VaccinationHistoryPageState extends State<VaccinationHistoryPage> {
  late VaccinationService _vaccinationService;
  List<Vaccination> _completedVaccinations = [];
  List<Vaccination> _upcomingVaccinations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
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

  void _loadVaccinationData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update vaccination statuses based on current date
      await _vaccinationService.updateVaccinationStatuses(widget.childId);
      
      // Subscribe to vaccinations stream
      _vaccinationService.getVaccinations(widget.childId).listen((vaccinations) {
        if (mounted) {
          setState(() {
            // Split vaccinations into completed and upcoming
            _completedVaccinations = vaccinations
                .where((v) => v.completed)
                .toList()
              ..sort((a, b) => (a.dateCompleted ?? DateTime.now())
                  .compareTo(b.dateCompleted ?? DateTime.now()));
            
            _upcomingVaccinations = vaccinations
                .where((v) => !v.completed)
                .toList()
              ..sort((a, b) => (a.dueDate ?? DateTime.now())
                  .compareTo(b.dueDate ?? DateTime.now()));
            
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Vaccination History", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1873EA),
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildChildInfoCard(),
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        Container(
                          color: Colors.white,
                          child: TabBar(
                            labelColor: Color(0xFF1873EA),
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Color(0xFF1873EA),
                            tabs: [
                              Tab(text: "Completed (${_completedVaccinations.length})"),
                              Tab(text: "Upcoming (${_upcomingVaccinations.length})"),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildCompletedVaccinationsList(),
                              _buildUpcomingVaccinationsList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildChildInfoCard() {
    // Calculate age in a display-friendly format
    final now = DateTime.now();
    final birthDate = widget.child.dateOfBirth;
    final ageInDays = now.difference(birthDate).inDays;
    
    String ageText;
    if (ageInDays < 30) {
      ageText = '$ageInDays days old';
    } else if (ageInDays < 365) {
      final months = (ageInDays / 30).floor();
      ageText = '$months ${months == 1 ? 'month' : 'months'} old';
    } else {
      final years = (ageInDays / 365).floor();
      final remainingMonths = ((ageInDays % 365) / 30).floor();
      ageText = '$years ${years == 1 ? 'year' : 'years'}';
      if (remainingMonths > 0) {
        ageText += ', $remainingMonths ${remainingMonths == 1 ? 'month' : 'months'} old';
      } else {
        ageText += ' old';
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.child.gender == 'boy' 
                ? Color(0xFF1873EA).withOpacity(0.2)
                : Color(0xFFF50ED6).withOpacity(0.2),
            ),
            child: Center(
              child: Icon(
                widget.child.gender == 'boy' ? Icons.male : Icons.female,
                color: widget.child.gender == 'boy' ? Color(0xFF1873EA) : Color(0xFFF50ED6),
                size: 36,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.child.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ageText,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Born on ${DateFormat('MMM d, yyyy').format(widget.child.dateOfBirth)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedVaccinationsList() {
    if (_completedVaccinations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No completed vaccinations yet'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _completedVaccinations.length,
      itemBuilder: (context, index) {
        final vaccine = _completedVaccinations[index];
        
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.2),
              ),
              child: Center(
                child: Icon(Icons.check, color: Colors.green),
              ),
            ),
            title: Text(
              vaccine.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Given on ${DateFormat('MMM d, yyyy').format(vaccine.dateCompleted!)}'),
                Text('Scheduled for week ${vaccine.weekDue}'),
              ],
            ),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              _showVaccinationDetails(vaccine);
            },
          ),
        );
      },
    );
  }

  Widget _buildUpcomingVaccinationsList() {
    if (_upcomingVaccinations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('All vaccinations completed!'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _upcomingVaccinations.length,
      itemBuilder: (context, index) {
        final vaccine = _upcomingVaccinations[index];
        final isDue = vaccine.status == 'due';
        
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDue 
                    ? Colors.red.withOpacity(0.2) 
                    : Color(0xFF1873EA).withOpacity(0.2),
              ),
              child: Center(
                child: Icon(
                  isDue ? Icons.warning : Icons.event,
                  color: isDue ? Colors.red : Color(0xFF1873EA),
                ),
              ),
            ),
            title: Text(
              vaccine.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Due ${isDue ? 'now' : 'on'} ${DateFormat('MMM d, yyyy').format(vaccine.dueDate!)}'),
                Text('Scheduled for week ${vaccine.weekDue}'),
              ],
            ),
            trailing: isDue 
                ? ElevatedButton(
                    onPressed: () => _markAsCompleted(vaccine),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text('Mark Done'),
                  )
                : Icon(Icons.chevron_right),
            onTap: () {
              _showVaccinationDetails(vaccine);
            },
          ),
        );
      },
    );
  }

  void _markAsCompleted(Vaccination vaccine) async {
    try {
      await _vaccinationService.markVaccinationCompleted(
        widget.childId, 
        vaccine.id,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${vaccine.name} marked as completed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating vaccination: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showVaccinationDetails(Vaccination vaccine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    vaccine.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: vaccine.completed 
                          ? Colors.green 
                          : (vaccine.status == 'due' ? Colors.red : Color(0xFF1873EA)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      vaccine.completed ? 'Completed' : (vaccine.status == 'due' ? 'Due Now' : 'Upcoming'),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              
              // Scheduled information
              Text(
                'Scheduled Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.event, color: Colors.grey, size: 18),
                  SizedBox(width: 8),
                  Text('Week ${vaccine.weekDue} after birth'),
                ],
              ),
              if (vaccine.dueDate != null) Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey, size: 18),
                  SizedBox(width: 8),
                  Text('Due date: ${DateFormat('MMM d, yyyy').format(vaccine.dueDate!)}'),
                ],
              ),
              SizedBox(height: 16),
              
              // Completion information if completed
              if (vaccine.completed) ...[
                Text(
                  'Completion Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Text('Given on ${DateFormat('MMM d, yyyy').format(vaccine.dateCompleted!)}'),
                  ],
                ),
                SizedBox(height: 16),
              ],
              
              // Description
              Text(
                'About This Vaccine',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              Text(
                vaccine.description,
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 24),
              
              // Actions
              Center(
                child: vaccine.completed
                    ? ElevatedButton.icon(
                        icon: Icon(Icons.undo),
                        label: Text('Mark as Not Completed'),
                        onPressed: () {
                          Navigator.pop(context);
                          _markAsNotCompleted(vaccine);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      )
                    : ElevatedButton.icon(
                        icon: Icon(Icons.check),
                        label: Text('Mark as Completed'),
                        onPressed: () {
                          Navigator.pop(context);
                          _showDatePicker(vaccine);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _markAsNotCompleted(Vaccination vaccine) async {
    try {
      await _vaccinationService.markVaccinationNotCompleted(
        widget.childId, 
        vaccine.id,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${vaccine.name} marked as not completed'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating vaccination: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDatePicker(Vaccination vaccine) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: widget.child.dateOfBirth,
      lastDate: DateTime.now(),
      builder: (context, child) {
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
      try {
        await _vaccinationService.markVaccinationCompleted(
          widget.childId,
          vaccine.id,
          completionDate: picked,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${vaccine.name} marked as completed on ${DateFormat('MMM d, yyyy').format(picked)}'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating vaccination: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
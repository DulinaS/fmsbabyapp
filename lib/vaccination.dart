import 'package:flutter/material.dart';

class VaccinationPage extends StatefulWidget {
  @override
  _VaccinationPageState createState() => _VaccinationPageState();
}

class _VaccinationPageState extends State<VaccinationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> vaccinations = [
    {
      "name": "BCG",
      "week": 0,
      "done": false,
      "description":
          "Protects against tuberculosis (TB), a serious infection that affects the lungs and other parts of the body.",
    },
    {
      "name": "Hepatitis B (1st dose)",
      "week": 0,
      "done": false,
      "description":
          "Prevents hepatitis B, a liver infection caused by the hepatitis B virus.",
    },
    {
      "name": "DTP, Hib, Polio (1st dose)",
      "week": 6,
      "done": false,
      "description":
          "Combined vaccine that protects against diphtheria, tetanus, pertussis (whooping cough), Haemophilus influenzae type b, and polio.",
    },
    {
      "name": "Rotavirus (1st dose)",
      "week": 6,
      "done": false,
      "description":
          "Protects against rotavirus, which causes severe diarrhea and vomiting in babies and young children.",
    },
    {
      "name": "Pneumococcal (1st dose)",
      "week": 10,
      "done": false,
      "description":
          "Helps prevent pneumonia, meningitis, and bloodstream infections caused by pneumococcal bacteria.",
    },
  ];

  final List<Map<String, String>> faqs = [
    {
      "question": "Why are baby vaccinations important?",
      "answer":
          "Vaccinations help protect babies from dangerous diseases early in life.",
    },
    {
      "question": "Are there any side effects?",
      "answer":
          "Some babies may experience mild fever or soreness, but side effects are usually minimal.",
    },
  ];

  final Set<int> expandedIndexes = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  String _getShortDescription(String desc, {int limit = 70}) {
    return desc.length > limit ? desc.substring(0, limit) + "..." : desc;
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
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView.builder(
            itemCount: vaccinations.length,
            itemBuilder: (context, index) {
              final vaccine = vaccinations[index];
              final isExpanded = expandedIndexes.contains(index);
              final shortDesc = _getShortDescription(vaccine["description"]);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                color:
                                    vaccine["done"]
                                        ? const Color.fromARGB(255, 12, 217, 19)
                                        : Color(0xFF1873EA),
                                shape: BoxShape.circle,
                              ),
                            ),
                            if (index != vaccinations.length - 1)
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
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vaccine["name"],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            fontFamily: 'Nunito',
                                          ),
                                        ),
                                        Text(
                                          "Week ${vaccine["week"]}",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Checkbox(
                                    value: vaccine["done"],
                                    shape: CircleBorder(),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        vaccinations[index]["done"] = value!;
                                      });
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
                                      ? vaccine["description"]
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
                                        expandedIndexes.remove(index);
                                      } else {
                                        expandedIndexes.add(index);
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
          ),

          // FAQ Tab
          ListView.builder(
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              return ExpansionTile(
                title: Text(faqs[index]["question"]!),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(faqs[index]["answer"]!),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

class BabyFeedingFAQPage extends StatefulWidget {
  @override
  _BabyFeedingFAQPageState createState() => _BabyFeedingFAQPageState();
}

class _BabyFeedingFAQPageState extends State<BabyFeedingFAQPage> {
  List<Map<String, String>> faqs = [];
  List<Map<String, String>> filteredFaqs = [];
  String searchQuery = "";
  bool isLoading = true;
  String errorMessage = "";
  
  // Define app colors
  final Color primaryColor = Color(0xFF1873EA);
  final Color secondaryColor = Color(0xFFE6F0FF);
  final Color accentColor = Color(0xFF62A1F6);

  @override
  void initState() {
    super.initState();
    _fetchFaqs();
  }

  // Fetch FAQ data from Firestore
  Future<void> _fetchFaqs() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('nutrition_faqs').get();

      setState(() {
        faqs = querySnapshot.docs.map((doc) {
          final data = doc.data();
          final question = data['question']?.toString() ?? 'No question';
          final answer = data['answer']?.toString() ?? 'No answer';
          return {"question": question, "answer": answer};
        }).toList();
        filteredFaqs = faqs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching FAQs: $e";
        isLoading = false;
      });
    }
  }

  void _filterFaqs(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      searchQuery = query;
      filteredFaqs = faqs.where((faq) {
        final question = faq['question']!.toLowerCase();
        final answer = faq['answer']!.toLowerCase();
        return question.contains(lowerQuery) || answer.contains(lowerQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Nourishing My Little One',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            fontFamily: 'Nunito',
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              // Show info about the app
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Baby Feeding FAQ - Helpful information for new parents'),
                  backgroundColor: accentColor,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with illustration
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Nunito',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Find answers to common questions about baby nutrition',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
          
          // Search bar
          Container(
            margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              onChanged: _filterFaqs,
              decoration: InputDecoration(
                hintText: 'Search questions...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: 'Nunito',
                ),
                prefixIcon: Icon(Icons.search, color: primaryColor),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _filterFaqs('');
                          // Clear the text field - you'll need a controller for this
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          // FAQ count indicator
          if (!isLoading && errorMessage.isEmpty && filteredFaqs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Showing ${filteredFaqs.length} of ${faqs.length} questions',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
            
          // FAQ list
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  )
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red[300],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Oops! Something went wrong',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Nunito',
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              errorMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontFamily: 'Nunito',
                              ),
                            ),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: Icon(Icons.refresh),
                              label: Text('Try Again'),
                              onPressed: _fetchFaqs,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : filteredFaqs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No matching questions found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Try using different keywords',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            itemCount: filteredFaqs.length,
                            itemBuilder: (context, index) {
                              return _buildFaqCard(index);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqCard(int index) {
    final isExpanded = ValueNotifier<bool>(false);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ValueListenableBuilder<bool>(
        valueListenable: isExpanded,
        builder: (context, expanded, _) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: expanded 
                      ? primaryColor.withOpacity(0.15) 
                      : Colors.black.withOpacity(0.05),
                  blurRadius: expanded ? 15 : 5,
                  offset: Offset(0, expanded ? 5 : 3),
                ),
              ],
              border: expanded
                  ? Border.all(color: primaryColor.withOpacity(0.2), width: 1)
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ExpansionTile(
                onExpansionChanged: (value) {
                  isExpanded.value = value;
                },
                initiallyExpanded: false,
                backgroundColor: Colors.white,
                collapsedBackgroundColor: Colors.white,
                tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                childrenPadding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                leading: CircleAvatar(
                  backgroundColor: expanded ? primaryColor : secondaryColor,
                  child: Icon(
                    expanded ? Icons.food_bank : Icons.question_mark,
                    color: expanded ? Colors.white : primaryColor,
                  ),
                ),
                title: Text(
                  filteredFaqs[index]["question"]!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    color: expanded ? primaryColor : Colors.black87,
                  ),
                ),
                iconColor: primaryColor,
                collapsedIconColor: Colors.grey[400],
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.lightbulb_outline,
                            color: accentColor,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            filteredFaqs[index]["answer"]!,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
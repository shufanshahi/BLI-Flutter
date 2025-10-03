import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey[200],
        body: const Center(
          child: CardWithChanger(),
        ),
      ),
    );
  }
}

class CardWithChanger extends StatefulWidget {
  const CardWithChanger({super.key});

  @override
  State<CardWithChanger> createState() => _CardWithChangerState();
}

class _CardWithChangerState extends State<CardWithChanger> {
  final List<Color> colors = [
    Colors.white,
    const Color(0xFFFFF3E0), // light orange
    const Color(0xFFE3F2FD), // light blue
    const Color(0xFFE8F5E9), // light green
    const Color(0xFFFCE4EC), // light pink
  ];

  int currentColorIndex = 0;

  // === Fonts ===
  final List<TextStyle Function()> fonts = [
    () => GoogleFonts.roboto(),
    () => GoogleFonts.lato(),
    () => GoogleFonts.poppins(),
    () => GoogleFonts.montserrat(),
    () => GoogleFonts.openSans(),
  ];

  int currentFontIndex = 0;

  void changeColor() {
    setState(() {
      currentColorIndex = Random().nextInt(colors.length);
    });
  }

  void changeFont() {
    setState(() {
      currentFontIndex = Random().nextInt(fonts.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fontStyle = fonts[currentFontIndex]();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ===== The Card =====
        Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 320,
            decoration: BoxDecoration(
              color: colors[currentColorIndex],
              borderRadius: BorderRadius.circular(12),
            ),
            child: DefaultTextStyle(
              style: fontStyle, // Apply selected font globally
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ===== Header with Logo & University Name + Profile overlap =====
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Header background
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 3, 43, 0),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          children: [
                            Image.asset("assets/images/logo.png", height: 60),
                            const SizedBox(height: 8),
                            Text(
                              "ISLAMIC UNIVERSITY OF TECHNOLOGY",
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: fontStyle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                
                                letterSpacing: 1,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 70),
                          ],
                        ),
                      ),

                      // Profile photo (overlapping)
                      Positioned(
                        bottom: -50,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 3, 43, 0),
                              border: Border.all(
                                color: Colors.black,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                "assets/images/student_photo.jpg",
                                height: 100,
                                width: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // ===== Student ID Label =====
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.vpn_key,
                            size: 20, color: Color.fromARGB(255, 0, 30, 10)),
                        const SizedBox(width: 8),
                        Text(
                          "Student ID",
                          style: fontStyle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color.fromARGB(255, 0, 30, 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Student ID Value
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 3,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 8,
                          backgroundColor: Color.fromARGB(255, 0, 140, 255),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "210041210",
                          style: fontStyle.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Student Name Label
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person, size: 20, color: Colors.black),
                        const SizedBox(width: 8),
                        Text(
                          "Student Name",
                          style: fontStyle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Student Name Value
                  Center(
                    child: Text(
                      "Shufan Shahi",
                      textAlign: TextAlign.center,
                      style: fontStyle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Program
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.school, size: 20, color: Colors.black),
                      const SizedBox(width: 8),
                      Text(
                        "Program :",
                        style: fontStyle.copyWith(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        " B.Sc. in CSE",
                        style: fontStyle.copyWith(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Department
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.account_tree,
                          size: 20, color: Colors.black),
                      const SizedBox(width: 8),
                      Text(
                        "Department :",
                        style: fontStyle.copyWith(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        " CSE",
                        style: fontStyle.copyWith(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on,
                          size: 20, color: Colors.black),
                      const SizedBox(width: 8),
                      Text(
                        "Bangladesh",
                        style: fontStyle.copyWith(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ===== Footer =====
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 3, 43, 0),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      "A subsidiary organ of OIC",
                      textAlign: TextAlign.center,
                      style: fontStyle.copyWith(
                        fontSize: 12,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // ===== Buttons =====
        // Column(
        //   mainAxisSize: MainAxisSize.min,
        //   children: [
        //     ElevatedButton(
        //       onPressed: changeColor,
        //       style: ElevatedButton.styleFrom(
        //         backgroundColor: Colors.green[800],
        //         foregroundColor: Colors.white,
        //       ),
        //       child: const Text("Change Color"),
        //     ),
        //     const SizedBox(height: 12),
        //     ElevatedButton(
        //       onPressed: changeFont,
        //       style: ElevatedButton.styleFrom(
        //         backgroundColor: Colors.blue[800],
        //         foregroundColor: Colors.white,
        //       ),
        //       child: const Text("Change Font"),
        //     ),
        //   ],
        // ),
      ],
    );
  }
}
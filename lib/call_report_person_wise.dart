import 'dart:convert';
import 'package:be_call/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';

class CallreportpersonWise extends StatefulWidget {
  final dynamic id;

  const CallreportpersonWise({super.key, required this.id});

  @override
  State<CallreportpersonWise> createState() => _CallreportpersonWiseState();
}

class _CallreportpersonWiseState extends State<CallreportpersonWise> {
  List<Map<String, dynamic>> groupedData = [];
  bool isLoading = true;

  DateTime? startDate;
  DateTime? endDate;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    DateTime today = DateTime.now();
    startDate = today;
    endDate = today;
    getDateWise(today, today);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  int parseDuration(String duration) {
    int totalSeconds = 0;
    final minMatch = RegExp(r'(\d+)\s*min').firstMatch(duration);
    final secMatch = RegExp(r'(\d+)\s*sec').firstMatch(duration);
    if (minMatch != null) totalSeconds += int.parse(minMatch.group(1)!) * 60;
    if (secMatch != null) totalSeconds += int.parse(secMatch.group(1)!);
    return totalSeconds;
  }

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return "${minutes}m ${remainingSeconds}s";
    } else {
      return "${remainingSeconds}s";
    }
  }

  Future<void> getDateWise(DateTime from, DateTime to) async {
    setState(() {
      isLoading = true;
    });

    var token = await getToken();

    try {
      var res = await http.get(
        Uri.parse("$api/api/call/report/staff/${widget.id}/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("Response Status Code: ${res.statusCode}");
      print("Response Body: ${res.body}");

      if (res.statusCode == 200) {
        List<dynamic> data = jsonDecode(res.body);

        List<Map<String, dynamic>> filtered = data.where((call) {
          final callDate = DateTime.tryParse(call['date']?.toString() ?? '');
          if (callDate == null) return false;
          return callDate.isAfter(from.subtract(const Duration(days: 1))) &&
              callDate.isBefore(to.add(const Duration(days: 1)));
        }).map((call) {
          final createdBy = (call['created_by_name'] ??
                  call['created_by_namme'] ??
                  'Unknown')
              .toString()
              .replaceAll('"', '');

          return {
            'name': createdBy,
            'duration': parseDuration(call['duration'] ?? '0 sec'),
            'time': call['call_datetime'] ?? '',
            'amount': (call['amount'] ?? 0).toDouble(),
            'customer': call['customer_name']?.toString() ?? '',
            'date': call['date']?.toString() ?? '',
            'audio_file': call['audio_file']?.toString() ?? '',
          };
        }).toList();

        setState(() {
          groupedData = filtered;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print("Error Response: ${res.body}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching data: $e");
    }
  }

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: startDate ?? DateTime.now(),
        end: endDate ?? DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF1AA48F),
              onPrimary: Colors.white,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      getDateWise(picked.start, picked.end);
    }
  }

  void _showAudioPopup(String url) async {
    final fullUrl = url.startsWith("http") ? url : "$api$url";

    _audioPlayer.stop();
    await _audioPlayer.setSourceUrl(fullUrl);

    _audioPlayer.onDurationChanged.listen((d) {
      setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      setState(() => _position = p);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() => _isPlaying = false);
      Navigator.pop(context); // auto-close on finish
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            title: const Text("Call Recording",
                style: TextStyle(color: Colors.tealAccent)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Slider(
  activeColor: Colors.tealAccent,
  inactiveColor: Colors.white24,
  min: 0,
  max: _duration.inSeconds.toDouble(),
  value: _position.inSeconds.clamp(0, _duration.inSeconds).toDouble(),
  onChanged: (value) {
    setState(() {
      _position = Duration(seconds: value.toInt());
    });
  },
  onChangeEnd: (value) async {
    final position = Duration(seconds: value.toInt());
    await _audioPlayer.seek(position);
    // Resume only if already playing
    if (_isPlaying) {
      await _audioPlayer.resume();
    }
  },
),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatTime(_position),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                      Text(_formatTime(_duration),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                IconButton(
                  iconSize: 60,
                  color: Colors.tealAccent,
                  icon: Icon(_isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill),
                  onPressed: () async {
                    if (_isPlaying) {
                      await _audioPlayer.pause();
                    } else {
                      await _audioPlayer.play(UrlSource(fullUrl));
                    }
                    setState(() => _isPlaying = !_isPlaying);
                  },
                ),
              ],
            ),
          );
        });
      },
    );
  }

  String _formatTime(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    String rangeText = "";
    if (startDate != null && endDate != null) {
      final fmt = DateFormat('dd MMM');
      rangeText =
          "${fmt.format(startDate!)} - ${fmt.format(endDate!)} (${DateFormat('yyyy').format(startDate!)})";
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1AA48F),
        title: const Text(
          "Productive Calls",
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.white),
            onPressed: pickDateRange,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.grey[900],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    rangeText.isEmpty ? "Today" : rangeText,
                    style: const TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Table(
                        border: TableBorder.all(color: Colors.white24, width: 1),
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(1.3),
                          2: FlexColumnWidth(1.2),
                          3: FlexColumnWidth(1.2),
                          4: FlexColumnWidth(0.8),
                        },
                        children: [
                          TableRow(
                            decoration:
                                BoxDecoration(color: Colors.grey[900]),
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  "Customer",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.tealAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  "Time",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.tealAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  "Duration",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.tealAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  "Amount",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.tealAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  "Play",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.tealAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          if (groupedData.isNotEmpty)
                            ...groupedData.map((row) {
                              String formattedTime = '';
                              if (row['time'] != null &&
                                  row['time'].toString().isNotEmpty) {
                                try {
                                  final parsed = DateTime.parse(row['time']);
                                  formattedTime =
                                      DateFormat('hh:mm a').format(parsed);
                                } catch (_) {
                                  formattedTime = '';
                                }
                              }

                              return TableRow(
                                decoration:
                                    const BoxDecoration(color: Colors.black),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(row['customer'],
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(formattedTime,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(
                                        formatDuration(row['duration']),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(
                                        "₹${row['amount'].toStringAsFixed(2)}",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Colors.tealAccent,
                                            fontWeight: FontWeight.w500)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: IconButton(
                                      icon: const Icon(Icons.play_circle_fill,
                                          color: Colors.tealAccent),
                                      onPressed: () {
                                        if (row['audio_file'] != null &&
                                            row['audio_file']
                                                .toString()
                                                .isNotEmpty) {
                                          _showAudioPopup(row['audio_file']);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      "No audio file found")));
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }),
                          if (groupedData.isEmpty)
                            const TableRow(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Text(
                                    "No Data Found",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                                SizedBox(),
                                SizedBox(),
                                SizedBox(),
                                SizedBox(),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

import 'dart:convert';
import 'package:biometric_attendance_record/features/attendance_details/attendance_detail_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceDetailScreen extends StatefulWidget {
  const AttendanceDetailScreen({super.key});

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  late Future<AttendanceDetailModel?> attendanceFuture;
  final TextEditingController _empCodeController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  static const String _empCodeKey = "employee_code";

  @override
  void initState() {
    super.initState();
    attendanceFuture = _initializeAttendance();
  }

  Future<AttendanceDetailModel?> _initializeAttendance() async {
    final prefs = await SharedPreferences.getInstance();

    final savedEmpCode = prefs.getString(_empCodeKey);

    if (savedEmpCode == null || savedEmpCode.isEmpty) {
      return null;
    }

    _empCodeController.text = savedEmpCode;

    return getAttendanceData();
  }

  @override
  void dispose() {
    _empCodeController.dispose();
    super.dispose();
  }

  Future<AttendanceDetailModel?> getAttendanceData() async {
    final empCode = _empCodeController.text.trim();

    if (empCode.isEmpty) {
      throw Exception("Please enter Employee Code");
    }

    try {
      final response = await http.post(
        Uri.parse(
          "https://wems.wavecorp.in:9091/api/AttendanceApi/GetEmployeeAttendanceReport",
        ),
        body: {
          "Month": _selectedDate.month.toString(),
          "Year": _selectedDate.year.toString(),
          "EmpCode": empCode,
          "Secret_Code": "123456",
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        return AttendanceDetailModel.fromJson(body);
      }

      throw Exception("Failed to fetch attendance (${response.statusCode})");
    } catch (e) {
      debugPrint("Attendance Error: $e");
      rethrow;
    }
  }

  Future<void> _fetchAttendance() async {
    final empCode = _empCodeController.text.trim();

    if (empCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter Employee Code"),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _empCodeKey,
      empCode,
    );

    setState(() {
      attendanceFuture = getAttendanceData();
    });
  }

  Future<void> _selectMonth() async {
    int selectedYear = _selectedDate.year;
    int selectedMonth = _selectedDate.month;

    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                "Select Month",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),

              content: SizedBox(
                width: 320,

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    // YEAR SELECTOR
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                      children: [
                        IconButton(
                          onPressed: () {
                            setDialogState(() {
                              selectedYear--;
                            });
                          },
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                          ),
                        ),

                        Text(
                          selectedYear.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        IconButton(
                          onPressed: () {
                            if (selectedYear <
                                DateTime.now().year) {
                              setDialogState(() {
                                selectedYear++;
                              });
                            }
                          },
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    GridView.builder(
                      shrinkWrap: true,

                      physics:
                      const NeverScrollableScrollPhysics(),

                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.5,
                      ),

                      itemCount: 12,

                      itemBuilder: (context, index) {
                        final month = index + 1;

                        final isSelected =
                            month == selectedMonth;

                        // Prevent selecting future months
                        final now = DateTime.now();

                        final isFuture =
                            selectedYear > now.year ||
                                (selectedYear == now.year &&
                                    month > now.month);

                        return InkWell(
                          borderRadius:
                          BorderRadius.circular(10),

                          onTap: isFuture
                              ? null
                              : () {
                            setDialogState(() {
                              selectedMonth = month;
                            });
                          },

                          child: Container(
                            alignment: Alignment.center,

                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : isFuture
                                  ? const Color(0xFFF1F5F9)
                                  : const Color(0xFFF8FAFC),

                              borderRadius:
                              BorderRadius.circular(10),

                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),

                            child: Text(
                              DateFormat(
                                "MMM",
                              ).format(
                                DateTime(
                                  selectedYear,
                                  month,
                                ),
                              ),

                              style: TextStyle(
                                fontSize: 13,

                                fontWeight:
                                FontWeight.w600,

                                color: isSelected
                                    ? Colors.white
                                    : isFuture
                                    ? const Color(
                                  0xFF94A3B8,
                                )
                                    : const Color(
                                  0xFF334155,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      DateTime(
                        selectedYear,
                        selectedMonth,
                      ),
                    );
                  },
                  child: const Text("Select"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedDate = result;
      });
      if (_empCodeController.text.trim().isNotEmpty) {
        _fetchAttendance();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),

        title: const Text(
          "Attendance",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _selectMonth,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 18),

                    const SizedBox(width: 6),

                    Text(
                      DateFormat("MMM yyyy").format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(width: 4),

                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          _buildFilterSection(),

          Expanded(
            child: FutureBuilder<AttendanceDetailModel?>(
              future: attendanceFuture,

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.none ||
                    (!snapshot.hasData && !snapshot.hasError)) {
                  return _buildInitialState();
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (!snapshot.hasData || snapshot.data?.data == null) {
                  return _buildEmptyState();
                }

                final attendanceList = snapshot.data?.data;

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      attendanceFuture = getAttendanceData();
                    });

                    await attendanceFuture;
                  },

                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),

                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),

                    children: [
                      _buildMonthHeader(),

                      const SizedBox(height: 20),

                      _buildSummary(attendanceList),

                      const SizedBox(height: 28),

                      const Text(
                        "Daily Attendance",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),

                      const SizedBox(height: 12),

                      ...?attendanceList?.map(
                        (attendance) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildAttendanceCard(attendance),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,

      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            "Employee Code",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _empCodeController,

                  keyboardType: TextInputType.number,

                  textInputAction: TextInputAction.done,

                  onSubmitted: (_) {
                    _fetchAttendance();
                  },

                  decoration: InputDecoration(
                    hintText: "Enter employee code",

                    prefixIcon: const Icon(Icons.badge_outlined, size: 21),

                    filled: true,

                    fillColor: const Color(0xFFF8FAFC),

                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              SizedBox(
                height: 50,
                width: 50,

                child: ElevatedButton(
                  onPressed: _fetchAttendance,

                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,

                    backgroundColor: const Color(0xFF2563EB),

                    foregroundColor: Colors.white,

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  child: const Icon(Icons.search_rounded, size: 23),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              height: 80,
              width: 80,

              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(22),
              ),

              child: const Icon(
                Icons.fingerprint_rounded,
                size: 42,
                color: Color(0xFF2563EB),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              "Enter Employee Code",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Enter your employee code to view your attendance report.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
        ),

        borderRadius: BorderRadius.circular(18),
      ),

      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,

            backgroundColor: Colors.white24,

            child: Icon(
              Icons.access_time_filled_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Text(
                "Attendance Report",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),

              const SizedBox(height: 3),

              Text(
                DateFormat("MMMM yyyy").format(_selectedDate),

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SUMMARY
  // ------------------------------------------------------------

  Widget _buildSummary(List<AttendanceData>? list) {
    final today = DateTime.now();

    final validRecords = list?.where((item) {
      if (item.attDate == null) return false;

      final date = DateTime.tryParse(item.attDate!);

      if (date == null) return false;

      return !date.isAfter(today);
    }).toList();

    final present = validRecords
        ?.where((e) => e.attendanceStatus == "Present")
        .length;

    final absent = validRecords
        ?.where((e) => e.attendanceStatus == "Absent")
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          "Attendance Summary",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: "Present",
                value: (present ?? 0).toString(),
                icon: Icons.check_circle_rounded,
                color: Colors.green,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _summaryCard(
                title: "Absent",
                value: (absent ?? 0).toString(),
                icon: Icons.cancel_rounded,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: const Color(0xFFE2E8F0)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,

            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(icon, color: color.shade600, size: 22),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  value,

                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  title,

                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceData attendance) {
    final status = attendance.attendanceStatus ?? "";

    final isPresent = status == "Present";
    final isAbsent = status == "Absent";
    final isWeeklyOff = status == "Weekly Off";

    final statusColor = isPresent
        ? Colors.green
        : isAbsent
        ? Colors.red
        : Colors.blue;

    final date = _formatDate(attendance.attDate);

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: const Color(0xFFE2E8F0)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Container(
                height: 46,
                width: 46,

                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Text(
                      _dayNumber(attendance.attDate),

                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                      ),
                    ),

                    Text(
                      _monthName(attendance.attDate),

                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      attendance.dayName ?? "",

                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      date,

                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              _statusBadge(status, statusColor),
            ],
          ),

          const SizedBox(height: 16),

          if (isPresent) ...[
            _timeRow(
              checkIn: attendance.inTime,
              checkOut: attendance.outTime,
              attendance: attendance.workingHours,
            ),
          ] else if (isWeeklyOff) ...[
            _specialStatus(
              icon: Icons.weekend_rounded,
              title: "Weekly Off",
              subtitle: "No attendance required",
            ),
          ] else if (isAbsent) ...[
            _specialStatus(
              icon: Icons.event_busy_rounded,
              title: "No attendance recorded",
              subtitle: "Employee was absent",
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeRow({String? checkIn, String? checkOut, String? attendance}) {
    return Row(
      children: [
        Expanded(
          child: _timeItem(
            icon: Icons.login_rounded,
            title: "Check In",
            value: _displayTime(checkIn),
          ),
        ),

        Container(height: 42, width: 1, color: const Color(0xFFE2E8F0)),

        Expanded(
          child: _timeItem(
            icon: Icons.logout_rounded,
            title: "Check Out",
            value: _displayTime(checkOut),
          ),
        ),

        Container(height: 42, width: 1, color: const Color(0xFFE2E8F0)),

        Expanded(
          child: _infoItem(
            icon: Icons.schedule_rounded,
            title: "Working Hours",
            value: attendance ?? "--",
          ),
        ),
      ],
    );
  }

  Widget _timeItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),

        const SizedBox(width: 10),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              title,

              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),

            const SizedBox(height: 3),

            Text(
              value,

              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        Icon(icon, size: 19, color: const Color(0xFF64748B)),

        const SizedBox(width: 8),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              title,

              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),

            const SizedBox(height: 2),

            Text(
              value,

              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusBadge(String status, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),

      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Container(
            height: 6,
            width: 6,

            decoration: BoxDecoration(
              color: color.shade600,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 5),

          Text(
            status,

            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _specialStatus({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(vertical: 18),

      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),

      child: Column(
        children: [
          Icon(icon, size: 28, color: const Color(0xFF64748B)),

          const SizedBox(height: 8),

          Text(
            title,

            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),

          const SizedBox(height: 3),

          Text(
            subtitle,

            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return "--";
    }

    final parsed = DateTime.tryParse(date);

    if (parsed == null) {
      return "--";
    }

    return DateFormat("dd MMM yyyy").format(parsed);
  }

  String _dayNumber(String? date) {
    if (date == null || date.isEmpty) {
      return "--";
    }

    final parsed = DateTime.tryParse(date);

    if (parsed == null) {
      return "--";
    }

    return DateFormat("dd").format(parsed);
  }

  String _monthName(String? date) {
    if (date == null || date.isEmpty) {
      return "--";
    }

    final parsed = DateTime.tryParse(date);

    if (parsed == null) {
      return "--";
    }

    return DateFormat("MMM").format(parsed).toUpperCase();
  }

  String _displayTime(String? time) {
    if (time == null || time.isEmpty) {
      return "--";
    }

    return time;
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: Colors.red,
            ),

            const SizedBox(height: 12),

            const Text(
              "Unable to load attendance",

              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 6),

            Text(
              error,
              textAlign: TextAlign.center,

              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _fetchAttendance,

              icon: const Icon(Icons.refresh_rounded),

              label: const Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(Icons.event_busy_rounded, size: 55, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            "No attendance records found",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
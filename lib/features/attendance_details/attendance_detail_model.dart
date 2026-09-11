// To parse this JSON data, do
//
//     final attendancedetailModel = attendancedetailModelFromJson(jsonString);

import 'dart:convert';

AttendanceDetailModel attendanceDetailModelFromJson(String str) => AttendanceDetailModel.fromJson(json.decode(str));

String attendanceDetailModelToJson(AttendanceDetailModel data) => json.encode(data.toJson());

class AttendanceDetailModel {
  final String? status;
  final String? flag;
  final String? alert;
  final List<AttendanceData>? data;

  AttendanceDetailModel({
    this.status,
    this.flag,
    this.alert,
    this.data,
  });

  factory AttendanceDetailModel.fromJson(Map<String, dynamic> json) => AttendanceDetailModel(
    status: json["status"],
    flag: json["flag"],
    alert: json["alert"],
    data: json["data"] == null ? [] : List<AttendanceData>.from(json["data"]!.map((x) => AttendanceData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "flag": flag,
    "alert": alert,
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}

class AttendanceData {
  final String? empCode;
  final String? attDate;
  final String? dayName;
  final String? inTime;
  final String? outTime;
  final String? workingHours;
  final String? attendanceStatus;
  final int? punchCount;

  AttendanceData({
    this.empCode,
    this.attDate,
    this.dayName,
    this.inTime,
    this.outTime,
    this.workingHours,
    this.attendanceStatus,
    this.punchCount,
  });

  factory AttendanceData.fromJson(Map<String, dynamic> json) => AttendanceData(
    empCode: json["EmpCode"],
    attDate: json["AttDate"],
    dayName: json["DayName"],
    inTime: json["InTime"],
    outTime: json["OutTime"],
    workingHours: json["WorkingHours"],
    attendanceStatus: json["AttendanceStatus"],
    punchCount: json["PunchCount"],
  );

  Map<String, dynamic> toJson() => {
    "EmpCode": empCode,
    "AttDate": attDate,
    "DayName": dayName,
    "InTime": inTime,
    "OutTime": outTime,
    "WorkingHours": workingHours,
    "AttendanceStatus": attendanceStatus,
    "PunchCount": punchCount,
  };
}

import 'dart:convert';
import 'dart:io';

import 'package:be_call/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as https;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ProductReportView extends StatefulWidget {

  const ProductReportView({super.key});

  @override
  State<ProductReportView> createState() => _ProductReportViewState();
}

class _ProductReportViewState extends State<ProductReportView> {

    List<Map<String, dynamic>> categoryList = [];
        List<Map<String, dynamic>> report = [];

    List<dynamic> staffList = [];
List<dynamic> filteredStaffList = [];
String? selectedStaff;
  List<Map<String, dynamic>> customer = [];
  DateTime? startDate;
DateTime? endDate;


TextEditingController staffSearchCtrl = TextEditingController();


      @override
  void initState() {
    super.initState();
    getproductreport();
    getstaff();
    getProductCategories();
    
  }
Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> getcustomer(var id) async {
    try {
      final token = await getTokenFromPrefs();
      var response = await https.get(
        Uri.parse('$api/api/staff/customers/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status customer: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];
        List<Map<String, dynamic>> managerlist = [];

        for (var productData in productsData) {
          managerlist.add({
            'id': productData['id'],
            'name': productData['name'],
            'created_at': productData['created_at'],
          });
        }

        setState(() {
          customer = managerlist;
          print('Customers: $customer');
        });
      }
    } catch (error) {
      print('Error fetching customers: $error');
    }
  }

 Future<void> getProductCategories() async {
    try {
      final token = await getTokenFromPrefs();
      if (token == null) return;

      final response = await https.get(
        Uri.parse('$api/api/product/category/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        List<Map<String, dynamic>> tempList = [];

        for (var item in parsed) {
          tempList.add({
            'id': item['id'],
            'name': item['category_name'],
          });
        }

        setState(() {
          categoryList = tempList;
        });
        print('Categories: $categoryList');
      }
    } catch (error) {}
  }

  Future<void> getproductreport() async {
  try {
    final token = await getTokenFromPrefs();
    if (token == null) return;

    final response = await https.get(
      Uri.parse('$api/api/staff/custom/order/update/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
print('Response status product report: ${response.statusCode}');
    print('Response body: ${response.body}'); 
    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      setState(() {
        report = List<Map<String, dynamic>>.from(parsed["data"]);
      });
    }
  } catch (e) {
    print(e);
  }
}
CellStyle yellowStyle = CellStyle(
  bold: true,
  fontColorHex: "#000000",
  backgroundColorHex: "#FFFF00", // YELLOW
  horizontalAlign: HorizontalAlign.Center,
);

  
Future<void> getstaff() async {
  try {
    final token = await getTokenFromPrefs();

    var response = await https.get(
      Uri.parse('$api/api/staffs/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Response status staff: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      staffList = parsed['data'];
      filteredStaffList = List.from(staffList);

      setState(() {});
    }
  } catch (error) {
    print(error);
  }
}
void filterStaff(String query) {
  setState(() {
    filteredStaffList = staffList
        .where((s) =>
            s['name'].toString().toLowerCase().contains(query.toLowerCase()))
        .toList();
  });
}

CellStyle greenTotalStyle = CellStyle(
  bold: true,
  fontColorHex: "#000000",
  backgroundColorHex: "#00FF00", // GREEN
  horizontalAlign: HorizontalAlign.Center,
);

Future<void> generateStateProductExcel() async {
  if (selectedStaff == null) return;

  var staff = staffList.firstWhere((s) => s['id'].toString() == selectedStaff);
  List<dynamic> allocatedStates = staff['allocated_states_names'];

  List<String> categories =
      categoryList.map((e) => e['name'].toString()).toList();

  var excel = Excel.createExcel();
Sheet sheetObject = excel['State_Product_Report'];

  // ========================================
  //                STYLES
  // ========================================

  // 🔴 Title row (Red background + BLACK text)
  CellStyle titleStyle = CellStyle(
    bold: true,
    fontColorHex: "#000000",
    backgroundColorHex: "#FF0000",
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    fontSize: 14,
  );

  // 🔵 Header (Light Blue background + BLACK text)
  CellStyle headerStyle = CellStyle(
    bold: true,
    fontColorHex: "#000000",
    backgroundColorHex: "#ADD8E6", // Light blue
    horizontalAlign: HorizontalAlign.Center,
  );

  // 🔴 Red body for zeros (BLACK text)
  CellStyle redBodyStyle = CellStyle(
    bold: false,
    fontColorHex: "#000000",
    backgroundColorHex: "#FF0000",
    horizontalAlign: HorizontalAlign.Center,
  );

  // 🟡 Yellow style (BLACK text)
  CellStyle yellowStyle = CellStyle(
    bold: true,
    fontColorHex: "#000000",
    backgroundColorHex: "#FFFF00",
    horizontalAlign: HorizontalAlign.Center,
  );

  // 🟩 Green totals (BLACK text)
  CellStyle greenTotalStyle = CellStyle(
    bold: true,
    fontColorHex: "#000000",
    backgroundColorHex: "#00FF00",
    horizontalAlign: HorizontalAlign.Center,
  );

  int totalColumns = categories.length + 2;

  // ========================================
  //          ROW 0 → TITLE ROW
  // ========================================
  sheetObject.merge(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
    CellIndex.indexByColumnRow(columnIndex: totalColumns - 1, rowIndex: 0),
  );

  var titleCell =
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
titleCell.value =
    "State Product Report - ${staff['name']} "
    "${startDate != null && endDate != null ? 
      "(${startDate!.toString().substring(0, 10)} to ${endDate!.toString().substring(0, 10)})" 
      : ""}";
  titleCell.cellStyle = titleStyle;

  // ========================================
  //          ROW 1 → EMPTY ROW
  // ========================================
  int emptyTitleRow = 1;
  for (int col = 0; col < totalColumns; col++) {
    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: emptyTitleRow))
        .value = "";
  }

  // ========================================
  //          ROW 2 → HEADER ROW
  // ========================================
  int headerRow = 2;

  sheetObject
      .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: headerRow))
      .value = "STATE";
  sheetObject
      .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: headerRow))
      .cellStyle = headerStyle;

  sheetObject
      .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: headerRow))
      .value = "TOTAL";
  sheetObject
      .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: headerRow))
      .cellStyle = headerStyle;

  for (int c = 0; c < categories.length; c++) {
    var cell = sheetObject.cell(
      CellIndex.indexByColumnRow(columnIndex: c + 2, rowIndex: headerRow),
    );
    cell.value = categories[c];
    cell.cellStyle = headerStyle;
  }

  // ========================================
  //    BUILD STATE-WISE & CATEGORY TOTALS
  // ========================================
  Map<String, Map<int, num>> stateCategoryTotals = {};
  Map<int, num> categoryTotals = {};

    for (var entry in report) {
      bool staffMatch = entry["staff"].toString() == selectedStaff;

String? dateStr = entry["date"];
if (dateStr == null || dateStr.isEmpty) {
  continue; // ⛔ skip entries without date
}

DateTime? entryDate = DateTime.tryParse(dateStr);
if (entryDate == null) {
  continue; // ⛔ skip invalid date formats
}
      bool dateMatch =
          entryDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
              entryDate.isBefore(endDate!.add(const Duration(days: 1)));

   if (staffMatch && dateMatch) {
  String state = entry["customer_state"] ?? "Unknown";

  // 🔥 FIX ADDED
  stateCategoryTotals.putIfAbsent(state, () => {});

  for (var item in entry["items"]) {
    int categoryId = item["category"];
    num qty = item["quantity"];

    stateCategoryTotals[state]!.update(categoryId, (v) => v + qty,
        ifAbsent: () => qty);

        categoryTotals.update(categoryId, (v) => v + qty, ifAbsent: () => qty);
      }
    }
  }

  // ========================================
  //               STATE ROWS
  // ========================================
  for (int r = 0; r < allocatedStates.length; r++) {
    String stateName = allocatedStates[r];
    int rowIndex = headerRow + 1 + r;

    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .value = stateName;

    num totalQty = 0;

    for (int c = 0; c < categories.length; c++) {
      int categoryId = categoryList[c]['id'];
      num qty = 0;

      if (stateCategoryTotals.containsKey(stateName)) {
        qty = stateCategoryTotals[stateName]![categoryId] ?? 0;
      }

      totalQty += qty;

      var cell = sheetObject.cell(
        CellIndex.indexByColumnRow(columnIndex: c + 2, rowIndex: rowIndex),
      );

      if (qty > 0) {
        cell.value = qty;
        cell.cellStyle = yellowStyle;
      } else {
        cell.value = 0;
        cell.cellStyle = redBodyStyle;
      }
    }

    // TOTAL column (Green if >0, else Red)
    var totalCell = sheetObject.cell(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
    );

    if (totalQty > 0) {
      totalCell.value = totalQty;
      totalCell.cellStyle = greenTotalStyle;
    } else {
      totalCell.value = 0;
      totalCell.cellStyle = redBodyStyle;
    }
  }

  // ========================================
  //       EMPTY ROW BEFORE GRAND TOTAL
  // ========================================
  int emptyRow2 = headerRow + 1 + allocatedStates.length;

  for (int col = 0; col < totalColumns; col++) {
    sheetObject
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: emptyRow2))
        .value = "";
  }

  // ========================================
  //            GRAND TOTAL ROW
  // ========================================
  int grandRow = emptyRow2 + 1;

  var gtCell = sheetObject.cell(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: grandRow),
  );
  gtCell.value = "GRAND TOTAL";
  gtCell.cellStyle = yellowStyle;

  num grandTotal = 0;

  for (int c = 0; c < categories.length; c++) {
    int categoryId = categoryList[c]['id'];
    num qty = categoryTotals[categoryId] ?? 0;

    grandTotal += qty;

    var cell = sheetObject.cell(
      CellIndex.indexByColumnRow(columnIndex: c + 2, rowIndex: grandRow),
    );
    cell.value = qty;
    cell.cellStyle = yellowStyle;
  }

  // TOTAL of grand total
  var totalGrandCell = sheetObject.cell(
    CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: grandRow),
  );

  if (grandTotal > 0) {
    totalGrandCell.value = grandTotal;
    totalGrandCell.cellStyle = greenTotalStyle;
  } else {
    totalGrandCell.value = 0;
    totalGrandCell.cellStyle = redBodyStyle;
  }

  // ========================================
  //              SAVE & SHARE
  // ========================================
  final dir = await getTemporaryDirectory();
  final filePath = "${dir.path}/State_Product_Report_${staff['name']}.xlsx";

  File(filePath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(excel.encode()!);

  await Share.shareXFiles([XFile(filePath)],
      text: "State Product Report - ${staff['name']}");
}

 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      elevation: 0,
      toolbarHeight: 70,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1AA48F), Color(0xFF1AA48F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: const Text(
        "Product Report View",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
    ),

    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

  const Text(
            "Select Staff",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1AA48F),
            ),
          ),
                 const SizedBox(height: 8),

Container(
  decoration: BoxDecoration(
    color: Colors.grey[900]!.withOpacity(0.4),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: Color(0xFF1AA48F), width: 1.3),
  ),
  child: TextField(
    controller: staffSearchCtrl,
    style: const TextStyle(color: Colors.white),
    onChanged: (value) => filterStaff(value),
    decoration: const InputDecoration(
      hintText: "Search Staff",
      hintStyle: TextStyle(color: Colors.white54),
      prefixIcon: Icon(Icons.search, color: Color(0xFF1AA48F)),
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  ),
),
          const SizedBox(height: 8),
Container(
  decoration: BoxDecoration(
    color: Colors.grey[900]!.withOpacity(0.5),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: Color(0xFF1AA48F), width: 1.3),
    boxShadow: [
      BoxShadow(
        color: Color(0xFF1AA48F).withOpacity(0.4),
        blurRadius: 12,
        spreadRadius: 0.5,
      ),
    ],
  ),
  child: DropdownButtonFormField<String>(
    dropdownColor: Colors.grey[900],
    isExpanded: true,
    value: selectedStaff,
    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1AA48F)),
    style: const TextStyle(color: Colors.white),
    decoration: const InputDecoration(
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    ),
    items: filteredStaffList.map((s) {
      return DropdownMenuItem(
        value: s['id'].toString(),
        child: Text(
          s['name'],
          style: const TextStyle(color: Colors.white),
        ),
      );
    }).toList(),
   onChanged: (value) async {
  setState(() {
    selectedStaff = value;

    // ⭐ Reset date range to avoid null crash
    startDate = null;
    endDate = null;
  });
  await getcustomer(value);
},

  ),
),

      const SizedBox(height: 20),
      const Text(
        "Select Date Range",
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1AA48F),
        ),
      ),
      const SizedBox(height: 8),

      GestureDetector(
        onTap: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            initialDateRange: startDate != null && endDate != null
                ? DateTimeRange(start: startDate!, end: endDate!)
                : null,
          );

          if (picked != null) {
            setState(() {
              startDate = picked.start;
              endDate = picked.end;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Color(0xFF1AA48F), width: 1.3),
          ),
          child: Text(
            startDate == null
                ? "Select Date Range"
                : "${startDate!.toString().substring(0, 10)}  to  ${endDate!.toString().substring(0, 10)}",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      const SizedBox(height: 20),



 if (selectedStaff != null)
 
  Column(
    children: [
      // ====== STATE PRODUCT REPORT BUTTON ======
      Padding(
        padding: const EdgeInsets.only(top: 30),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            backgroundColor: const Color(0xFF1AA48F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
         onPressed: (startDate != null && endDate != null)
    ? () => generateStateProductExcel()
    : null,

          child: const Text(
            "State Product Report",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      const SizedBox(height: 20),

      // ====== NEW CUSTOMER PRODUCT REPORT BUTTON ======
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          // generateCustomerProductExcel();  // NEW FUNCTION
        },
        child: const Text(
          "Customer Product Report",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  ),


        ],
      ),
    ),
  );
}


}
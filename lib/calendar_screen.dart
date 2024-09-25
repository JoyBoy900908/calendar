import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'menu_drawer.dart';
import 'schedule_widget.dart';
import 'database_helper.dart';

int getFirstDayOfMonth(DateTime date) {
  return DateTime(date.year, date.month, 1).weekday;
}

int getDaysInMonth(DateTime date) {
  return DateTime(date.year, date.month + 1, 0).day;
}

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selectedDate = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> schedules = {};
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    print('Calling _loadSchedules');
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    print('Entered _loadSchedules');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');
    print('User ID: $userId');

    if (userId != null) {
      final Database db = await DatabaseHelper().database;
      List<Map<String, dynamic>> results = await db.query(
        'schedules',
        where: 'userId = ? OR model =?',
        whereArgs: [userId,2],
      );

      print('Query results: $results');

      Map<DateTime, List<Map<String, dynamic>>> newSchedules = {};
      for (var result in results) {
        print('Processing result: $result');
        try {
          DateTime date = DateTime.parse(result['date']);
          print('Parsed date: $date');
          if (newSchedules[date] == null) {
            newSchedules[date] = [];
          }
          newSchedules[date]!.add(result);
        } catch (e) {
          print('Error parsing date: ${result['date']}');
          print('Exception: $e');
        }
      }
      setState(() {
        schedules = newSchedules;
      });

      // 打印日程數據以供調試
      print('Schedules loaded: $schedules');
    }
  }

  List<Widget> _buildScheduleIndicators(DateTime date) {
    List<Widget> indicators = [];
    if (schedules[date] != null) {
      for (var schedule in schedules[date]!) {
        Color color;
        switch (schedule['model']) {
          case 1:
            color = Colors.blue; // 個人行程顏色
            break;
          case 2:
            color = Colors.green; // 多人行程顏色
            break;
          case 3:
            color = Colors.red; // 隱私行程顏色
            break;
          default:
            color = Colors.amber;
        }
        indicators.add(Container(
          width: 8,
          height: 8,
          margin: EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ));
      }
    }
    // 打印日期和對應的指示器信息
    print('Date: $date, Indicators: $indicators');
    return indicators;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFDCDCDC),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  selectedDate = DateTime(selectedDate.year, selectedDate.month - 1);
                  _loadSchedules(); // 更新日程數據
                });
              },
            ),
            Text('${selectedDate.year}年${selectedDate.month}月'),
            IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: () {
                setState(() {
                  selectedDate = DateTime(selectedDate.year, selectedDate.month + 1);
                  _loadSchedules(); // 更新日程數據
                });
              },
            ),
          ],
        ),
      ),
      endDrawer: MenuDrawer(
        onClose: () {
          setState(() {
            _loadSchedules();
          });
        },
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 10.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _buildWeekdayLabel('Sun'),
                _buildWeekdayLabel('Mon'),
                _buildWeekdayLabel('Tue'),
                _buildWeekdayLabel('Wed'),
                _buildWeekdayLabel('Thu'),
                _buildWeekdayLabel('Fri'),
                _buildWeekdayLabel('Sat'),
              ],
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                ),
                itemCount: getDaysInMonth(selectedDate) + getFirstDayOfMonth(selectedDate) - 1,
                itemBuilder: (context, index) {
                  final day = index + 1 - getFirstDayOfMonth(selectedDate);
                  final date = DateTime(selectedDate.year, selectedDate.month, day);
                  return GridTile(
                    child: GestureDetector(
                      onTap: () {
                        if (day > 0) {
                          setState(() {
                            _selectedDay = date;
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12), // 添加灰色邊框
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(day > 0 ? '$day' : ''), // 只有實際的日期顯示數字
                            if (day > 0) ..._buildScheduleIndicators(date),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_selectedDay != null) ScheduleWidget(date: _selectedDay!),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayLabel(String label) {
    return Container(
      alignment: Alignment.center,
      width: 50,
      decoration: BoxDecoration(
        color: Colors.grey[300], // 添加背景顏色
        borderRadius: BorderRadius.circular(10), // 圓角
      ),
      child: Text(label),
    );
  }
}

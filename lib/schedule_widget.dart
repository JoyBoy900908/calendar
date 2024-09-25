import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'chat_page.dart';

class ScheduleWidget extends StatefulWidget {
  final DateTime date;

  ScheduleWidget({required this.date});

  @override
  _ScheduleWidgetState createState() => _ScheduleWidgetState();
}

class _ScheduleWidgetState extends State<ScheduleWidget> {
  bool _isPlaying = false;
  FlutterSoundPlayer _player = FlutterSoundPlayer();

  @override
  void initState() {
    super.initState();
    _player.openPlayer();
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }
  Future<List<Map<String, dynamic>>> _fetchSchedules(DateTime date) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');
    if (userId != null) {
      final Database db = await DatabaseHelper().database;
      List<Map<String, dynamic>> results = await db.query(
        'schedules',
        where: '(userId = ? OR model = ?) AND date = ?',
        whereArgs: [userId, 2, date.toIso8601String().split('T')[0]],
      );
      return results;
    }
    return [];
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchSchedules(widget.date),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('發生錯誤'));
        } else if (snapshot.hasData && snapshot.data!.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(top: 10.0),
            child: Container(
              height: 300.0,
              color: Color(0xFFF8F8FF),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('本日無行程', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        } else {
          return Padding(
            padding: EdgeInsets.only(top: 10.0),
            child: Container(
              height: 300.0,
              color: Color(0xFFF8F8FF),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('本日記事', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        var schedule = snapshot.data![index];
                        return _buildExpandableTile(
                          context,
                          schedule['title'],
                          schedule['description'],
                          _getColor(schedule['model']),
                          _getTypeLabel(schedule['model']),
                          schedule['date'],
                          schedule['model'],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildExpandableTile(BuildContext context, String title, String description, Color color, String typeLabel, String time, int model) {
    return Material(
      color: color,
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(model == 3 ? '[隱密] $time - 隱密' : '[$typeLabel] $time - $title'),
            ),
            Row(
              children: [
                if (model == 2) // 如果是多人行程，顯示聊天按鈕
                  IconButton(
                    icon: Icon(Icons.chat),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChatPage(title: title)),
                      );
                    },
                  ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _editContent(context, title, description, typeLabel, model == 3);
                  },
                ),
              ],
            ),
          ],
        ),
        onExpansionChanged: (bool expanded) {
          if (expanded && model == 3) {
            _showPasswordDialog(context, title, description, time);
          }
        },
        children: <Widget>[
          if(model != 3)
            ListTile(
              title: model == 4
                  ? IconButton(
                icon: Icon( _isPlaying? Icons.pause :Icons.play_arrow ),
                onPressed: () {
                  _playRecording(description); // 使用 description 作為錄音文件路徑
                },
              )
                  : Text(description),
              onTap: () {
                if (model != 4) {
                  _showDetails(context, title, description);
                }
              },
            ),
        ],
      ),
    );
  }
  void _playRecording(String path) async {
    if (_isPlaying) {
      await _player.stopPlayer();
    } else {
      await _player.startPlayer(
        fromURI: path,
        codec: Codec.aacADTS,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
          });
        },
      );
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });

  }
  void _showPasswordDialog(BuildContext context, String title, String description, String time) {
    final _passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('輸入密碼'),
          content: TextField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: '密碼'),
            obscureText: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_passwordController.text == '123') {
                  Navigator.of(context).pop();
                  _showDetails(context, title, description);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('密碼錯誤')),
                  );
                }
              },
              child: Text('確認'),
            ),
          ],
        );
      },
    );
  }

  void _showDetails(BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(description),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('關閉'),
            ),
          ],
        );
      },
    );
  }

  void _editContent(BuildContext context, String title, String description, String typeLabel, bool isPrivacy) {
    final _titleController = TextEditingController(text: title);
    final _descriptionController = TextEditingController(text: description);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('編輯內容'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: '標題'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: '描述'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                // 保存更改邏輯
                Navigator.of(context).pop();
              },
              child: Text('保存'),
            ),
          ],
        );
      },
    );
  }

  Color _getColor(int model) {
    switch (model) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      default:
        return Colors.amber;
    }
  }

  String _getTypeLabel(int model) {
    switch (model) {
      case 1:
        return '個人';
      case 2:
        return '多人';
      case 3:
        return '隱私';
      default:
        return '錄音';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'database_helper.dart';
import 'dart:io';

class MenuDrawer extends StatefulWidget {
  final VoidCallback onClose; // 添加回調函數
  MenuDrawer({required this.onClose});

  @override
  _MenuDrawerState createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _initializePlayer();
  }

  @override
  void dispose() {
    super.dispose();
  }
  Future<void> _initializeRecorder() async {
    await _audioRecorder.openRecorder();
    if (await Permission.microphone.request().isGranted) {
      print("init is ok");
    } else {
      print("NO MC");
    }
  }
  Future<void> _initializePlayer() async {
    await _audioPlayer.openPlayer();
  }
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 50.0,
            color: Color(0xFFDCDCDC),
            child: Center(child: Text('功能', style: TextStyle(fontSize: 24))),
          ),
          ListTile(
            title: Text('建立行程'),
            onTap: () {
              Navigator.pop(context);
              _showCreateScheduleOptions(context);
            },
          ),
        ],
      ),
    );
  }

  void _showCreateScheduleOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('選擇行程類型'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text('個人行程'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditScheduleDialog(context, '個人行程', 1);
                },
              ),
              ListTile(
                title: Text('多人行程'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditScheduleDialog(context, '多人行程', 2);
                },
              ),
              ListTile(
                title: Text('隱私行程'),
                onTap: () {
                  Navigator.pop(context);
                  _showPrivacyScheduleDialog(context);
                },
              ),
              ListTile(
                title: Text('錄音行程'),
                onTap: () {
                  Navigator.pop(context);
                  _showaudio(context, '錄音行程', 4);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  Future<void> _startRecording() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      _audioPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
      await _audioRecorder.startRecorder(
        toFile: _audioPath,
        codec: Codec.aacADTS,
      );
    } catch (e) {
      print("錄音失敗: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stopRecorder();
    } catch (e) {
      print("停止錄音失敗: $e");
    }
  }

  void _showaudio(BuildContext context, String scheduleType, int model) {
    final _titleController = TextEditingController();
    final _dateController = TextEditingController(
        text: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}"
    );
    Future<void> _playRecording() async {
      try {
        if (_audioPath != null) {
          await _audioPlayer.startPlayer(
            fromURI: _audioPath,
            codec: Codec.aacADTS,
            whenFinished: () {
              setState(() {
                _isPlaying = false;
              });
            },
          );
          setState(() {
            _isPlaying = true;
          });
        }
      } catch (e) {
        print("播放失敗: $e");
      }
    }

    Future<void> _stopPlaying() async {
      try {
        await _audioPlayer.stopPlayer();
        setState(() {
          _isPlaying = false;
        });
      } catch (e) {
        print("停止播放失敗: $e");
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('編輯 $scheduleType'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: '標題'),
                  ),
                  TextField(
                    controller: _dateController,
                    decoration: InputDecoration(labelText: '日期'),
                    onTap: () async {
                      FocusScope.of(context).requestFocus(new FocusNode());
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        _dateController.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                      }
                    },
                  ),
                  SizedBox(height: 20),
                  _isRecording
                      ? Text("錄音中...")
                      : Text(_audioPath != null ? "錄音完成" : "未錄音"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          if (_isRecording) {
                            await _stopRecording();
                          } else {
                            await _startRecording();
                          }
                          setState(() {
                            _isRecording = !_isRecording;
                          });
                        },
                        child: Text(_isRecording ? '停止錄音' : '開始錄音'),
                      ),
                      if (!_isRecording && _audioPath != null)
                        ElevatedButton(
                          onPressed: () async {
                            if (_isPlaying) {
                              await _stopPlaying();
                            } else {
                              await _playRecording();
                            }
                          },
                          child: Text(_isPlaying ? '停止播放' : '播放錄音'),
                        ),
                    ],
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
                  onPressed: () async {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    int? userId = prefs.getInt('userId');

                    if (userId != null && _audioPath != null) {
                      await _saveSchedule(
                        _titleController.text,
                        _audioPath!,
                        _dateController.text,
                        model,
                        userId,
                      );
                    }

                    Navigator.of(context).pop();
                    widget.onClose();
                    await _audioRecorder.closeRecorder();
                  },
                  child: Text('確認'),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _showPrivacyScheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final _passwordController = TextEditingController();

        return AlertDialog(
          title: Text('輸入密碼'),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: '密碼'),
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
                  _showEditScheduleDialog(context, '隱私行程', 3);
                } else {
                  Navigator.of(context).pop();
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

  void _showEditScheduleDialog(BuildContext context, String scheduleType, int model) {
    final _titleController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _dateController = TextEditingController(
        text: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}"
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('編輯 $scheduleType'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if(model == 2)
                TextField(
                  decoration: InputDecoration(labelText: '共享使用者'),
                ),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: '標題'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: '描述'),
              ),
              TextField(
                controller: _dateController,
                decoration: InputDecoration(labelText: '日期'),
                onTap: () async {
                  FocusScope.of(context).requestFocus(new FocusNode());
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    _dateController.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                  }
                },
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
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                int? userId = prefs.getInt('userId');

                if (userId != null) {
                  await _saveSchedule(
                    _titleController.text,
                    _descriptionController.text,
                    _dateController.text,
                    model,
                    userId,
                  );
                }

                Navigator.of(context).pop();
                widget.onClose();
              },
              child: Text('確認'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _saveSchedule(String title, String description, String date, int model, int userId) async {
    final Database db = await DatabaseHelper().database;

    // 將日期轉換為 ISO 8601 格式
    DateTime parsedDate = DateTime.parse(date);
    String formattedDate = parsedDate.toIso8601String().split('T')[0]; // 確保日期格式為 YYYY-MM-DD

    // 準備要插入的數據
    Map<String, dynamic> scheduleData = {
      'title': title,
      'description': description,
      'date': formattedDate,
      'model': model,
      'userId': userId,
    };

    // 插入數據
    await db.insert(
      'schedules',
      scheduleData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 查詢所有數據並打印
    List<Map<String, dynamic>> results = await db.query('schedules');
    print('All schedules:');
    for (var result in results) {
      print(result);
    }
  }
}

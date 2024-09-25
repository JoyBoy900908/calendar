import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

class ChatPage extends StatelessWidget {
  final String title;

  ChatPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$title 的聊天'),
      ),
      body: ChatScreen(chatTitle: title),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String chatTitle;

  ChatScreen({required this.chatTitle});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');
    currentUserId = userId == 1 ? 'aaa' : userId == 2 ? 'bbb' : '你';

    final messages = await DatabaseHelper().getMessages(widget.chatTitle);

    setState(() {
      print('Messages table content:');
      for (var message in messages) {
        print(message);
        final chatMessage = ChatMessage(
          text: message['content'],
          sender: message['userId'] == userId ? '你' : (message['userId'] == 1 ? 'aaa' : 'bbb'),
          animationController: AnimationController(
            duration: const Duration(milliseconds: 300),
            vsync: this,
          ),
        );
        _messages.insert(0, chatMessage);
        chatMessage.animationController.forward(); // 啟動動畫控制器
      }
    });

    // 日誌打印消息數組的內容
    print('Loaded messages:');
    for (var message in _messages) {
      print(message.text);
    }
  }


  void _handleSubmitted(String text) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');
    currentUserId ='你';

    _textController.clear();
    ChatMessage message = ChatMessage(
      text: text,
      sender: currentUserId,
      animationController: AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );
    setState(() {
      _messages.insert(0, message);
    });
    message.animationController.forward();
    await DatabaseHelper().insertMessage(widget.chatTitle, text, userId!);

    // 日誌打印提交後的消息數組內容
    print('Submitted messages:');
    for (var message in _messages) {
      print(message.text);
    }
  }

  @override
  void dispose() {
    for (ChatMessage message in _messages) {
      message.animationController.dispose();
    }
    super.dispose();
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration.collapsed(hintText: "發送訊息"),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Flexible(
          child: ListView.builder(
            padding: EdgeInsets.all(8.0),
            reverse: true,
            itemBuilder: (_, int index) => _messages[index],
            itemCount: _messages.length,
          ),
        ),
        Divider(height: 1.0),
        Container(
          decoration: BoxDecoration(color: Theme.of(context).cardColor),
          child: _buildTextComposer(),
        ),
      ],
    );
  }
}

class ChatMessage extends StatelessWidget {
  ChatMessage({required this.text, required this.sender, required this.animationController});

  final String text;
  final String sender;
  final AnimationController animationController;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOut,
      ),
      axisAlignment: 0.0,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(child: Text(sender.substring(0, 1))),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(sender, style: Theme.of(context).textTheme.headlineSmall),
                  Container(
                    margin: const EdgeInsets.only(top: 5.0),
                    child: Text(text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:chat_janry_app/model/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Janry',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        dialogBackgroundColor: Colors.white,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {

  TextEditingController messageTextController = TextEditingController();
  final List<Messages> _historyList = List.empty(growable: true);

  String apiKey = '';
  String streamText = '';

  static const String _kStrings = 'Flutter ChatGPT';

  String get _currentString => _kStrings;

  ScrollController scrollController = ScrollController();
  late Animation<int> _characterCount;
  late AnimationController animationController;

  void _scrollDown() {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 350),
      curve: Curves.fastOutSlowIn
    );
  }

  setupAnimations() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500)
    );
    _characterCount = StepTween(begin: 0, end: _currentString.length).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeIn
      )
    );
    animationController.addListener(() {
      setState(() {});
    });
    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 1)).then((value) {
          animationController.reverse();
        });
      } else if (status == AnimationStatus.dismissed) {
        Future.delayed(const Duration(seconds: 1)).then((value) {
          animationController.forward();
        });
      }
    });

    animationController.forward();
  }

  Future requestChat(String text) async {
    ChatCompletionModel openAiModel = ChatCompletionModel(
      model: 'gpt-3.5-turbo',
      messages: [
        Messages(
          role: 'system',
          content: 'You are a helpful assistant.'
        ),
        ..._historyList
      ],
      stream: false
    );
    final url = Uri.https('api.openai.com', 'v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(openAiModel.toJson())
    );
    print(response.body);
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      String role = jsonData['choices'][0]['message']['role'];
      String content = jsonData['choices'][0]['message']['content'];
      _historyList.last = _historyList.last.copyWidth(
        role: role,
        content: content
      );
      setState(() {
        _scrollDown();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    setupAnimations();
  }

  @override
  void dispose() {
    messageTextController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future clearChat() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새로운 대화의 시작'),
        content: const Text('새로운 대화를 시작하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                messageTextController.clear();
                _historyList.clear();
              });
            },
            child: const Text('네')
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Card(
                  child: PopupMenuButton(
                    itemBuilder: (context) {
                      return [
                        const PopupMenuItem(
                          child: ListTile(
                            title: Text('History'),
                          )
                        ),
                        const PopupMenuItem(
                          child: ListTile(
                            title: Text('Settings'),
                          )
                        ),
                        PopupMenuItem(
                          onTap: () {
                            clearChat();
                          },
                          child: const ListTile(
                            title: Text('New chat'),
                          )
                        )
                      ];
                    }
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _historyList.isEmpty ? Center(
                    child: AnimatedBuilder(
                      animation: _characterCount,
                      builder: (BuildContext context, Widget? child) {
                        String text = _currentString.substring(0, _characterCount.value);
                        return Row(
                          children: [
                            Text(
                              text,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24
                              ),
                            ),
                            CircleAvatar(
                              radius: 8,
                              backgroundColor: Colors.orange[200],
                            )
                          ],
                        );
                      },
                    ),
                  ) : GestureDetector(
                        onTap: () => FocusScope.of(context).unfocus(),
                        child: ListView.builder(
                          itemCount: _historyList.length,
                          itemBuilder: (context, index) {
                            if (_historyList[index].role == 'user') {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const CircleAvatar(),
                                    const SizedBox(width: 8,),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('User'),
                                          Text(_historyList[index].content)
                                        ],
                                      )
                                    )
                                  ],
                                ),
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(backgroundColor: Colors.teal,),
                                const SizedBox(width: 8,),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Janry'),
                                      Text(_historyList[index].content)
                                    ],
                                  )
                                )
                              ],
                            );
                          }
                        ),
                  )
                )
              ),
              Dismissible( // 해당 탭 슬라이스 효과
                key: const Key('chat-bar'), // 필수 값
                direction: DismissDirection.startToEnd,
                onDismissed: (d) {
                  // d 는 direction
                  if (d == DismissDirection.startToEnd) {
                    // logic
                  }
                },
                background: const Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('New chat')
                  ],
                ),
                confirmDismiss: (d) async {
                  // d 는 direction
                  if (d == DismissDirection.startToEnd) {
                    if (_historyList.isEmpty) return;
                    clearChat();
                  }
                  return null;
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all()
                        ),
                        child: TextField(
                          controller: messageTextController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Message'
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      iconSize: 42,
                      onPressed: () async {
                        if (messageTextController.text.isEmpty) {
                          // messageTextController 입력 값이 없을 때
                          return;
                        }
                        // 입력 버튼을 누르면 history에 데이터 쌓기
                        setState(() {
                          _historyList.add(Messages(
                            role: 'user',
                            content: messageTextController.text.trim()
                          ));
                          _historyList.add(Messages(
                            role: 'assistant',
                            content: ''
                          ));
                        });
                        try {
                          print(messageTextController.text);
                          await requestChat(messageTextController.text.trim());
                          messageTextController.clear();
                          streamText = '';
                        } catch (e) {
                          print(e.toString());
                        }
                      },
                      icon: const Icon(Icons.arrow_circle_up)
                    )
                  ],
                ),
              )
            ],
          ),
        )
      ),
    );
  }
}
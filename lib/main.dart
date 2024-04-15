import 'package:flutter/material.dart';

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

  static const String _kStrings = 'Flutter ChatGPT';

  String get _currentString => _kStrings;

  ScrollController scrollController = ScrollController();
  late Animation<int> _characterCount;
  late AnimationController animationController;

  setupAnimations () {
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
                        const PopupMenuItem(
                          child: ListTile(
                            title: Text('New chat'),
                          )
                        )
                      ];
                    }
                  ),
                ),
              ),
              Expanded(
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
                    // logic
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
                      onPressed: (){},
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
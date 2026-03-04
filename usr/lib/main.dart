import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const SnakeGameApp());
}

class SnakeGameApp extends StatelessWidget {
  const SnakeGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kids Snake Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        fontFamily: 'Rounded', // Uses system font but implies rounded style
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SnakeGamePage(),
      },
    );
  }
}

class SnakeGamePage extends StatefulWidget {
  const SnakeGamePage({super.key});

  @override
  State<SnakeGamePage> createState() => _SnakeGamePageState();
}

enum Direction { up, down, left, right }
enum GameStatus { idle, playing, paused, gameOver }

class _SnakeGamePageState extends State<SnakeGamePage> {
  // Game Configuration
  static const int rows = 20;
  static const int columns = 20;
  
  // State
  List<Point<int>> snake = [const Point(10, 10), const Point(10, 11), const Point(10, 12)];
  Point<int> food = const Point(5, 5);
  Direction direction = Direction.up;
  Direction? nextDirection; 
  GameStatus status = GameStatus.idle;
  Timer? timer;
  int score = 0;
  Color snakeColor = Colors.green;
  Color foodColor = Colors.redAccent;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startGame() {
    setState(() {
      snake = [const Point(10, 10), const Point(10, 11), const Point(10, 12)];
      direction = Direction.up;
      nextDirection = Direction.up;
      score = 0;
      status = GameStatus.playing;
      generateFood();
    });
    timer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      gameTick();
    });
  }

  void pauseGame() {
    if (status == GameStatus.playing) {
      setState(() {
        status = GameStatus.paused;
      });
      timer?.cancel();
    } else if (status == GameStatus.paused) {
      setState(() {
        status = GameStatus.playing;
      });
      timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
        gameTick();
      });
    }
  }

  void generateFood() {
    final random = Random();
    Point<int> newFood;
    do {
      newFood = Point(random.nextInt(columns), random.nextInt(rows));
    } while (snake.contains(newFood));
    
    setState(() {
      food = newFood;
      List<Color> foodColors = [Colors.red, Colors.orange, Colors.purple, Colors.blue];
      foodColor = foodColors[random.nextInt(foodColors.length)];
    });
  }

  void gameTick() {
    setState(() {
      if (nextDirection != null) {
        direction = nextDirection!;
      }

      Point<int> currentHead = snake.first;
      Point<int> newHead;

      switch (direction) {
        case Direction.up:
          newHead = Point(currentHead.x, currentHead.y - 1);
          break;
        case Direction.down:
          newHead = Point(currentHead.x, currentHead.y + 1);
          break;
        case Direction.left:
          newHead = Point(currentHead.x - 1, currentHead.y);
          break;
        case Direction.right:
          newHead = Point(currentHead.x + 1, currentHead.y);
          break;
      }

      if (newHead.x < 0 || newHead.x >= columns || newHead.y < 0 || newHead.y >= rows || snake.contains(newHead)) {
        gameOver();
        return;
      }

      snake.insert(0, newHead);

      if (newHead == food) {
        score++;
        generateFood();
      } else {
        snake.removeLast();
      }
    });
  }

  void gameOver() {
    timer?.cancel();
    setState(() {
      status = GameStatus.gameOver;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Oops!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sentiment_dissatisfied, size: 60, color: Colors.orange),
            const SizedBox(height: 10),
            Text("You hit something!\nYour Score: $score", 
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, color: Colors.black87)
            ),
          ],
        ),
        actions: [
          Center(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                startGame();
              },
              child: const Text("Play Again", style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  void changeDirection(Direction newDir) {
    if (status != GameStatus.playing) return;
    
    if (direction == Direction.up && newDir == Direction.down) return;
    if (direction == Direction.down && newDir == Direction.up) return;
    if (direction == Direction.left && newDir == Direction.right) return;
    if (direction == Direction.right && newDir == Direction.left) return;

    nextDirection = newDir;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: const Text("🐛 Hungry Snake 🍎", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowUp): () => changeDirection(Direction.up),
          const SingleActivator(LogicalKeyboardKey.arrowDown): () => changeDirection(Direction.down),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => changeDirection(Direction.left),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => changeDirection(Direction.right),
        },
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Determine if we are in landscape/wide mode (iPad/Tablet/Desktop)
              // iPad Portrait width is usually > 700, but let's use 600 as a safe breakpoint for "wide layout"
              // Actually, for iPad Portrait, we might still want the Column layout if it's tall.
              // Let's check aspect ratio or width.
              bool isWide = constraints.maxWidth > 600 && constraints.maxWidth > constraints.maxHeight;
              
              if (isWide) {
                return _buildLandscapeLayout();
              } else {
                return _buildPortraitLayout();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildScoreBoard(),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(child: _buildGameBoard()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: _buildControls(),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(child: _buildGameBoard()),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.white.withOpacity(0.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                _buildScoreBoard(),
                const SizedBox(height: 40),
                // Scale up controls for iPad landscape
                Transform.scale(
                  scale: 1.2,
                  child: _buildControls(),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBoard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.green, width: 3),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Text("Score: $score", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
        ),
        const SizedBox(width: 20),
        if (status == GameStatus.idle)
          FilledButton.icon(
            onPressed: startGame,
            icon: const Icon(Icons.play_arrow, size: 30),
            label: const Text("Start", style: TextStyle(fontSize: 24)),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          )
        else if (status == GameStatus.playing || status == GameStatus.paused)
          IconButton(
            onPressed: pauseGame,
            icon: Icon(status == GameStatus.playing ? Icons.pause_circle : Icons.play_circle, size: 56, color: Colors.orange),
            tooltip: status == GameStatus.playing ? "Pause" : "Resume",
          ),
      ],
    );
  }

  Widget _buildGameBoard() {
    return AspectRatio(
      aspectRatio: columns / rows,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.green.shade300, width: 8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellSize = constraints.maxWidth / columns;
              return Stack(
                children: [
                  // Grid Background
                  ...List.generate(rows, (y) => 
                    List.generate(columns, (x) => 
                      Positioned(
                        left: x * cellSize,
                        top: y * cellSize,
                        child: Container(
                          width: cellSize,
                          height: cellSize,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                        ),
                      )
                    )
                  ).expand((element) => element),
          
                  // Food
                  Positioned(
                    left: food.x * cellSize,
                    top: food.y * cellSize,
                    child: SizedBox(
                      width: cellSize,
                      height: cellSize,
                      child: Center(
                        child: Icon(Icons.apple, color: foodColor, size: cellSize * 0.85),
                      ),
                    ),
                  ),
          
                  // Snake
                  ...snake.map((part) {
                    final isHead = part == snake.first;
                    return Positioned(
                      left: part.x * cellSize,
                      top: part.y * cellSize,
                      child: Container(
                        width: cellSize,
                        height: cellSize,
                        decoration: BoxDecoration(
                          color: isHead ? Colors.green.shade700 : Colors.green,
                          shape: BoxShape.circle,
                          boxShadow: isHead ? [const BoxShadow(color: Colors.black26, blurRadius: 4)] : null,
                        ),
                        child: isHead 
                          ? const Center(child: Text("👀", style: TextStyle(fontSize: 14))) 
                          : null,
                      ),
                    );
                  }),
                  
                  if (status == GameStatus.idle)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10)],
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Ready?", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green)),
                            SizedBox(height: 16),
                            Text("Eat apples to grow!\nDon't hit the walls!", 
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 20, color: Colors.grey)
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlButton(Icons.keyboard_arrow_up, Direction.up),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildControlButton(Icons.keyboard_arrow_left, Direction.left),
              const SizedBox(width: 60), 
              _buildControlButton(Icons.keyboard_arrow_right, Direction.right),
            ],
          ),
          _buildControlButton(Icons.keyboard_arrow_down, Direction.down),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, Direction dir) {
    return Material(
      color: Colors.orange.shade400,
      shape: const CircleBorder(),
      elevation: 8,
      child: InkWell(
        onTap: () => changeDirection(dir),
        customBorder: const CircleBorder(),
        splashColor: Colors.orange,
        child: Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          child: Icon(icon, size: 50, color: Colors.white),
        ),
      ),
    );
  }
}

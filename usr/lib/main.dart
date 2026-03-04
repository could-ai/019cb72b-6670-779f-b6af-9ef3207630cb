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
  static const double gameSpeed = 300; // Milliseconds (slower for kids)

  // State
  List<Point<int>> snake = [const Point(10, 10), const Point(10, 11), const Point(10, 12)];
  Point<int> food = const Point(5, 5);
  Direction direction = Direction.up;
  Direction? nextDirection; // Prevent rapid double turns
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
      // Randomize food color for fun
      List<Color> foodColors = [Colors.red, Colors.orange, Colors.purple, Colors.blue];
      foodColor = foodColors[random.nextInt(foodColors.length)];
    });
  }

  void gameTick() {
    setState(() {
      // Update direction if a new one was queued
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

      // Check Collisions (Walls or Self)
      if (newHead.x < 0 || newHead.x >= columns || newHead.y < 0 || newHead.y >= rows || snake.contains(newHead)) {
        gameOver();
        return;
      }

      snake.insert(0, newHead);

      if (newHead == food) {
        score++;
        generateFood();
        // Don't remove tail, so it grows
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
    
    // Prevent reversing direction directly
    if (direction == Direction.up && newDir == Direction.down) return;
    if (direction == Direction.down && newDir == Direction.up) return;
    if (direction == Direction.left && newDir == Direction.right) return;
    if (direction == Direction.right && newDir == Direction.left) return;

    nextDirection = newDir;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Light yellow/cream background
      appBar: AppBar(
        title: const Text("🐛 Hungry Snake 🍎", style: TextStyle(fontWeight: FontWeight.bold)),
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
          child: Column(
            children: [
              // Score Board
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: Text("Score: $score", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                    ),
                    if (status == GameStatus.idle)
                      FilledButton.icon(
                        onPressed: startGame,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text("Start Game"),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      )
                    else if (status == GameStatus.playing || status == GameStatus.paused)
                      IconButton(
                        onPressed: pauseGame,
                        icon: Icon(status == GameStatus.playing ? Icons.pause_circle : Icons.play_circle, size: 48, color: Colors.orange),
                      ),
                  ],
                ),
              ),
              
              // Game Board
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AspectRatio(
                    aspectRatio: columns / rows,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.green.shade300, width: 5),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final cellSize = constraints.maxWidth / columns;
                            return Stack(
                              children: [
                                // Grid Background (Subtle)
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
                                      child: Icon(Icons.apple, color: foodColor, size: cellSize * 0.9),
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
                                        shape: BoxShape.circle, // Rounded segments
                                        boxShadow: isHead ? [const BoxShadow(color: Colors.black26, blurRadius: 4)] : null,
                                      ),
                                      child: isHead 
                                        ? const Center(child: Text("👀", style: TextStyle(fontSize: 12))) // Cute eyes
                                        : null,
                                    ),
                                  );
                                }),
                                
                                if (status == GameStatus.idle)
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.95),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10)],
                                      ),
                                      child: const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text("Ready?", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
                                          SizedBox(height: 10),
                                          Text("Eat apples to grow!\nDon't hit the walls!", 
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 18, color: Colors.grey)
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
                  ),
                ),
              ),
        
              // Controls
              Padding(
                padding: const EdgeInsets.only(bottom: 30.0, top: 10),
                child: Column(
                  children: [
                    _buildControlButton(Icons.keyboard_arrow_up, Direction.up),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildControlButton(Icons.keyboard_arrow_left, Direction.left),
                        const SizedBox(width: 60), // Space for down button
                        _buildControlButton(Icons.keyboard_arrow_right, Direction.right),
                      ],
                    ),
                    _buildControlButton(Icons.keyboard_arrow_down, Direction.down),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, Direction dir) {
    return Material(
      color: Colors.orange.shade300,
      shape: const CircleBorder(),
      elevation: 6,
      child: InkWell(
        onTap: () => changeDirection(dir),
        customBorder: const CircleBorder(),
        splashColor: Colors.orange,
        child: Container(
          width: 75,
          height: 75,
          alignment: Alignment.center,
          child: Icon(icon, size: 45, color: Colors.white),
        ),
      ),
    );
  }
}

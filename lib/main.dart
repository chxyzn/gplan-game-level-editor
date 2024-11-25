import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final NODE_RADIUS = 20.r;

void main() async {
  runApp(const DrawingBoard());
}

class DrawingBoard extends StatefulWidget {
  const DrawingBoard({super.key});

  @override
  State<DrawingBoard> createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  int gridCrossAxisCount = 1;
  int gridMainAxisCount = 1;
  int activeIndex = 0;
  List<Node> edgeConsumer = [];
  List<Edge> edges = [];
  List<List<int>> grid = [];

  final List<Node> nodes = [];
  final TextEditingController xController = TextEditingController();
  final TextEditingController yController = TextEditingController();

  void setGrid(int columns, int rows) {
    print("Setting Grid");
    print("Rows : $rows");
    print("Columns : $columns");
    grid = List.generate(
      rows,
      (i) => List.generate(
        columns,
        (j) => 0,
        growable: false,
      ),
      growable: false,
    );

    for (int i = 0; i < grid.length; i++) {
      print(grid[i]);
    }
  }

  void addToEdge(Node node) {
    edgeConsumer.add(node);
    addEdge();
  }

  void addEdge() {
    if (edgeConsumer.length == 2) {
      if (edgeConsumer[0] == edgeConsumer[1]) {
        edgeConsumer.clear();
        return;
      }

      setState(() {
        edgeConsumer[0].isSelected = false;
        edgeConsumer[1].isSelected = false;

        edges.add(Edge(
          start: edgeConsumer[0],
          end: edgeConsumer[1],
          color: Colors.black,
        ));
        edgeConsumer.clear();
      });
    }
  }

  bool isNodeClash(Node node) {
    for (final n in nodes) {
      if ((n.position - node.position).distance < NODE_RADIUS * 2) {
        return true;
      }
    }
    return false;
  }

  String exportTojson() {
    Map<String, dynamic> json = {};

    Map<String, dynamic> grid = {
      "row_size": gridMainAxisCount,
      "column_size": gridCrossAxisCount,
    };

    Map<String, dynamic> graph = {};
    List<Map<String, dynamic>> nodesJson = [];

    for (final node in nodes) {
      Map<String, dynamic> nodeJson = {
        "id": node.id + 1,
        "shape": getShapeForjson(node.id),
      };
      nodesJson.add(nodeJson);
    }

    List<List<int>> edgesJson = [];

    for (final edge in edges) {
      edgesJson.add([edge.start.id, edge.end.id]);
    }
    graph["nodes"] = nodesJson;
    graph["edges"] = edgesJson;

    json["grid"] = grid;
    json["graph"] = graph;

    return jsonEncode(json);
  }

  List<List<int>> getShapeForjson(int id) {
    List<List<int>> shape = List.generate(
      gridMainAxisCount,
      (i) => List.generate(
        gridCrossAxisCount,
        (j) => 0,
        growable: false,
      ),
      growable: false,
    );

    for (int i = 0; i < shape.length; i++) {
      for (int j = 0; j < shape.first.length; j++) {
        if (grid[i][j] == id) {
          shape[i][j] = 1;
        }
      }
    }

    //write a function to print the shape
    for (int i = 0; i < shape.length; i++) {
      print(shape[i]);
    }
    print("-----------------");
    return shape;
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(411, 914),
      splitScreenMode: false,
      builder: (context, child) {
        return MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Drawing Board'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      nodes.clear();
                      edges.clear();
                    });
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(
                    height: 600.h,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTapDown: (details) {
                            Node n = Node(
                              id: nodes.length,
                              position: details.localPosition,
                              radius: NODE_RADIUS,
                              color: Colors.blue,
                            );

                            if (isNodeClash(n)) {
                              return;
                            }
                            setState(() {
                              nodes.add(n);
                            });
                          },
                          child: Container(
                            height: double.infinity,
                            width: double.infinity,
                            color: Colors.white,
                          ),
                        ),
                        ...edges.map((edge) {
                          return CustomPaint(
                            painter: LinePainter(
                              start: edge.start.position,
                              end: edge.end.position,
                              color: edge.color,
                            ),
                          );
                        }),
                        ...nodes.map((node) {
                          return Positioned(
                            left: node.position.dx - node.radius,
                            top: node.position.dy - node.radius,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  node.isSelected = true;
                                  addToEdge(node);
                                });
                              },
                              child: Container(
                                width: node.radius * 2,
                                height: node.radius * 2,
                                decoration: BoxDecoration(
                                  color: (node.isSelected)
                                      ? Colors.grey
                                      : node.color,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    node.id.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const Divider(),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(bottom: 40.h),
                    color: Colors.white,
                    child: Column(
                      children: [
                        const Text(
                          "Floorplan Editor",
                          textAlign: TextAlign.center,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                              width: 50.w,
                              child: TextField(
                                controller: xController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 50.w,
                              child: TextField(
                                controller: yController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ),
                            TextButton(
                                onPressed: () {
                                  setState(() {
                                    gridCrossAxisCount =
                                        int.parse(xController.text);
                                    gridMainAxisCount =
                                        int.parse(yController.text);
                                    setGrid(
                                        gridCrossAxisCount, gridMainAxisCount);
                                  });
                                },
                                child: const Text("Set Grid Dimensions"))
                          ],
                        ),
                        Center(
                          child: Text("Active Node : $activeIndex"),
                        ),
                        Center(
                          child: SizedBox(
                            height: 40.h,
                            width: 300.w,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: nodes.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: EdgeInsets.only(right: 8.w),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        activeIndex = index;
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 19.w),
                                      color: (activeIndex == index)
                                          ? Colors.grey
                                          : Colors.blue,
                                      child:
                                          Center(child: Text(index.toString())),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 80.h),
                        SizedBox(
                          height: gridMainAxisCount * 54.r + 50.h,
                          width: gridCrossAxisCount * 54.r + 50.w,
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: gridCrossAxisCount,
                            ),
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: gridCrossAxisCount * gridMainAxisCount,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    grid[index ~/ gridCrossAxisCount]
                                            [index % gridCrossAxisCount] =
                                        activeIndex;
                                  });
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(2.w),
                                  child: Container(
                                    height: 35.r,
                                    width: 35.r,
                                    color: Colors.black,
                                    child: Center(
                                      child: Text(
                                        grid[index ~/ gridCrossAxisCount]
                                                [index % gridCrossAxisCount]
                                            .toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 20.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: EdgeInsets.only(bottom: 40.h),
                    child: ElevatedButton(
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: exportTojson()));
                      },
                      child: const Text("Export"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class LinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;

  LinePainter({
    required this.start,
    required this.end,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class Node {
  final Offset position;
  final double radius;
  final Color color;
  final int id;
  bool isSelected = false;

  Node({
    required this.id,
    required this.position,
    required this.radius,
    required this.color,
  });
}

class Edge {
  final Node start;
  final Node end;
  final Color color;

  Edge({
    required this.start,
    required this.end,
    required this.color,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';
import 'game_provider.dart';
import 'models.dart';
import 'theme.dart';

class SchemaTab extends ConsumerStatefulWidget {
  const SchemaTab({super.key});

  @override
  ConsumerState<SchemaTab> createState() => _SchemaTabState();
}

class _SchemaTabState extends ConsumerState<SchemaTab> {
  final Graph graph = Graph()..isTree = true;
  late BuchheimWalkerConfiguration builder;

  @override
  void initState() {
    super.initState();
    builder = BuchheimWalkerConfiguration()
      ..siblingSeparation = (50)
      ..levelSeparation = (100)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);
  }

  void _buildGraph(Map<String, NarrativeNode> allNodes) {
    graph.nodes.clear();
    graph.edges.clear();
    
    // Map nodes to GraphView nodes
    Map<String, Node> visualNodes = {};
    for (var id in allNodes.keys) {
      visualNodes[id] = Node.Id(id);
    }

    // Add edges based on choices
    for (var node in allNodes.values) {
      for (var choice in node.choices) {
        if (visualNodes.containsKey(choice.nextId)) {
          graph.addEdge(visualNodes[node.id]!, visualNodes[choice.nextId]!);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider.notifier);
    _buildGraph(gameState.getAllNodes()); // Ensure you expose a getter for _allNodes

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Narrative DAG Schema", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Expanded(
            child: InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 0.1,
              maxScale: 2.0,
              child: GraphView(
                graph: graph,
                algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
                paint: Paint()..color = AppColors.surfaceLight..strokeWidth = 2,
                builder: (Node node) {
                  var nodeId = node.key!.value as String;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      border: Border.all(color: AppColors.primaryAction, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Node $nodeId', style: const TextStyle(color: Colors.white)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
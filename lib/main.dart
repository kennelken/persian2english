import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Persian to English',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const HomePage(title: 'Persian to English translator'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _textController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 600,
          height: 230,
          child: FutureBuilder<Map<String, String>>(
              future: _getTranslationsFromFile(),
              builder: (context, snapshot) {
                var suggestionsTree = _buildSuggestionsTree(snapshot.data);
                return Material(
                  borderRadius: Style.border,
                  color: Colors.orange.shade100,
                  child: Center(
                    child: Padding(
                      padding: Style.paddingOuter,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: Style.padding,
                            child: TypeAheadField<String>(
                              textFieldConfiguration: TextFieldConfiguration(
                                controller: _textController,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(borderRadius: Style.border),
                                  hintText: "Enter a persian word",
                                ),
                              ),
                              suggestionsCallback: (pattern) async {
                                return await _getSuggestions(pattern, suggestionsTree);
                              },
                              itemBuilder: (context, suggestion) {
                                return Text(
                                  suggestion,
                                  style: TextStyle(fontSize: 20),
                                );
                              },
                              onSuggestionSelected: (suggestion) {
                                _textController.text = suggestion;
                              },
                              hideOnEmpty: true,
                              minCharsForSuggestions: 1,
                              loadingBuilder: (context) => const SizedBox(),
                            ),
                            /* child: TextField(
                              controller: _textController,
                              decoration:
                                  ,
                            ), */
                          ),
                          Padding(
                            padding: Style.padding,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "English translation:",
                                  style: Theme.of(context).textTheme.headline5,
                                ),
                                Style.distance,
                                Text(
                                  snapshot.data?[_textController.text] ?? "...",
                                  style: Theme.of(context).textTheme.headline4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
        ),
      ),
    );
  }

  Future<List<String>> _getSuggestions(String pattern, TreeNode suggestionTree) async {
    var result = <String>[];
    TreeNode? node = suggestionTree;
    for (var i = 0; i < pattern.length && node != null; i++) {
      var char = pattern[i];
      if (i >= pattern.length - 1) {
        _addAllSuggestions(node, result);
      }
      node = node.nodes[char];
    }
    return result;
  }

  void _addAllSuggestions(TreeNode treeNode, List<String> result) {
    for (var word in treeNode.words) {
      result.add(word);
    }
    for (var node in treeNode.nodes.values) {
      _addAllSuggestions(node, result);
    }
  }

  Future<Map<String, String>> _getTranslationsFromFile() async {
    var fileText = await rootBundle.loadString('assets/persian2english.csv');
    var pairs = fileText.split("\n").map((e) => e.split(","));
    var map = {for (var p in pairs) p[0]: p[1]};
    return map;
  }

  TreeNode _buildSuggestionsTree(Map<String, String>? data) {
    var res = TreeNode();
    if (data != null) {
      for (var persianWord in data.keys) {
        var node = res;
        for (var i = 0; i < persianWord.length; i++) {
          var char = persianWord[i];
          if (i >= persianWord.length - 1) {
            node.words.add(persianWord);
          } else {
            if (node.nodes[char] == null) {
              node.nodes[char] = TreeNode();
            }
            node = node.nodes[char]!;
          }
        }
      }
    }
    return res;
  }
}

class TreeNode {
  List<String> words = [];
  Map<String, TreeNode> nodes = {};
}

class Style {
  static const border = BorderRadius.all(Radius.circular(10));
  static const padding = EdgeInsets.all(10.0);
  static const paddingOuter = EdgeInsets.all(30.0);
  static const distance = SizedBox(width: 10);
}

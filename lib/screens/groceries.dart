import 'dart:convert';
import 'package:shopping_list/config.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/screens/new_item.dart';
import 'package:connectivity/connectivity.dart';

var _isLoading = true;
String? _error;

class GroceriesScreen extends StatefulWidget {
  const GroceriesScreen({super.key});

  @override
  State<GroceriesScreen> createState() => _GroceriesScreenState();
}

class _GroceriesScreenState extends State<GroceriesScreen> {
  List<GroceryItem> _groceryItem = [];
  var _connectivity = Connectivity();

  @override
  void initState() {
    super.initState();
    _loadItems();

    // Set up connectivity change listener
    // _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
    //   if (result != ConnectivityResult.none) {
    //     print("SAASASA");
    //     // Internet connection is available, refresh data
    //     _loadItems();
    //   }
    // });
  }

  void _newItem() async {
    var item = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (item == null) {
      return;
    }

    setState(() {
      _groceryItem.add(item);
    });
  }

  void _loadItems() async {
    print("in Load");
    var url = Uri.https(
        'flutter-prep-6e6e0-default-rtdb.firebaseio.com', 'shopping-list.json');
    print("on");
    try {
      print("1");

      var data = await http.get(url);
      if (data.statusCode >= 400) {
        print(data);

        setState(() {
          _error = "Can't fetch the data :(\n please try again later.";
        });
      }
      print("2");

      if (data.body == 'null') {
        print("null");

        setState(() {
          _isLoading = false;
          return;
        });
      }
      print("3");

      final Map<String, dynamic> items = json.decode(data.body);
      final List<GroceryItem> tmpItems = [];
      print("4");

      for (final item in items.entries) {
        final category = categories.entries
            .firstWhere(
                (element) => element.value.label == item.value["category"])
            .value;
        tmpItems.add(
          GroceryItem(
              id: item.key,
              name: item.value["name"],
              quantity: item.value["quantity"],
              category: category),
        );
      }
      print("5");

      setState(() {
        _groceryItem = tmpItems;
        _isLoading = false;
      });
      print("1dd");
    } catch (err) {
      setState(() {
        print("MESSAGE " + err.toString());
        _error = 'Something went wrong :(';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var content;

    if (_groceryItem.isEmpty) {
      content = const Center(
        child: Text("Oh uh, No Item here."),
      );
    }
    if (_isLoading) {
      content = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(
              height: 8,
            ),
            Text("Loading Grocery Items..."),
          ],
        ),
      );
    }
    if (_groceryItem.isNotEmpty) {
      content = ListView(
        children: [
          for (GroceryItem item in _groceryItem)
            Dismissible(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: Container(
                  decoration: const BoxDecoration(
                    //borderRadius: BorderRadius.circular(50),
                    color: Color.fromARGB(255, 192, 45, 35),
                  ),
                  alignment: Alignment.centerLeft,
                  //color: kColorScheme.error,
                  padding: const EdgeInsets.fromLTRB(3, 0, 3, 0),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            "Delete",
                            style: GoogleFonts.abel(
                                color: Colors.white, fontSize: 28),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            "Delete",
                            style: GoogleFonts.abel(
                                color: Colors.white, fontSize: 28),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              onDismissed: (direction) async {
                var index = _groceryItem.indexOf(item);
                setState(() {
                  _groceryItem.remove(item);
                });

                var url =
                    Uri.https(firebaseUrl, 'shopping-list/${item.id}.json');

                var response = await http.delete(url);
                print(response.statusCode);

                if (response.statusCode != 200) {
                  print("Not Deleted");
                  setState(() {
                    _groceryItem.insert(index, item);
                  });
                }
              },
              key: ValueKey(item.id),
              child: Card(
                color: const Color.fromARGB(88, 68, 137, 255),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: item.category.color,
                          borderRadius: BorderRadius.circular(25)),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(item.quantity.toString()),
                    const SizedBox(
                      width: 20,
                    )
                  ],
                ),
              ),
            ),
        ],
      );
    }

    if (_error != null) {
      content = Center(
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: GoogleFonts.abel(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groceries'),
        actions: [
          IconButton(
            onPressed: _newItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: content,
      ),
    );
  }
}

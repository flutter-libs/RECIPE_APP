import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('recipeBox');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recipe Book',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: RecipeBookPage(),
    );
  }
}

class RecipeBookPage extends StatefulWidget {
  @override
  _RecipeBookPageState createState() => _RecipeBookPageState();
}

class _RecipeBookPageState extends State<RecipeBookPage> {
  final _recipeNameController = TextEditingController();
  final _recipeIngredientsController = TextEditingController();
  final _recipeBox = Hive.box('recipeBox');
  File? _recipeImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe Book'),
      ),
      body: ValueListenableBuilder(
        valueListenable: _recipeBox.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return Center(
              child: Text('No recipes added yet!'),
            );
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final recipe = box.getAt(index) as Map;
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  leading: recipe['imagePath'] != null
                      ? Image.file(
                    File(recipe['imagePath']),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                      : Icon(Icons.image, size: 50),
                  title: Text(recipe['name']),
                  subtitle: Text('Ingredients: ${recipe['ingredients']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteRecipe(index),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showAddRecipeDialog(),
      ),
    );
  }
  void _showAddRecipeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Recipe'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _recipeNameController,
                decoration: InputDecoration(hintText: 'Enter recipe name'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _recipeIngredientsController,
                decoration: InputDecoration(hintText: 'Enter ingredients'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _pickImage(),
                child: Text('Pick Image'),
              ),
              if (_recipeImage != null)
                Image.file(
                  _recipeImage!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
              _clearFields();
            },
          ),
          TextButton(
            child: Text('Add'),
            onPressed: () {
              if (_recipeNameController.text.isNotEmpty && _recipeIngredientsController.text.isNotEmpty && _recipeImage != null) {
                _addRecipe(_recipeNameController.text, _recipeIngredientsController.text, _recipeImage!.path);
                Navigator.of(context).pop();
                _clearFields();
              }
            },
          ),
        ],
      ),
    );
  }

  void _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _recipeImage = File(pickedFile.path);
      });
    }
  }

  void _addRecipe(String name, String ingredients, String imagePath) {
    final recipe = {'name': name, 'ingredients': ingredients, 'imagePath': imagePath};
    _recipeBox.add(recipe);
    setState(() {});
  }

  void _deleteRecipe(int index) {
    _recipeBox.deleteAt(index);
    setState(() {});
  }

  void _clearFields() {
    _recipeNameController.clear();
    _recipeIngredientsController.clear();
    _recipeImage = null;
    setState(() {});
  }
}



import 'package:conditional_builder/conditional_builder.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:todo_app/modules/archived_taskes/archived_taskes_screen.dart';
import 'package:todo_app/modules/done_taskes/done_taskes_screnn.dart';
import 'package:todo_app/modules/new_taskes/new_taskes_screen.dart';
import 'package:todo_app/shared/componantes/componantes.dart';
import 'package:todo_app/shared/componantes/costants.dart';

class HomeLayout extends StatefulWidget {
  const HomeLayout({Key key}) : super(key: key);

  @override
  _HomeLayoutState createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  int _currentIndex = 0;

  List<Widget> screens = [
    NewTasksScreen(),
    DoneTasksScreen(),
    ArchivedTasksScreen(),
  ];

  List<String> titles = [
    'New',
    'Done',
    'Archived',
  ];
  Database database;
  var scaffoldKey = GlobalKey<ScaffoldState>();
  var formKey = GlobalKey<FormState>();
  bool isBottomSheetOpen = false;
  IconData fabIcon = Icons.edit;
  var titleController = TextEditingController();
  var timeController = TextEditingController();
  var dateController = TextEditingController();

  @override
  void initState() {
    super.initState();

    createDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(fabIcon),
        onPressed: () {
          if (isBottomSheetOpen) {
            if (formKey.currentState.validate()) {
              insertToDatabase(
                title: titleController.text,
                time: timeController.text,
                date: dateController.text,
              ).then(
                (value) {

                  getDataFromDatabase(database).then(
                        (value) {
                          Navigator.pop(context);
                      setState(() {
                        isBottomSheetOpen = false;
                        tasks = value;
                        print(tasks);
                      });
                    },
                  );
                },
              ).catchError(
                (error) {
                  print('error in inserting to database');
                },
              );
            }
          } else {
            scaffoldKey.currentState
                .showBottomSheet(
                  (context) => Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          defaultFormField(
                            controller: titleController,
                            type: TextInputType.text,
                            validate: (String value) {
                              if (value.isEmpty) {
                                return 'Title can\'t be empty!!';
                              }
                              return null;
                            },
                            label: 'Task Title',
                            prefix: Icons.title,
                          ),
                          SizedBox(height: 15),
                          defaultFormField(
                            isReadOnly: true,
                            controller: timeController,
                            onTap: () {
                              showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              ).then(
                                (value) {
                                  timeController.text =
                                      value.format(context).toString();
                                },
                              );
                            },
                            type: TextInputType.datetime,
                            validate: (String value) {
                              if (value.isEmpty) {
                                return 'time can\'t be empty!!';
                              }
                              return null;
                            },
                            label: 'Task Time',
                            prefix: Icons.watch_later_outlined,
                          ),
                          SizedBox(height: 15),
                          defaultFormField(
                            isReadOnly: true,
                            controller: dateController,
                            onTap: () {
                              showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.parse('2022-06-03'),
                              ).then(
                                (value) {
                                  dateController.text =
                                      DateFormat.yMMMd().format(value);
                                },
                              ).catchError(
                                (error) {
                                  print(
                                      'Error in date picker is ${error.toString()}');
                                },
                              );
                            },
                            type: TextInputType.datetime,
                            validate: (String value) {
                              if (value.isEmpty) {
                                return 'date can\'t be empty!!';
                              }
                              return null;
                            },
                            label: 'Task date',
                            prefix: Icons.calendar_today,
                          ),
                        ],
                      ),
                    ),
                  ),
                  elevation: 20,
                )
                .closed
                .then(
              (value) {
                isBottomSheetOpen = false;
                setState(() {
                  fabIcon = Icons.edit;
                });
              },
            ).catchError(
              (error) {
                print('error while trying to close fab is ${error.toString()}');
              },
            );
            isBottomSheetOpen = true;
            setState(() {
              fabIcon = Icons.add;
            });
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Done',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.archive_outlined),
            label: 'Archived',
          ),
        ],
      ),
      body: ConditionalBuilder(
        condition: tasks.length > 0,
        builder: (context) => screens[_currentIndex],
        fallback: (context) => Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void createDatabase() async {
    database = await openDatabase(
      'todo.db',
      version: 1,
      onCreate: (database, version) {
        print('Database created');
        database
            .execute(
                'CREATE TABLE tasks (id INTEGER PRIMARY KEY , title TEXT , date TEXT , time TEXT , status TEXT)')
            .then(
          (value) {
            print('table created');
          },
        ).catchError(
          (error) {
            print('Error when creating the tabled ${error.toString()}');
          },
        );
      },
      onOpen: (database) {
        print('Database opened!');
        getDataFromDatabase(database).then(
          (value) {
            setState(() {
              tasks = value;
            });
          },
        );
      },
    );
  }

  Future insertToDatabase({
    @required String title,
    @required String time,
    @required String date,
  }) async {
    return await database.transaction(
      (txn) {
        txn
            .rawInsert(
          'INSERT INTO tasks(title , date , time , status) VALUES("$title","$date","$time","new") ',
        )
            .then(
          (value) {
            print('Row inserted DONE');
          },
        ).catchError(
          (error) {
            print('Error while inserting is ${error.toString()}');
          },
        );
        return null;
      },
    );
  }

  Future<List<Map>> getDataFromDatabase(database) async {
    return await database.rawQuery('SELECT * FROM tasks');
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:todo_app/modules/archived_taskes/archived_taskes_screen.dart';
import 'package:todo_app/modules/done_taskes/done_taskes_screnn.dart';
import 'package:todo_app/modules/new_taskes/new_taskes_screen.dart';
import 'package:todo_app/shared/cubit/states.dart';

class AppCubit extends Cubit<AppStates> {
  AppCubit() : super(AppInitialState());

  Database database;
  List<Map> newTasks = [];
  List<Map> doneTasks = [];
  List<Map> archivedTasks = [];

  bool isBottomSheetOpen = false;
  IconData fabIcon = Icons.edit;

  static AppCubit get(context) => BlocProvider.of(context);

  int currentIndex = 0;

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

  void changeIndex(int index) {
    currentIndex = index;
    emit(AppChangeBottomNavBarState());
  }

  void createDatabase() {
    openDatabase(
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
        getDataFromDatabase(database);
      },
    ).then((value) {
      database = value;
      emit(AppCreateDatabaseState());
    });
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
            emit(AppInsertDatabaseState());

            getDataFromDatabase(database);
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

  getDataFromDatabase(database) {
    newTasks = [];
    doneTasks = [];
    archivedTasks = [];

    emit(AppGetDatabaseLoadingState());

    database.rawQuery('SELECT * FROM tasks').then(
      (value) {
        value.forEach(
          (element) {
            if (element['status'] == 'new')
              newTasks.add(element);
            else if (element['status'] == 'done')
              doneTasks.add(element);
            else
              archivedTasks.add(element);
          },
        );

        emit(AppGetDatabaseState());
      },
    );
  }

  void updateData({
    @required String status,
    @required int id,
  }) {
    database.rawUpdate(
      'UPDATE tasks SET status = ? WHERE id = ?',
      ['$status', id],
    ).then(
      (value) {
        getDataFromDatabase(database);
        emit(AppUpdateDatabaseState());
      },
    );
  }

  void deleteData({
    @required int id,
  }) {
    database.rawDelete(
      'DELETE FROM tasks WHERE id = ?',
      [id],
    ).then(
      (value) {
        getDataFromDatabase(database);
        emit(AppDeleteDatabaseState());
      },
    );
  }

  void changeBottomSheetState({
    @required bool isShow,
    @required IconData icon,
  }) {
    isBottomSheetOpen = isShow;
    fabIcon = icon;
    emit(AppChangeBottomSheetState());
  }
}

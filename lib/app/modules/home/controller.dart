import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:todo_app_getx/app/data/services/storage/repository.dart';

import '../../data/models/task.dart';

class HomeController extends GetxController {
  final formKey = GlobalKey<FormState>();
  TaskRepository taskRepository;

  HomeController({
    required this.taskRepository,
  });

  final formEditCtrl = TextEditingController();
  final formEditDescriptionCtrl = TextEditingController();
  final tabIndex = 0.obs;
  final chipIndex = 0.obs;
  final deleting = false.obs;
  final tasks = <Task>[].obs;
  final task = Rx<Task?>(null);
  final doingTodos = <dynamic>[].obs;
  final doneTodos = <dynamic>[].obs;
  var wifiStatus = "".obs;
  var location = "".obs;
  final ImagePicker picker = ImagePicker();
  List<XFile> imagePathList = [];

  @override
  void onInit() {
    super.onInit();
    tasks.assignAll(taskRepository.readTasks());
    ever(tasks, (_) => taskRepository.writeTasks(tasks));
    Timer.periodic(const Duration(seconds: 5), (_) => _updateNetworkStatus());
    getLocation();
  }

  @override
  void onClose() {
    // TODO: implement onClose
    formEditCtrl.dispose();
    super.onClose();
  }


  Future<void> pickMultipleImg() async {
    imagePathList = await picker.pickMultiImage(
        requestFullMetadata: false, maxHeight: 200, maxWidth: 200);
    update();
  }

  Future<void> getLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    debugPrint('location: Lat-----> ${position.latitude} Long-----> ${position.longitude}');
    List<Placemark> addresses = await placemarkFromCoordinates(position.latitude, position.longitude);
    var first = addresses.first;
    location.value = first.locality!;
    print('Locality : ${first.locality}');
    update();
  }

  Future<void> _updateNetworkStatus() async {
    String status = await getNetworkStatus();
    wifiStatus.value = status;
  }

  Future<String> getNetworkStatus() async {
    final NetworkInfo networkInfo = NetworkInfo();
    String? wifiName = await networkInfo.getWifiName();
    if (await Permission.location.request().isGranted) {
      if (await Permission.location.serviceStatus.isEnabled) {
        return wifiName ?? "Connected";
      } else {
        return "Location services are disabled, turn on location";
      }
    } else {
      return "Location permission denied";
    }
  }

  bool addTask(Task task) {
    if (tasks.contains(task)) {
      return false;
    }
    tasks.add(task);
    return true;
  }

  void deleteTask(Task task) {
    tasks.remove(task);
  }

  updateTask(Task task, String title) {
    var todos = task.todos ?? [];
    if (containTodo(todos, title)) {
      return false;
    }
    var todo = {'title': title, 'done': false};
    todos.add(todo);
    var newTask = task.copyWith(todos: todos);
    int oldIdx = tasks.indexOf(task);
    tasks[oldIdx] = newTask;
    tasks.refresh();
    return true;
  }

  bool containTodo(List todos, String title) {
    return todos.any((element) => element['title'] == title);
  }

  void changeChipIndex(int value) {
    chipIndex.value = value;
  }

  void changeDeleting(bool value) {
    deleting.value = value;
  }

  void changeTask(Task? select) {
    task.value = select;
  }

  void changeTodo(List<dynamic> select) {
    doneTodos.clear();
    doingTodos.clear();

    for (var i = 0; i < select.length; i++) {
      var todo = select[i];
      var status = todo['done'];
      if (status == true) {
        doneTodos.add(todo);
      } else {
        doingTodos.add(todo);
      }
    }
  }

  bool addTodo(String title) {
    var doingTodo = {'title': title, 'done': false};
    if (doingTodos
        .any((element) => mapEquals<String, dynamic>(doingTodo, element))) {
      return false;
    }
    var doneTodo = {'title': title, 'done': true};
    if (doneTodos
        .any((element) => mapEquals<String, dynamic>(doneTodo, element))) {
      return false;
    }
    doingTodos.add(doingTodo);
    return true;
  }

  void updateTodo() {
    var newTodos = <Map<String, dynamic>>[];
    newTodos.addAll([
      ...doingTodos,
      ...doneTodos,
    ]);
    var newTask = task.value!.copyWith(todos: newTodos);
    int oldIdx = tasks.indexOf(task.value);
    tasks[oldIdx] = newTask;
    tasks.refresh();
  }

  void doneTodo(String title) {
    var doingTodo = {'title': title, 'done': false};
    int index = doingTodos.indexWhere(
        (element) => mapEquals<String, dynamic>(doingTodo, element));
    doingTodos.removeAt(index);
    var doneTodo = {'title': title, 'done': true};
    doneTodos.add(doneTodo);
    doingTodos.refresh();
    doneTodos.refresh();
  }

  deleteDoneTodo(dynamic doneTodo) {
    int index = doneTodos
        .indexWhere((element) => mapEquals<String, dynamic>(doneTodo, element));
    doneTodos.removeAt(index);
    doneTodos.refresh();
  }

  bool isTodoEmpty(Task task) {
    return task.todos == null || task.todos!.isEmpty;
  }

  int getDoneTodo(Task task) {
    var res = 0;
    for (int i = 0; i < task.todos!.length; i++) {
      if (task.todos![i]['done'] == true) {
        res += 1;
      }
    }
    return res;
  }

  void changeTabIndex(int index) {
    tabIndex.value = index;
  }

  int getTotalTask() {
    var res = 0;
    for (var i = 0; i < tasks.length; i++) {
      if (tasks[i].todos != null) {
        res += tasks[i].todos!.length;
      }
    }
    return res;
  }

  int getTotalDoneTask() {
    int res = 0;
    for (int i = 0; i < tasks.length; i++) {
      if (tasks[i].todos != null) {
        for (int j = 0; j < tasks[i].todos!.length; j++) {
          // if (j < 0 || j >= tasks[i].todos!.length) break;
          if (tasks[i].todos![j]['done'] == true) {
            res += 1;
          }
        }
      }
    }
    return res;
  }
}

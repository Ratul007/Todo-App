import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final String title;
  final String description;
  final int icon;
  final String color;
  final List<dynamic>? todos;

  const Task(
      {required this.title,
      required this.description,
      required this.icon,
      required this.color,
      this.todos});

  Task copyWith({
    String? title,
    String? description,
    int? icon,
    String? color,
    List<dynamic>? todos,
  }) =>
      Task(
        title: title ?? this.title,
        description: description ?? this.description,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        todos: todos ?? this.todos,
      );

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        title: json['title'],
        description: json['description'],
        icon: json['icon'],
        color: json['color'],
        todos: json['todos'],
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'icon': icon,
        'color': color,
        'todos': todos,
      };

  @override
  List<Object?> get props => [title, description, icon, color];
}

import 'dart:async';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:characters/characters.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_idiomatic/import.dart';

part 'todos.g.dart';

class TodosCubit extends Cubit<TodosState> {
  TodosCubit(DatabaseRepository repository)
      : _repository = repository,
        super(TodosState()) {
    _fetchNewNotificationSubscription =
        repository.fetchNewTodoNotification.listen(fetchNewNotification);
  }

  final DatabaseRepository _repository;
  late StreamSubscription<int?> _fetchNewNotificationSubscription;
  bool _isStartedSubscription = false;

  @override
  Future<void> close() {
    _fetchNewNotificationSubscription.cancel();
    return super.close();
  }

  void fetchNewNotification(int? id) {
    if (!_isStartedSubscription) {
      _isStartedSubscription = true;
      return;
    }
    emit(state.copyWith(newId: id));
  }

  Future<void> load({required TodosOrigin origin}) async {
    const kLimit = 10;
    if (state.status == TodosStatus.loading) return;
    emit(state.copyWith(
      status: TodosStatus.loading,
      origin: origin,
      // errorMessage: '',
    ));
    try {
      final items = await _repository.readTodos(
        createdAt: origin == TodosOrigin.loadMore ? state.nextDateTime : null,
        limit: kLimit + 1,
      );
      var hasMore = false;
      DateTime? nextDateTime;
      if (items.length == kLimit + 1) {
        hasMore = true;
        final lastItem = items.removeLast();
        nextDateTime = lastItem.createdAt;
      }
      if (origin != TodosOrigin.loadMore) {
        emit(TodosState());
        await Future.delayed(Duration(milliseconds: 300));
      }
      emit(state.copyWith(
        items: [...state.items, ...items],
        hasMore: hasMore,
        nextDateTime: nextDateTime,
      ));
//  } catch (error) {
//    emit(state.copyWith(errorMessage: '$error'));
//    return Future.error(error);
    } finally {
      emit(state.copyWith(
        status: TodosStatus.ready,
        origin: TodosOrigin.initial,
      ));
    }
  }

  Future<void> remove(int id) async {
    emit(state.copyWith(
      items: [...state.items]..removeWhere((TodoModel item) => item.id == id),
    ));
    try {
      final deletedId = await _repository.deleteTodo(id);
      if (deletedId != id) {
        throw Exception('Can not remove todo $id');
      }
    } catch (error) {
      return Future.error(error);
    }
  }

  Future<void> add(TodosData data) async {
    // final titleInput = TitleInputModel.dirty(title);
    // final status = Formz.validate([titleInput]);
    // if (status.isInvalid) {
    //   return Future.error(ValidationException(titleInput.error));
    // }
    // emit(state.copyWith(isSubmitMode: true));
    // try {
    if (data.title.characters.length < 4) {
      throw ValidationException('Invalid input < 4 characters');
    }
    final item = await _repository.createTodo(data);
    if (item == null) return;
    emit(state.copyWith(
      items: [item, ...state.items],
    ));
    // } catch (error) {
    //   return Future.error(error);
    // } finally {
    //   emit(state.copyWith(isSubmitMode: false));
    // }
  }
}

enum TodosStatus { initial, loading, ready }
enum TodosOrigin { initial, start, refreshIndicator, loadNew, loadMore }

@CopyWith()
class TodosState extends Equatable {
  TodosState({
    this.items = const [],
    this.status = TodosStatus.initial,
    this.origin = TodosOrigin.initial,
    this.hasMore = false,
    this.nextDateTime,
    this.newId,
    // this.isSubmitMode = false,
    // this.errorMessage = '',
  });

  final List<TodoModel> items;
  final TodosStatus status;
  final TodosOrigin origin;
  final DateTime? nextDateTime;
  final bool hasMore;
  final int? newId;
  // final bool isSubmitMode;
  // final String errorMessage;

  bool get hasReallyNewId =>
      newId != null &&
      items.indexWhere((TodoModel item) => item.id == newId) == -1;

  @override
  List<Object?> get props => [
        items,
        status,
        origin,
        hasMore,
        nextDateTime,
        newId,
        // isSubmitMode,
        // errorMessage,
      ];
}

@JsonSerializable(createFactory: false)
class TodosData {
  TodosData({required this.title});

  final String title;

  Map<String, dynamic> toJson() => _$TodosDataToJson(this);
}

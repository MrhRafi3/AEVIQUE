import 'edit_state.dart';

class HistoryManager {
  final List<EditState> _stack = [];
  int _currentIndex = 0;
  final int maxHistory;

  HistoryManager({EditState? initialState, this.maxHistory = 50}) {
    _stack.add(initialState ?? EditState.identity());
    _currentIndex = 0;
  }

  EditState get current => _stack[_currentIndex];

  bool get canUndo => _currentIndex > 0;

  bool get canRedo => _currentIndex < _stack.length - 1;

  int get historyLength => _stack.length;

  int get currentIndex => _currentIndex;

  List<EditState> get history => List.unmodifiable(_stack);

  void push(EditState newState) {
    if (newState == current) return;

    // Discard any redos after current position
    if (_currentIndex < _stack.length - 1) {
      _stack.removeRange(_currentIndex + 1, _stack.length);
    }

    _stack.add(newState);

    // Limit maximum history size to prevent memory bloat
    if (_stack.length > maxHistory) {
      _stack.removeAt(0);
    } else {
      _currentIndex++;
    }
  }

  EditState? undo() {
    if (!canUndo) return null;
    _currentIndex--;
    return current;
  }

  EditState? redo() {
    if (!canRedo) return null;
    _currentIndex++;
    return current;
  }

  void reset({EditState? toState}) {
    _stack.clear();
    _stack.add(toState ?? EditState.identity());
    _currentIndex = 0;
  }
}

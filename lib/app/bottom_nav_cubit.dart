import 'package:bloc/bloc.dart';

class BottomNavCubit extends Cubit<int> {
  BottomNavCubit() : super(0);

  void select(int index) {
    if (index == state) return;
    emit(index);
  }
}

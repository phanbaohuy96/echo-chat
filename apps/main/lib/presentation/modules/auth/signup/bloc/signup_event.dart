part of 'signup_bloc.dart';

abstract class SignupEvent {}

class SignupSubmittedEvent extends SignupEvent {
  SignupSubmittedEvent({
    required this.name,
    required this.username,
    required this.password,
    required this.completer,
  });

  final String name;
  final String username;
  final String password;
  final Completer<AuthResponse> completer;
}

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StateData {

 List<UserModel> get peers; UserModel? get selectedPeer; List<ChatMessage> get messages; bool get isLoadingPeers; bool get isLoadingMessages; bool get isSending;
/// Create a copy of _StateData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StateDataCopyWith<_StateData> get copyWith => __$StateDataCopyWithImpl<_StateData>(this as _StateData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StateData&&const DeepCollectionEquality().equals(other.peers, peers)&&(identical(other.selectedPeer, selectedPeer) || other.selectedPeer == selectedPeer)&&const DeepCollectionEquality().equals(other.messages, messages)&&(identical(other.isLoadingPeers, isLoadingPeers) || other.isLoadingPeers == isLoadingPeers)&&(identical(other.isLoadingMessages, isLoadingMessages) || other.isLoadingMessages == isLoadingMessages)&&(identical(other.isSending, isSending) || other.isSending == isSending));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(peers),selectedPeer,const DeepCollectionEquality().hash(messages),isLoadingPeers,isLoadingMessages,isSending);

@override
String toString() {
  return '_StateData(peers: $peers, selectedPeer: $selectedPeer, messages: $messages, isLoadingPeers: $isLoadingPeers, isLoadingMessages: $isLoadingMessages, isSending: $isSending)';
}


}

/// @nodoc
abstract mixin class _$StateDataCopyWith<$Res>  {
  factory _$StateDataCopyWith(_StateData value, $Res Function(_StateData) _then) = __$StateDataCopyWithImpl;
@useResult
$Res call({
 List<UserModel> peers, UserModel? selectedPeer, List<ChatMessage> messages, bool isLoadingPeers, bool isLoadingMessages, bool isSending
});




}
/// @nodoc
class __$StateDataCopyWithImpl<$Res>
    implements _$StateDataCopyWith<$Res> {
  __$StateDataCopyWithImpl(this._self, this._then);

  final _StateData _self;
  final $Res Function(_StateData) _then;

/// Create a copy of _StateData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? peers = null,Object? selectedPeer = freezed,Object? messages = null,Object? isLoadingPeers = null,Object? isLoadingMessages = null,Object? isSending = null,}) {
  return _then(_self.copyWith(
peers: null == peers ? _self.peers : peers // ignore: cast_nullable_to_non_nullable
as List<UserModel>,selectedPeer: freezed == selectedPeer ? _self.selectedPeer : selectedPeer // ignore: cast_nullable_to_non_nullable
as UserModel?,messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<ChatMessage>,isLoadingPeers: null == isLoadingPeers ? _self.isLoadingPeers : isLoadingPeers // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMessages: null == isLoadingMessages ? _self.isLoadingMessages : isLoadingMessages // ignore: cast_nullable_to_non_nullable
as bool,isSending: null == isSending ? _self.isSending : isSending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [_StateData].
extension _StateDataPatterns on _StateData {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __StateData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __StateData() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __StateData value)  $default,){
final _that = this;
switch (_that) {
case __StateData():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __StateData value)?  $default,){
final _that = this;
switch (_that) {
case __StateData() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<UserModel> peers,  UserModel? selectedPeer,  List<ChatMessage> messages,  bool isLoadingPeers,  bool isLoadingMessages,  bool isSending)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __StateData() when $default != null:
return $default(_that.peers,_that.selectedPeer,_that.messages,_that.isLoadingPeers,_that.isLoadingMessages,_that.isSending);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<UserModel> peers,  UserModel? selectedPeer,  List<ChatMessage> messages,  bool isLoadingPeers,  bool isLoadingMessages,  bool isSending)  $default,) {final _that = this;
switch (_that) {
case __StateData():
return $default(_that.peers,_that.selectedPeer,_that.messages,_that.isLoadingPeers,_that.isLoadingMessages,_that.isSending);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<UserModel> peers,  UserModel? selectedPeer,  List<ChatMessage> messages,  bool isLoadingPeers,  bool isLoadingMessages,  bool isSending)?  $default,) {final _that = this;
switch (_that) {
case __StateData() when $default != null:
return $default(_that.peers,_that.selectedPeer,_that.messages,_that.isLoadingPeers,_that.isLoadingMessages,_that.isSending);case _:
  return null;

}
}

}

/// @nodoc


class __StateData implements _StateData {
  const __StateData({final  List<UserModel> peers = const [], this.selectedPeer, final  List<ChatMessage> messages = const [], this.isLoadingPeers = false, this.isLoadingMessages = false, this.isSending = false}): _peers = peers,_messages = messages;
  

 final  List<UserModel> _peers;
@override@JsonKey() List<UserModel> get peers {
  if (_peers is EqualUnmodifiableListView) return _peers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_peers);
}

@override final  UserModel? selectedPeer;
 final  List<ChatMessage> _messages;
@override@JsonKey() List<ChatMessage> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

@override@JsonKey() final  bool isLoadingPeers;
@override@JsonKey() final  bool isLoadingMessages;
@override@JsonKey() final  bool isSending;

/// Create a copy of _StateData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_StateDataCopyWith<__StateData> get copyWith => __$_StateDataCopyWithImpl<__StateData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is __StateData&&const DeepCollectionEquality().equals(other._peers, _peers)&&(identical(other.selectedPeer, selectedPeer) || other.selectedPeer == selectedPeer)&&const DeepCollectionEquality().equals(other._messages, _messages)&&(identical(other.isLoadingPeers, isLoadingPeers) || other.isLoadingPeers == isLoadingPeers)&&(identical(other.isLoadingMessages, isLoadingMessages) || other.isLoadingMessages == isLoadingMessages)&&(identical(other.isSending, isSending) || other.isSending == isSending));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_peers),selectedPeer,const DeepCollectionEquality().hash(_messages),isLoadingPeers,isLoadingMessages,isSending);

@override
String toString() {
  return '_StateData(peers: $peers, selectedPeer: $selectedPeer, messages: $messages, isLoadingPeers: $isLoadingPeers, isLoadingMessages: $isLoadingMessages, isSending: $isSending)';
}


}

/// @nodoc
abstract mixin class _$_StateDataCopyWith<$Res> implements _$StateDataCopyWith<$Res> {
  factory _$_StateDataCopyWith(__StateData value, $Res Function(__StateData) _then) = __$_StateDataCopyWithImpl;
@override @useResult
$Res call({
 List<UserModel> peers, UserModel? selectedPeer, List<ChatMessage> messages, bool isLoadingPeers, bool isLoadingMessages, bool isSending
});




}
/// @nodoc
class __$_StateDataCopyWithImpl<$Res>
    implements _$_StateDataCopyWith<$Res> {
  __$_StateDataCopyWithImpl(this._self, this._then);

  final __StateData _self;
  final $Res Function(__StateData) _then;

/// Create a copy of _StateData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? peers = null,Object? selectedPeer = freezed,Object? messages = null,Object? isLoadingPeers = null,Object? isLoadingMessages = null,Object? isSending = null,}) {
  return _then(__StateData(
peers: null == peers ? _self._peers : peers // ignore: cast_nullable_to_non_nullable
as List<UserModel>,selectedPeer: freezed == selectedPeer ? _self.selectedPeer : selectedPeer // ignore: cast_nullable_to_non_nullable
as UserModel?,messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<ChatMessage>,isLoadingPeers: null == isLoadingPeers ? _self.isLoadingPeers : isLoadingPeers // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMessages: null == isLoadingMessages ? _self.isLoadingMessages : isLoadingMessages // ignore: cast_nullable_to_non_nullable
as bool,isSending: null == isSending ? _self.isSending : isSending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

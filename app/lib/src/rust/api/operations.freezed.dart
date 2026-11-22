// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'operations.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OperationEvent {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is OperationEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'OperationEvent()';
}


}

/// @nodoc
class $OperationEventCopyWith<$Res>  {
$OperationEventCopyWith(OperationEvent _, $Res Function(OperationEvent) __);
}


/// Adds pattern-matching-related methods to [OperationEvent].
extension OperationEventPatterns on OperationEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OperationEvent_Progress value)?  progress,TResult Function( OperationEvent_Fragmented value)?  fragmented,TResult Function( OperationEvent_Recomposed value)?  recomposed,TResult Function( OperationEvent_Failed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OperationEvent_Progress() when progress != null:
return progress(_that);case OperationEvent_Fragmented() when fragmented != null:
return fragmented(_that);case OperationEvent_Recomposed() when recomposed != null:
return recomposed(_that);case OperationEvent_Failed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OperationEvent_Progress value)  progress,required TResult Function( OperationEvent_Fragmented value)  fragmented,required TResult Function( OperationEvent_Recomposed value)  recomposed,required TResult Function( OperationEvent_Failed value)  failed,}){
final _that = this;
switch (_that) {
case OperationEvent_Progress():
return progress(_that);case OperationEvent_Fragmented():
return fragmented(_that);case OperationEvent_Recomposed():
return recomposed(_that);case OperationEvent_Failed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OperationEvent_Progress value)?  progress,TResult? Function( OperationEvent_Fragmented value)?  fragmented,TResult? Function( OperationEvent_Recomposed value)?  recomposed,TResult? Function( OperationEvent_Failed value)?  failed,}){
final _that = this;
switch (_that) {
case OperationEvent_Progress() when progress != null:
return progress(_that);case OperationEvent_Fragmented() when fragmented != null:
return fragmented(_that);case OperationEvent_Recomposed() when recomposed != null:
return recomposed(_that);case OperationEvent_Failed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Stage stage,  BigInt done,  BigInt total)?  progress,TResult Function( FragmentOutcome field0)?  fragmented,TResult Function( RecomposeOutcome field0)?  recomposed,TResult Function( SlysError field0)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OperationEvent_Progress() when progress != null:
return progress(_that.stage,_that.done,_that.total);case OperationEvent_Fragmented() when fragmented != null:
return fragmented(_that.field0);case OperationEvent_Recomposed() when recomposed != null:
return recomposed(_that.field0);case OperationEvent_Failed() when failed != null:
return failed(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Stage stage,  BigInt done,  BigInt total)  progress,required TResult Function( FragmentOutcome field0)  fragmented,required TResult Function( RecomposeOutcome field0)  recomposed,required TResult Function( SlysError field0)  failed,}) {final _that = this;
switch (_that) {
case OperationEvent_Progress():
return progress(_that.stage,_that.done,_that.total);case OperationEvent_Fragmented():
return fragmented(_that.field0);case OperationEvent_Recomposed():
return recomposed(_that.field0);case OperationEvent_Failed():
return failed(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Stage stage,  BigInt done,  BigInt total)?  progress,TResult? Function( FragmentOutcome field0)?  fragmented,TResult? Function( RecomposeOutcome field0)?  recomposed,TResult? Function( SlysError field0)?  failed,}) {final _that = this;
switch (_that) {
case OperationEvent_Progress() when progress != null:
return progress(_that.stage,_that.done,_that.total);case OperationEvent_Fragmented() when fragmented != null:
return fragmented(_that.field0);case OperationEvent_Recomposed() when recomposed != null:
return recomposed(_that.field0);case OperationEvent_Failed() when failed != null:
return failed(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class OperationEvent_Progress extends OperationEvent {
  const OperationEvent_Progress({required this.stage, required this.done, required this.total}): super._();
  

 final  Stage stage;
 final  BigInt done;
 final  BigInt total;

/// Create a copy of OperationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OperationEvent_ProgressCopyWith<OperationEvent_Progress> get copyWith => _$OperationEvent_ProgressCopyWithImpl<OperationEvent_Progress>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is OperationEvent_Progress&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.done, done) || other.done == done)&&(identical(other.total, total) || other.total == total));
}


@override
int get hashCode {
    return Object.hash(runtimeType,stage,done,total);
}

@override
String toString() {
    return 'OperationEvent.progress(stage: $stage, done: $done, total: $total)';
}


}

/// @nodoc
abstract mixin class $OperationEvent_ProgressCopyWith<$Res> implements $OperationEventCopyWith<$Res> {
  factory $OperationEvent_ProgressCopyWith(OperationEvent_Progress value, $Res Function(OperationEvent_Progress) _then) = _$OperationEvent_ProgressCopyWithImpl;
@useResult
$Res call({
 Stage stage, BigInt done, BigInt total
});




}
/// @nodoc
class _$OperationEvent_ProgressCopyWithImpl<$Res>
    implements $OperationEvent_ProgressCopyWith<$Res> {
  _$OperationEvent_ProgressCopyWithImpl(this._self, this._then);

  final OperationEvent_Progress _self;
  final $Res Function(OperationEvent_Progress) _then;

/// Create a copy of OperationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? stage = null,Object? done = null,Object? total = null,}) {
  return _then(OperationEvent_Progress(
stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as Stage,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as BigInt,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class OperationEvent_Fragmented extends OperationEvent {
  const OperationEvent_Fragmented(this.field0): super._();
  

 final  FragmentOutcome field0;

/// Create a copy of OperationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OperationEvent_FragmentedCopyWith<OperationEvent_Fragmented> get copyWith => _$OperationEvent_FragmentedCopyWithImpl<OperationEvent_Fragmented>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is OperationEvent_Fragmented&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode {
    return Object.hash(runtimeType,field0);
}

@override
String toString() {
    return 'OperationEvent.fragmented(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $OperationEvent_FragmentedCopyWith<$Res> implements $OperationEventCopyWith<$Res> {
  factory $OperationEvent_FragmentedCopyWith(OperationEvent_Fragmented value, $Res Function(OperationEvent_Fragmented) _then) = _$OperationEvent_FragmentedCopyWithImpl;
@useResult
$Res call({
 FragmentOutcome field0
});




}
/// @nodoc
class _$OperationEvent_FragmentedCopyWithImpl<$Res>
    implements $OperationEvent_FragmentedCopyWith<$Res> {
  _$OperationEvent_FragmentedCopyWithImpl(this._self, this._then);

  final OperationEvent_Fragmented _self;
  final $Res Function(OperationEvent_Fragmented) _then;

/// Create a copy of OperationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(OperationEvent_Fragmented(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as FragmentOutcome,
  ));
}


}

/// @nodoc


class OperationEvent_Recomposed extends OperationEvent {
  const OperationEvent_Recomposed(this.field0): super._();
  

 final  RecomposeOutcome field0;

/// Create a copy of OperationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OperationEvent_RecomposedCopyWith<OperationEvent_Recomposed> get copyWith => _$OperationEvent_RecomposedCopyWithImpl<OperationEvent_Recomposed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is OperationEvent_Recomposed&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode {
    return Object.hash(runtimeType,field0);
}

@override
String toString() {
    return 'OperationEvent.recomposed(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $OperationEvent_RecomposedCopyWith<$Res> implements $OperationEventCopyWith<$Res> {
  factory $OperationEvent_RecomposedCopyWith(OperationEvent_Recomposed value, $Res Function(OperationEvent_Recomposed) _then) = _$OperationEvent_RecomposedCopyWithImpl;
@useResult
$Res call({
 RecomposeOutcome field0
});




}
/// @nodoc
class _$OperationEvent_RecomposedCopyWithImpl<$Res>
    implements $OperationEvent_RecomposedCopyWith<$Res> {
  _$OperationEvent_RecomposedCopyWithImpl(this._self, this._then);

  final OperationEvent_Recomposed _self;
  final $Res Function(OperationEvent_Recomposed) _then;

/// Create a copy of OperationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(OperationEvent_Recomposed(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as RecomposeOutcome,
  ));
}


}

/// @nodoc


class OperationEvent_Failed extends OperationEvent {
  const OperationEvent_Failed(this.field0): super._();
  

 final  SlysError field0;

/// Create a copy of OperationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OperationEvent_FailedCopyWith<OperationEvent_Failed> get copyWith => _$OperationEvent_FailedCopyWithImpl<OperationEvent_Failed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is OperationEvent_Failed&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode {
    return Object.hash(runtimeType,field0);
}

@override
String toString() {
    return 'OperationEvent.failed(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $OperationEvent_FailedCopyWith<$Res> implements $OperationEventCopyWith<$Res> {
  factory $OperationEvent_FailedCopyWith(OperationEvent_Failed value, $Res Function(OperationEvent_Failed) _then) = _$OperationEvent_FailedCopyWithImpl;
@useResult
$Res call({
 SlysError field0
});




}
/// @nodoc
class _$OperationEvent_FailedCopyWithImpl<$Res>
    implements $OperationEvent_FailedCopyWith<$Res> {
  _$OperationEvent_FailedCopyWithImpl(this._self, this._then);

  final OperationEvent_Failed _self;
  final $Res Function(OperationEvent_Failed) _then;

/// Create a copy of OperationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(OperationEvent_Failed(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as SlysError,
  ));
}


}

// dart format on

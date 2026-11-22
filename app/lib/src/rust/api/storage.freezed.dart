// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'storage.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InactivityStatus {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is InactivityStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'InactivityStatus()';
}


}

/// @nodoc
class $InactivityStatusCopyWith<$Res>  {
$InactivityStatusCopyWith(InactivityStatus _, $Res Function(InactivityStatus) __);
}


/// Adds pattern-matching-related methods to [InactivityStatus].
extension InactivityStatusPatterns on InactivityStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InactivityStatus_Disabled value)?  disabled,TResult Function( InactivityStatus_Armed value)?  armed,TResult Function( InactivityStatus_Expired value)?  expired,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InactivityStatus_Disabled() when disabled != null:
return disabled(_that);case InactivityStatus_Armed() when armed != null:
return armed(_that);case InactivityStatus_Expired() when expired != null:
return expired(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InactivityStatus_Disabled value)  disabled,required TResult Function( InactivityStatus_Armed value)  armed,required TResult Function( InactivityStatus_Expired value)  expired,}){
final _that = this;
switch (_that) {
case InactivityStatus_Disabled():
return disabled(_that);case InactivityStatus_Armed():
return armed(_that);case InactivityStatus_Expired():
return expired(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InactivityStatus_Disabled value)?  disabled,TResult? Function( InactivityStatus_Armed value)?  armed,TResult? Function( InactivityStatus_Expired value)?  expired,}){
final _that = this;
switch (_that) {
case InactivityStatus_Disabled() when disabled != null:
return disabled(_that);case InactivityStatus_Armed() when armed != null:
return armed(_that);case InactivityStatus_Expired() when expired != null:
return expired(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  disabled,TResult Function( int daysLeft)?  armed,TResult Function()?  expired,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InactivityStatus_Disabled() when disabled != null:
return disabled();case InactivityStatus_Armed() when armed != null:
return armed(_that.daysLeft);case InactivityStatus_Expired() when expired != null:
return expired();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  disabled,required TResult Function( int daysLeft)  armed,required TResult Function()  expired,}) {final _that = this;
switch (_that) {
case InactivityStatus_Disabled():
return disabled();case InactivityStatus_Armed():
return armed(_that.daysLeft);case InactivityStatus_Expired():
return expired();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  disabled,TResult? Function( int daysLeft)?  armed,TResult? Function()?  expired,}) {final _that = this;
switch (_that) {
case InactivityStatus_Disabled() when disabled != null:
return disabled();case InactivityStatus_Armed() when armed != null:
return armed(_that.daysLeft);case InactivityStatus_Expired() when expired != null:
return expired();case _:
  return null;

}
}

}

/// @nodoc


class InactivityStatus_Disabled extends InactivityStatus {
  const InactivityStatus_Disabled(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is InactivityStatus_Disabled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'InactivityStatus.disabled()';
}


}




/// @nodoc


class InactivityStatus_Armed extends InactivityStatus {
  const InactivityStatus_Armed({required this.daysLeft}): super._();
  

 final  int daysLeft;

/// Create a copy of InactivityStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InactivityStatus_ArmedCopyWith<InactivityStatus_Armed> get copyWith => _$InactivityStatus_ArmedCopyWithImpl<InactivityStatus_Armed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is InactivityStatus_Armed&&(identical(other.daysLeft, daysLeft) || other.daysLeft == daysLeft));
}


@override
int get hashCode {
    return Object.hash(runtimeType,daysLeft);
}

@override
String toString() {
    return 'InactivityStatus.armed(daysLeft: $daysLeft)';
}


}

/// @nodoc
abstract mixin class $InactivityStatus_ArmedCopyWith<$Res> implements $InactivityStatusCopyWith<$Res> {
  factory $InactivityStatus_ArmedCopyWith(InactivityStatus_Armed value, $Res Function(InactivityStatus_Armed) _then) = _$InactivityStatus_ArmedCopyWithImpl;
@useResult
$Res call({
 int daysLeft
});




}
/// @nodoc
class _$InactivityStatus_ArmedCopyWithImpl<$Res>
    implements $InactivityStatus_ArmedCopyWith<$Res> {
  _$InactivityStatus_ArmedCopyWithImpl(this._self, this._then);

  final InactivityStatus_Armed _self;
  final $Res Function(InactivityStatus_Armed) _then;

/// Create a copy of InactivityStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? daysLeft = null,}) {
  return _then(InactivityStatus_Armed(
daysLeft: null == daysLeft ? _self.daysLeft : daysLeft // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class InactivityStatus_Expired extends InactivityStatus {
  const InactivityStatus_Expired(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is InactivityStatus_Expired);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'InactivityStatus.expired()';
}


}




// dart format on

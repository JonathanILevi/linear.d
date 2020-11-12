module math.linear.point;

import math.linear.vector: Vec;
import vector_ = math.linear.vector;

// TODO: Add tests to ensure T is a compotable type (number or vector, etc...).
struct Point(T) {
	union {
		T vector;
		struct {
			static if (T.data.length>=1)
				T.Type x;
			static if (T.data.length>=2)
				T.Type y;
			static if (T.data.length>=3)
				T.Type z;
			static if (T.data.length>=4)
				T.Type w;
		}
	}
	alias v = vector;
	
	const
	auto castType(NT)() {
		return point(vector.castType!NT);
	}
	
	const
	auto opBinary(string op, T)(T b) {////if (__traits(compiles, opBinaryImpl!op(this, b))){
		return opBinaryImpl!op(this, b);
	}
	const
	auto opBinaryRight(string op, T)(T a) if (__traits(compiles, opBinaryImpl!op(a, this))){
		return opBinaryImpl!op(a,this);
	}
	auto opOpAssign(string op, T)(T b) if (__traits(compiles, opOpAssignImpl!op(this, b))){
		return opOpAssignImpl!op(this, b);
	}
}
auto point(T)(T v) {
	return Point!T(v);
}
auto pvec(T, size_t size)(T[size] data ...) {
	return point(Vec!(T, size)(data));
}
auto pvec(size_t size, T)(T data) {
	return point(Vec!(T, size)(data));
}

auto distance(T, U, size_t size)(Point!(Vec!(T,size)) v, Point!(Vec!(U,size)) w) {
	return vector_.distance(v.vector, w.vector);
}

alias P = Point;
alias PVec(size_t size, T) = P!(Vec!(T, size));
alias PVec2(T) = P!(Vec!(T, 2));
alias PVec3(T) = P!(Vec!(T, 3));
alias PVec4(T) = P!(Vec!(T, 4));

auto opBinaryImpl(string op:"-", T,U)(const P!T a, const P!U b) 
////if	( __traits(compiles, mixin("a.vector"~op~"b.vector"))
////	)
{
	return mixin("a.vector"~op~"b.vector");
}
auto opBinaryImpl(string op, T,U)(const P!T a, const U b) 
if	(__traits(compiles, mixin("a.vector"~op~"b"))
	&& (op=="-" || op=="+")
	)
{
	return point(mixin("a.vector"~op~"b"));
}

auto opOpAssignImpl(string op, T,U)(ref P!T a, const U b) 
if	( __traits(compiles, mixin("a.vector"~op~"=b"))
	&& (op=="-" || op=="+")
	)
{
	mixin("a.vector"~op~"=b;");
	return a;
}
 

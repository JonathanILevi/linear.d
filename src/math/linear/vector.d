module math.linear.vector;

import core.internal.traits : Unconst;
////import std.traits : Unconst;
import std.traits;
import std.math;
import std.range;
import std.algorithm;

public import math.linear._qv;

alias Vec2(T) = Vec!(T, 2);
alias Vec3(T) = Vec!(T, 3);
alias Vec4(T) = Vec!(T, 4);
// TODO: Add tests to ensure T is a compotable type (number, etc...).
struct Vec(T, size_t size) {
	alias Type = T;
	union {
		T[size] data;
		struct {
			static if (size>=1)
				T x;
			static if (size>=2)
				T y;
			static if (size>=3)
				T z;
			static if (size>=4)
				T w;
		}
	}
	alias data this;
	
	this(T[size] data ...) {
		this.data = data;
	}
	this(T x) {
		this.data[] = x;
	}
	this(Ts)(Ts data) if (isInputRange!T) {
		this.data = data.staticArray!size;
	}
	
	const
	Vec!(NT, size) castType(NT)() {
		return Vec!(NT,size)(data.arrayCast!NT);
	}
	
	inout
	T opIndex(const size_t i) {
		return data[i];
	}
	void opIndex(const size_t i, T n) {
		data[i] = n;
	}
	
	const
	auto opBinary(string op, T)(T b) {////if (__traits(compiles, opBinaryImpl!op(this, b))){
		return opBinaryImpl!op(this, b);
	}
	const
	auto opBinaryRight(string op, T)(T a) if (__traits(compiles, opBinaryImpl!op(a, this))){
		return opBinaryImpl!op(a,this);
	}
	auto opOpAssign(string op, T)(T b) {////if (__traits(compiles, opOpAssignImpl!op(this, b))){
		return opOpAssignImpl!op(this, b);
	}
	
	auto map(funs...)() {
		return vec(data[].map!funs.array[0..size]);
	}
}
auto vec(T, size_t size)(T[size] data ...) {
	return Vec!(T, size)(data);
}
auto vec(size_t size, T)(T data) {
	return Vec!(T, size)(data);
}

T magnitudeSquared(T, size_t size)(const Vec!(T,size) v) {
	return v.data[].map!"a^^2".sum;
}
T magnitude(T, size_t size)(const Vec!(T,size) v) {
	return cast(T) sqrt(cast(real) v.magnitudeSquared);
}
void normalize(bool zero=true, T, size_t size)(Vec!(T,size) v) {
	auto ms = v.magnitudeSquared;
	if (zero && ms == 0)
		this.data[] = 0;
	else
		this.data[] /= cast(T) sqrt(cast(real) ms);
}
Vec!(T,size) normalized(bool zero=true, T, size_t size)(const Vec!(T,size) v) {
	Vec!(T,size) n;
	auto ms = v.magnitudeSquared;
	if (zero && ms == 0)
		n.data[] = 0;
	else
		n.data[] = v.data[] / cast(T) sqrt(cast(real) ms);
	return n;
}

auto rotate(T, U)(Vec!(T,2) v, U a) {
	return vec(v.x * a.cos - v.y * a.sin, v.x * a.sin + v.y * a.cos);
}


void invert(T, size_t size)(Vec!(T,size) v) {
	v.data[] = -v.data[];
}
Vec!(T,size) inverse(T, size_t size)(constVec!(T,size) v) {
	Vec!(T,size) n;
	n.data[] = -v.data[];
	return n;
}

auto cross(T, U)(const Vec!(T,3) a, const Vec!(U,3) b) {
	return Vec!(typeof(a[0]*b[0]),3)	( a.y * b.z - b.y * a.z
		, a.z * b.x - b.z * a.x
		, a.x * b.y - b.x * a.y
		);
}
auto cross(T, U)(const Vec!(T,2) a, const Vec!(U,2) b) {
	return a.x * b.y - b.x * a.y;
}
auto dot(T, U, size_t size)(const Vec!(T,size) a, const Vec!(U,size) b) if (size==2||size==3) {
	return cast(typeof(a[0]*b[0])) zip(a.data[],b.data[]).map!"a[0]*a[1]".sum();// `cast` because sum will increase precision of type.
}


////auto cross(T, U)(const Vec!(T,3) a, const U[3] b) {
////	return cross(a, Vec!(U,3)(b));
////}
////auto cross(T, U)(const T[3] a, const Vec!(U,3) b) {
////	return cross(Vec!(T,3)(a), b);
////}
////auto cross(T, U)(const T[3] a, const U[3] b) {
////	return cross(Vec!(T,3)(a), Vec!(U,3)(b));
////}
////auto dot(T, U, size_t size)(const Vec!(T,size) a, const U[size] b) if (size==2||size==3) {
////	return dot(a,Vec!(U,size)(b));
////}
////auto dot(T, U, size_t size)(const T[size] a, const Vec!(U,size) b) if (size==2||size==3) {
////	return dot(Vec!(T,size)(a),b);
////}
////auto dot(T, U, size_t size)(const T[size] a, const U[size] b) if (size==2||size==3) {
////	return dot(Vec!(T,size)(a),Vec!(U,size)(b));
////}

auto abs(T, size_t size)(Vec!(T,size) v) {
	alias NT = Unconst!(typeof(std.math.abs(rvalueOf!T)));
	Vec!(NT, size) n;
	n.data[] = v.data[].map!"abs(a)".array[];
	return n;
}
auto distance(T, U, size_t size)(Vec!(T,size) v, Vec!(U,size) w) {
	return magnitude(v-w);
}

auto opBinaryImpl(string op, size_t size,T,U)(const Vec!(T, size) a, const Vec!(U, size) b) 
if (__traits(compiles, mixin("rvalueOf!T"~op~"rvalueOf!U")))
{
	alias NT = Unconst!(typeof(mixin("rvalueOf!T"~op~"rvalueOf!U")));
	Vec!(NT, size) n;
	static if (__traits(compiles, mixin("a.data[]"~op~"b.data[]")))
		n.data[] = mixin("a.data[]"~op~"b.data[]");
	else static foreach(i; 0..size)
		n.data[i] = mixin("a.data[i]"~op~"b.data[i]");
	return n;
}
auto opBinaryImpl(string op, size_t size,T,U)(const Vec!(T, size) a, const U[size] b) 
if (__traits(compiles, mixin("rvalueOf!T"~op~"rvalueOf!U")))
{
	return mixin("a"~op~"Vec!(U,size)(b)");
}
auto opBinaryImpl(string op, size_t size,T,U)(const T[size] a, const Vec!(U, size) b) 
if (__traits(compiles, mixin("rvalueOf!T"~op~"rvalueOf!U")))
{
	return mixin("Vec!(T,size)(a)"~op~"b");
}

auto opBinaryImpl(string op, size_t size,T,U)(const Vec!(T, size) a, const U b)
if (__traits(compiles, mixin("rvalueOf!T"~op~"rvalueOf!U")))
{
	alias NT = Unconst!(typeof(mixin("rvalueOf!T"~op~"rvalueOf!U")));
	Vec!(NT, size) n;
	static if (__traits(compiles, mixin("a.data[]"~op~"b")))
		n.data[] = mixin("a.data[]"~op~"b");
	else static foreach(i; 0..size)
		n.data[i] = mixin("a.data[i]"~op~"b");
	return n;
}

auto opBinaryImpl(string op, size_t size,T,U)(const T a, const Vec!(U, size) b) 
if (__traits(compiles, mixin("rvalueOf!T"~op~"rvalueOf!U")) && !__traits(compiles, mixin("opBinaryImpl!\""~op~"\"(rvalueOf!T, rvalueOf!U)")))
{
	alias NT = Unconst!(typeof(rvalueOf!T*rvalueOf!U));
	Vec!(NT, size) n;
	n.data[] = mixin("a"~op~"b.data[]");
	return n;
}

 




auto opOpAssignImpl(string op, size_t size,T,U)(ref Vec!(T, size) a, const Vec!(U, size) b) 
if (__traits(compiles, mixin("rvalueOf!T"~op~"rvalueOf!U")))
{
	static if(__traits(compiles,mixin("a.data[]"~op~"=b.data[];")))
		mixin("a.data[]"~op~"=b.data[];");
	else static foreach(i; 0..size)
		mixin("a.data[i]"~op~"=b.data[i];");
	return a;
}
auto opOpAssignImpl(string op, size_t size,T,U)(ref Vec!(T, size) a, const U[size] b) 
if (__traits(compiles, mixin("rvalueOf!T"~op~"rvalueOf!U")))
{
	static if(__traits(compiles,mixin("a.data[]"~op~"=b[];")))
		mixin("a.data[]"~op~"=b[];");
	else static foreach(i; 0..size)
		mixin("a.data[i]"~op~"=b[i];");
	return a;
}
auto opOpAssignImpl(string op, size_t size,T,U)(ref Vec!(T, size) a, const U b) 
if (__traits(compiles, mixin("rvalueOf!T"~op~"rvalueOf!U")))
{
	static if(__traits(compiles,mixin("a.data[]"~op~"=b;")))
		mixin("a.data[]"~op~"=b;");
	else static foreach(i; 0..size)
		mixin("a.data[i]"~op~"=b;");
	return a;
}





private {
	NT[] arrayCast(NT,OT)(OT[] xs) {
		NT[] nxs = new NT[xs.length];
		foreach (i,e; xs) {
			nxs[i] = cast(NT) e;
		}
		return nxs;
	}
	NT[L] arrayCast(NT,OT,size_t L)(OT[L] xs) {
		NT[L] nxs;
		foreach (i,e; xs) {
			nxs[i] = cast(NT) e;
		}
		return nxs;
	}
}




unittest {
	import std.stdio;
	void testOp(string op)() {
		void testValues(A,B)(A a1, A a2, A a3, B b1, B b2, B b3) {
			void testConst(bool aConst, bool bConst)() {
				void testTypes(AT, BT)() {
					static if (aConst)
						const AT a = [a1,a2,a3];
					else
						AT a = [a1,a2,a3];
					static if (bConst)
						const BT b = [b1,b2,b3];
					else
						BT b = [b1,b2,b3];
					static assert(is(typeof(mixin("a"~op~"b")) == Vec!(typeof(a1+b1),3)));
					assert(mixin("a"~op~"b")== vec([mixin("a1"~op~"b1"),mixin("a2"~op~"b2"),mixin("a3"~op~"b3")]));
					static if(op=="*") {
						static assert(is(typeof(cross(a,b)) == Vec!(typeof(a1*b1),3)));
						static assert(is(typeof(dot(a,b)) == typeof(a1*b1)));
					}
				}
				testTypes!(Vec!(A,3), Vec!(B,3));
				testTypes!(Vec!(A,3), B[3]);
				testTypes!(A[3], Vec!(B,3));
			}
			testConst!(false,false);
			testConst!(true,true);
			testConst!(true,false);
			testConst!(false,true);
		}
		testValues!(int,int)(1,2,3,2,3,4);
		testValues!(float,float)(1.5,2.5,3,2.5,3,4.5);
		testValues!(int,float)(1,2,3,2.5,3,4.5);
		testValues!(float,double)(1.5,2.5,3,2.5,3,4.5);
	}
	testOp!"+";
	testOp!"-";
	testOp!"*";
	testOp!"/";
	testOp!"%";
}






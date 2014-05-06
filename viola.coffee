# ### Viola ###
# A coffeescript library of useful collections in a monadic style; Inspired by and loosely based upon the Scala Collections library
#   requires D3 (for Map)

# ### Option ###

class Some
	constructor: (@value) ->
	bind: (f) -> @flatMap(f)
	flatMap: (f) -> f(@value)
	map: (f) -> some(f(@value))
	forEach: (f) -> @map(f)
	getOrElse: (n) -> @value
	get: () -> @value
	isEmpty: () -> false
	nonEmpty: () -> true
	fold: (e, f) -> f(@value)

class None
	constructor: () ->
	bind: (f) -> this
	flatMap: (f) -> this
	map: (f) -> this
	forEach: (f) ->
	getOrElse: (n) -> n
	get: () -> throw exception # TODO
	isEmpty: () -> true
	nonEmpty: () -> false
	fold: (e, f) -> e

some = (v) -> new Some(v)
none = new None()
option = (v) -> if v then some(v) else none

# ### List ###

class List
	constructor: (@head, @tail) ->
	flatMap: (f) -> if @tail then f(@head).append( @tail.flatMap(f)) else f(@head)
	bind: (f) -> @flatMap(f)
	map: (f) ->cons(f(@head), @tail.map(f))
	forEach: (f) -> @map(f)
	isEmpty: () -> false
	length: () -> if @tail then @tail.length() + 1 else 1
	append: (l) -> if @tail then cons(@head, @tail.append(l)) else cons(@head, l)
	filter: (p) -> if p(@head) then cons( @head, @tail.filter(p)) else @tail.filter(p)
	flatten: () -> @reduce((a,b) -> a.append(b)) # List[List[T]] -> List[T]
	reduce: (f) -> if @tail then f(@head, @tail.reduce(f)) else @head

cons = (h, t) -> new List(h, t)
list = (elems...) -> if arguments.length > 0 then cons( arguments[0], list.apply(null, Array.prototype.slice.call(arguments,1))) else empty

class Empty
	constructor: () ->
	flatMap: (f) -> this
	bind: (f) -> @flatMap(f)
	map: (f) ->  this
	forEach: (f) ->
	isEmpty: () -> true
	length: () -> 0
	append: (l) -> l
	filter: (p) -> this
	flatten: () -> this
	reduce: (f) -> this

empty = new Empty

# ### Array ###

Array::toList = () ->
	switch @length
		when 0 then empty
		when 1 then cons( this[0], empty )
		else cons( this[0], @slice(1).toList() )

Array::zipWithIndex = ( ) ->
	arr = new Array()
	i = 0
	while i < @length
		arr[i] = T(this[i], i)
		i++
	arr

Array::mkString = ( join ) -> if @length > 0 then @slice(1).reduce( ((a,b) -> a + join + b), this[0] ) else ""

Array::flatten = () -> @reduce(((a,b) -> a.concat(b)), [])
Array::append = (a) -> @concat([a])

Array::fold = ( initial, f ) -> @foldImpl( initial, f, 0 )
Array::foldImpl = ( initial, f, i ) -> if (i < @length) then @foldImpl( f( initial, this[i] ), f, i + 1 ) else initial

# ### Tuple

Pair = (a, b) => _1: a, _2: b
Triple = (a, b, c) => _1: a, _2: b, _3: c
Quad = (a, b, c, d) => _1: a, _2: b, _3: c, _4: d

T = (args...) ->
	switch args.length
		when 2 then Pair( args[0], args[1] )
		when 3 then Triple( args[0], args[1], args[2] )
		when 4 then Quad( args[0], args[1], args[2], args[3] )
		else null
	
# ### Map
# An Immutable map in the style of Scala
# Wraps a D3 map but provides methods for producing new maps without mutating the original

class Map
	constructor: (values) ->
		@m = d3.map()
		_m = @m # Store for closure
		values.forEach( (v) -> _m.set(v._1, v._2))
	add: (key, value) ->
		ent = @m.entries()
		arr = ent.map((i) -> T(i.key, i.value))
		arr.push(T(key, value))
		new Map( arr )
	remove: (key) -> new Map( @m.entries().map((i) -> T(i.key, i.value)).filter((i) -> i._1 != key) )
	get: (key) -> @m.get(key)
	getOpt: (key) -> option(@m.get(key))
	values: () -> @m.values()
	keys: () -> @m.keys()
	entries: () -> @m.entries()
	filter: (f) -> new Map( @m.entries().map((i) -> T(i.key, i.value)).filter((i) -> f(i._1, i._2)))
	length: () -> @m.values().length
	map: (f) -> new Map(@entries().map((e) -> f(e.key, e.value)))

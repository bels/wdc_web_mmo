$(document).ready(function(){
	
});

window.util = window.util || (function(){
	var type_map = {};
	var core_toString = Object.prototype.toString.call;

	(function(){
		$.each('Boolean Function Array Date RegExp String'.split(' '), function(i, name){
			type_map['[object ' + name + ']'] = name;
		});
		if (Object.prototype.toString.call(undefined) === '[object Undefined]'){
			type_map['[object Undefined]'] = 'Undefined';
		}
		if (Object.prototype.toString.call(null) === '[object Null]'){
			type_map['[object Null]'] = 'Null';
		}
	}());
	return {
		'type': function(object){
			var long_type = core_toString(object);
			return type_map[long_type] || function(){
				if (typeof object === 'undefined'){
					return 'Undefined';
				} else if (object === null){
					return 'Null';
				} else if(object !== object){
					return 'NaN';
				} else {
					var type = long_type.splice(8, -1);
					if (type !== 'Object' && type !== 'Undefined' && type !== 'Number'){
						type_map[long_type] = type;
					}
					return type;
				}
			}();
		}
	};
})();

// Emulates perl6 Array.pick method.
if (!Array.prototype.pick){
	Object.defineProperty(Array, 'pick', {
		'value': function(number){
			var stack = [];
			if (this.length === 0){
				return this;
			}
			
			var l = this.length;
			if (number === '*'){
				number = l;
			}
			if (l > 0){
				stack.push(this.splice(Math.floor(Math.random() * l), 1)[0]);
			}
			if (number > 0){
				Array.prototype.push.apply(stack, Array.prototype.pick.call(this, --number));
			}
			
			return stack;
		}
	});
}
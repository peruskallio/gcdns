/**
 * Copyright 2014 Mainio Tech Ltd.
 * 
 * @author Antti Hukkanen
 * @license See LICENSE (project root)
 */

window.PathInitializer = {
	
	callbacks: {},
	matchers: {},
	
	add: function(name, match) {
		this.matchers[name] = match;
	},
	
	bind: function(name, callback) {
		if (typeof callback === "function") {
			if (typeof this.callbacks[name] === "undefined") {
				this.callbacks[name] = [];
			}
			this.callbacks[name].push(callback);
		}
	},
	
	register: function(path, callback) {
		this.add(path, path);
		this.bind(path, callback);
	},
	
	load: function() {
		var path = window.location.pathname;
		for (var i in this.matchers) {
			var regex = new RegExp("^" + this.matchers[i] + "$");
			if (regex.exec(path)) {
				var callbacks = this.callbacks[i];
				if (typeof callbacks !== "undefined") {
					for (var j=0; j < callbacks.length; j++) {
						callbacks[j].call(this, path);
					}
				}
			}
		}
	}
	
};

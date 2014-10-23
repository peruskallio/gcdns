/**
 * Copyright 2014 Mainio Tech Ltd.
 * 
 * Originally from:
 * http://stackoverflow.com/a/19557708/4145454
 * 
 * @author Antti Hukkanen
 * @license See LICENSE (project root)
 */

(function($) {

$(document).on('recordsapp:load', function() {
	RecordsApp.ArrayTransform = DS.Transform.extend({
		deserialize: function(serialized) {
			return (Ember.typeOf(serialized) == "array")
				? serialized 
				: [];
		},
		
		serialize: function(deserialized) {
			var type = Ember.typeOf(deserialized);
			if (type == 'array') {
				return deserialized;
			} else if (type == 'string') {
				return deserialized.split(',').map(function(item) {
					return jQuery.trim(item);
				});
			} else {
				return [];
			}
		}
	});
});

})(jQuery);

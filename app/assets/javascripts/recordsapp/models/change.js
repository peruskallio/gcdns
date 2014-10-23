/**
 * Copyright 2014 Mainio Tech Ltd.
 * 
 * @author Antti Hukkanen
 * @license See LICENSE (project root)
 */

(function($) {

$(document).on('recordsapp:load', function() {
	// Ember oddities, we cannot have the model names in plural format,
	// i.e. "Changes". It breaks some things with the saving process.
	
	// attr_accessor :id, :zone, :additions, :deletions, :status, :start_time
	RecordsApp.Change = DS.Model.extend({
		additions: DS.attr('array'),
		deletions: DS.attr('array'),
		startTime: DS.attr('date'),
		status: DS.attr('string')
	});
});

})(jQuery);
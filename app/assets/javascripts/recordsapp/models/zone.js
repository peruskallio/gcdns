/**
 * Copyright 2014 Mainio Tech Ltd.
 * 
 * @author Antti Hukkanen
 * @license See LICENSE (project root)
 */

(function($) {

$(document).on('recordsapp:load', function() {
	RecordsApp.Zone = DS.Model.extend({
		name: DS.attr('string'),
		description: DS.attr('string'),
		dnsName: DS.attr('string')
	});
});

})(jQuery);
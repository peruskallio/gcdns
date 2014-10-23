/**
 * Copyright 2014 Mainio Tech Ltd.
 * 
 * @author Antti Hukkanen
 * @license See LICENSE (project root)
 */

(function($) {

$(document).on('recordsapp:load', function() {
	RecordsApp.Record = DS.Model.extend({
		name: DS.attr('string'),
		type: DS.attr('string'),
		ttl: DS.attr('number'),
		datas: DS.attr('array')
	});
});

})(jQuery);
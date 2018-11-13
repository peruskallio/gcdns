/**
 * Copyright 2014 Mainio Tech Ltd.
 *
 * @author Antti Hukkanen
 * @license See LICENSE (project root)
 */

(function() {

$(document).on('recordsapp:load', function(ev, path) {
	// Override the default adapter with the `DS.RESTAdapter` which works with the
	// DNS record endpoints.
	RecordsApp.ApplicationAdapter = DS.RESTAdapter.extend({

		namespace: path.substring(1),

		pathForType: function(type) {
			if (type == 'record' || type == 'zone') {
				return 'records';
			}
			return this._super(type);
		}

	});
});

})();

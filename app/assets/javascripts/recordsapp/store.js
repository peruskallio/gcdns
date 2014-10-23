/**
 * Copyright 2014 Mainio Tech Ltd.
 * 
 * @author Antti Hukkanen
 * @license See LICENSE (project root)
 */

(function() {

$(document).on('recordsapp:load', function(ev, path) {
	RecordsApp.ApplicationStore = DS.Store.extend({
	
	});
	
	// Override the default adapter with the `DS.ActiveModelAdapter` which
	// is built to work nicely with the ActiveModel::Serializers gem.
	RecordsApp.ApplicationAdapter = DS.ActiveModelAdapter.extend({
		
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

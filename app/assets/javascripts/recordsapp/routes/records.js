/**
 * Copyright 2014 Mainio Tech Ltd.
 *
 * @author Antti Hukkanen
 * @license See LICENSE (project root)
 */

(function($) {

$(document).on('recordsapp:load', function() {
	RecordsApp.RecordsRoute = Ember.Route.extend({

		setupController: function(controller, model) {
			this._super(controller, model.records);
			controller.set('zone', model.zone);
			controller.startup();
		},

		model: function() {
			// We're not using Ember Data here because we want
			// to fetch all the records within the same request.
			// This way, we can prevent two exactly the same
			// API requests and save some time in the loading
			// up process.
			var route = this;
			return new Ember.RSVP.Promise(function(resolve, reject) {
				var apiEndpoint = RecordsApp.get('paths')['records'] + '/records';
				$.ajax({
					url: apiEndpoint
				}).then(function(resp) {
					if (resp.error) {
						reject(new Error('ajax call failed with message: `' + resp.error + '`'));
					} else {
						// Make sure the store is clear (needed to work with Turbolinks)
						// Wrap it in a Ember RunLoop because otherwise this issue may
						// arise: https://github.com/emberjs/data/issues/5111
						Ember.run(function() {
							route.store.unloadAll();
						});

						// Push the objects to the store
						route.store.pushPayload(resp);

						resolve(Ember.RSVP.hash({
							records: route.store.peekAll('record'),
							// There is always only one zone in the response
							// which is the zone of the records.
							zone: route.store.peekAll('zone').objectAt(0)
						}));
					}
				});
			});
		}

	});
});

})(jQuery);

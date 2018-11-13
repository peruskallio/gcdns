//= require_self
//= require ./store
//= require_tree ./transforms
//= require_tree ./mixins
//= require_tree ./models
//= require_tree ./controllers
//= require_tree ./views
//= require_tree ./helpers
//= require_tree ./components
//= require_tree ./templates
//= require ./router
//= require_tree ./routes
/**
 * Copyright 2014 Mainio Tech Ltd.
 *
 * @author Antti Hukkanen
 * @license See LICENSE (project root)
 */

// This cannot be within a $(document).ready() closure because
// this needs to run before any of those are run. The if statement
// here prevents these being run each time when the page is loaded.
// No need to do that since there these should only be run once
// when the document is initially started up.
if (typeof window.PATHS_BOUND === "undefined") {
	window.PATHS_BOUND = true;

	// Bind the zone path into the callback that creates the Ember.js records application.
	// The callback is called each time the page matching the defined path is loaded.
	PathInitializer.register('/projects/[0-9]+/zones/[0-9]+', function(path) {
		// Create the records managing app with Ember.js
		if (typeof window.RecordsApp === "undefined") {
			window.RecordsApp = Ember.Application.create({
				rootElement: '#records-app',
				Resolver: Ember.DefaultResolver.extend({
					resolveTemplate: function(parsedName) {
						// Set the templates to be found from the recordsapp template namespace.
						var appSpecific = Ember.copy(parsedName);

						appSpecific.fullNameWithoutType = 'recordsapp/' + appSpecific.fullNameWithoutType;
						appSpecific.fullName = "template:" + appSpecific.fullNameWithoutType;
						appSpecific.name = appSpecific.fullNameWithoutType;

						var resolvedTemplate = this._super(appSpecific);
						if (resolvedTemplate) { return resolvedTemplate; }

						return this._super(parsedName);
					}
				}),
				ready: function() {
					this.set('paths', {
						records: path
					});
				}
			});
			RecordsApp.Router.reopen({
				rootURL: path
			});

			// This is needed when the application is reloaded on the fly during
			// Turbolinks reloads. Without these, the application would show the
			// following errors and stop loading:
			// Uncaught Error: Cannot re-register: `transform:boolean`, as it has already been resolved.
			RecordsApp.initializer({
				name: 'fix-reloading-registries',
				before: ['ember-data'],
				initialize: function(registry) {
					registry.unregister('transform:boolean');
					registry.unregister('transform:number');
					registry.unregister('transform:string');
					registry.unregister('serializer:-rest');
				}
			});

			$(document).trigger('recordsapp:load', [path]);
		} else {
			// Re-load the application.
			// Remember to reset the paths so that the correct
			// records are loaded on the route initialization.
			RecordsApp.reopen({
				ready: function() {
					this.set('paths', {
						records: path
					});
				}
			});
			RecordsApp.Router.reopen({
				rootURL: path
			});

			RecordsApp.reset();
		}
	});
}

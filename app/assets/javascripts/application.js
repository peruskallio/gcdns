// Copyright 2014 Mainio Tech Ltd.
//
// @author Antti Hukkanen
// @license See LICENSE (project root)
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require jquery
//= require bootstrap/dropdown
//= require bootstrap/collapse
//= require bootstrap/transition
//= require nprogress
//= require nprogress-turbolinks
//= require jquery
//= require handlebars
//= require ember
//= require ember-data
//= require lib/path_initializer
//= require lib/chosen.jquery.min
//= require_tree ./views
//= require permissions
//= require_self

// Bind all the starting actions of a page to the "pageready"
// event so that we don't need to repeat both events each time.
$(document).on('ready page:load', function(ev) {
	var args = Array.prototype.slice.call(arguments);
	ev.originalType = ev.type;
	ev.type = "pageready";
	$(this).trigger(ev, args);

	PathInitializer.load();
	$('.permission-edit').permissionUI();
	$('select.chosen').chosen();
});

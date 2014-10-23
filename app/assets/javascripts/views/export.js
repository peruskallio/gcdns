/**
 * Copyright 2014 Mainio Tech Ltd.
 * 
 * @author Antti Hukkanen
 * @license See LICENSE (project root)
 */

PathInitializer.register('/projects/[0-9]+/export', function(path) {
	var $cnt = $('#export-container');
	var updateBulkSelectors = function() {
		var allSelected = true;
		$('.zone-selector input[type="checkbox"]', $cnt).each(function() {
			if (!$(this).is(':checked')) {
				allSelected = false;
			}
		});
		if (allSelected) {
			$('.bulk-selectors .select-all', $cnt).hide();
			$('.bulk-selectors .deselect-all', $cnt).show();
		} else {
			$('.bulk-selectors .select-all', $cnt).show();
			$('.bulk-selectors .deselect-all', $cnt).hide();
		}
	};
	
	$('.zone-selector input[type="checkbox"]', $cnt).on('click', function(ev) {
		ev.stopPropagation();
		updateBulkSelectors();
	});
	$('.zone-selector', $cnt).on('click', function(ev) {
		ev.preventDefault();
		
		var $inp = $('input[type="checkbox"]', this);
		if ($inp.is(':checked')) {
			$inp.prop('checked', false);
		} else {
			$inp.prop('checked', true);
		}
		updateBulkSelectors();
	});
	$('.btn.select-all', $cnt).on('click', function(ev) {
		ev.preventDefault();
		$('.zone-selector input[type="checkbox"]', $cnt).prop('checked', true);
		updateBulkSelectors();
	});
	$('.btn.deselect-all', $cnt).on('click', function(ev) {
		ev.preventDefault();
		$('.zone-selector input[type="checkbox"]', $cnt).prop('checked', false);
		updateBulkSelectors();
	});
	
	$('.bulk-selectors', $cnt).show();
	updateBulkSelectors();
});

PathInitializer.register('/projects/[0-9]+/export/[a-z0-9]+/process_done', function(path) {
	$('textarea#data').on('focus', function() {
		$(this).select();
	}).on('mouseup', function(ev) {
		ev.stopPropagation();
		ev.preventDefault();
	});
});
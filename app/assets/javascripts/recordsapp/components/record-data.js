/**
 * Copyright 2014 Mainio Tech Ltd.
 *
 * @author Antti Hukkanen
 * @license See LICENSE (project root)
 */

(function($) {

$(document).on('recordsapp:load', function() {
	RecordsApp.RecordDataComponent = Ember.Component.extend({

		actions: {

			removeRow: function() {
				this.sendAction('remove-action', this.get('index'));
			}

		},

		rowChanged: function() {
			var type = this.get('recordType');
			var value = {};
			if (this.get('recordTypeDefault') || type == 'TXT') {
				value.value = this.get('recordValue');
			} else if (type == 'MX') {
				value.hostname = this.get('recordValueHostname');
				value.priority = this.get('recordValuePriority');
			} else if (type == 'SRV') {
				value.target = this.get('recordValueTarget');
				value.port = this.get('recordValuePort');
				value.priority = this.get('recordValuePriority');
				value.weight = this.get('recordValueWeight');
			}
			this.sendAction('update-action', this.get('index'), value);
		}.observes('recordValue', 'recordValueHostname', 'recordValuePriority', 'recordValueTarget', 'recordValuePort', 'recordValueWeight'),

		init: function() {
			this._super();

			var type = this.get('record-type');
			var index = this.get('index');
			var value = this.get('value');
			var errors = this.get('errors');

			this.set('recordType', type);

			this.set('dataIndex', index + 1);
			this.set('canDelete', index > 0);

			var errorKeys = errors.filter(function(item) {
				return item.index == index;
			}).map(function(item) {
				return item.key;
			});

			errorKeys.forEach(function(key) {
				var dataKey = 'recordValue';
				if (key != 'value') {
					// e.g. recordValuePriorityError
					dataKey += key.charAt(0).toUpperCase() + key.slice(1);
				}
				this.set(dataKey + 'Error', true);
			}, this);

			var defaultType = true;
			if (type == 'A') {
				this.set('dataName', 'IP Address (IPv4)');
			} else if (type == 'AAAA') {
				this.set('dataName', 'IP Address (IPv6)');
			} else if (type == 'CNAME') {
				this.set('dataName', 'Hostname');
			} else if (type == 'SPF') {
				this.set('dataName', 'SPF');
			} else if (type == 'PTR') {
                this.set('dataName', 'Mapping');
            } else if (type == "SOA") {
                this.set('dataName', 'Hostname');
            } else if (type == "NS") {
                this.set('dataName', 'Hostname');
			} else {
				defaultType = false;
			}

			if (defaultType) {
				this.set('recordTypeDefault', true);
				this.set('valueIdAttribute', 'value' + index);
				this.set('recordValue', value.value);
			} else {
				// Record types that need special form elements.
				['MX', 'SRV', 'TXT'].forEach(function(testtype) {
					this.set('recordType' + testtype, type == testtype);
				}, this);

				if (type == 'MX') {
					this.set('valueIdAttributeHostname', 'hostname' + index);
					this.set('valueIdAttributePriority', 'priority' + index);
					this.set('recordValueHostname', value.hostname);
					this.set('recordValuePriority', value.priority);
				} else if (type == 'SRV') {
					this.set('valueIdAttributeHostname', 'target' + index);
					this.set('valueIdAttributePort', 'port' + index);
					this.set('valueIdAttributePriority', 'priority' + index);
					this.set('valueIdAttributeWeight', 'weight' + index);
					this.set('recordValueTarget', value.target);
					this.set('recordValuePort', value.port);
					this.set('recordValueHostname', value.hostname);
					this.set('recordValueWeight', value.weight);
				} else { // TXT
					this.set('valueIdAttribute', 'value' + index);
					this.set('recordValue', value.value);
				}
			}
		}

	});
});

})(jQuery);

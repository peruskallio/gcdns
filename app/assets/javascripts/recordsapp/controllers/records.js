/**
 * Copyright 2014 Mainio Tech Ltd.
 *
 * @author Antti Hukkanen
 * @license See LICENSE (project root)
 */

(function($) {

$(document).on('recordsapp:load', function() {

	var RECORD_TYPE_SORT_ORDER = Em.A(['SOA', 'NS', 'A', 'AAAA', 'CNAME', 'MX', 'PTR', 'SPF', 'SRV', 'TXT', 'PTR']);

	// Domain regex from:
	// http://www.mkyong.com/regular-expressions/domain-name-regular-expression-example/
	var domainRegex = /^((?!-)[A-Za-z0-9-]{1,63}(?!-)\.)+[A-Za-z]{2,6}\.$/;
	var numberRegex = /^[1-9][0-9]*$/;
	var numberRegexLeadingZero = /^[0-9]*$/;

	RecordsApp.RecordsController = Ember.Controller.extend({

		sortProperties: ['name'], // Also check out the orderBy function override.

		recordType: 'A',
		recordTypeA: true,
		recordDataRows: Ember.A([{}]),
		recordDataErrors: Ember.A(),
		isAdding: false,

		defaultTTL: 21600,

		fields: ["name", "TTL"],
		deletedRecords: Ember.A(),

		recordTypes: {

			A: {
				validate: {
					// Format: 1.2.3.4
					// http://www.mkyong.com/regular-expressions/how-to-validate-ip-address-with-regular-expression/
					value: {
						test: /^([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])$/,
						error: "Invalid IP address for %@."
					}
				}
			},

			AAAA: {
				validate: {
					// Format: 2607:f8b0:400a:801::1005
					// From: http://stackoverflow.com/a/17871737
					value: {
						test: /^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]).){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]).){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$/,
						error: "Invalid IP address for %@."
					}
				}
			},

			CNAME: {
				validate: {
					// Format: example.com.
					value: {
						test: domainRegex,
						error: "Invalid hostname for %@."
					}
				}
			},

			MX: {
				value: ["priority", "hostname"],
				validate: {
					// Format: 10 mail.example.com.
					hostname: {
						test: domainRegex,
						error: "Invalid hostname for %@."
					},
					priority: {
						test: numberRegexLeadingZero,
						error: "Invalid priority for %@."
					}
				}
			},

			SPF: {
				validate: {
					// Format: v=spf1 mx:example.com -all
					value: {
						// General level check against these possibilities:
						// http://www.openspf.org/SPF_Record_Syntax

						// The regexp is self made but does not check for 100% correct SPF syntax.
						// Does not make sure that all the parts of the record are actually valid
						// but it only validates the format of the spf record on a general level.
						// E.g. this allows multiple "redirect" and "exp" modifiers although the
						// specification only allows one of each. This also does not take any part
						// in validating that the mechanism arguments are always valid.
						// E.g. this would allow "v=spf1 a:-*älpöä" as a valid record

						// There would be also a complete regexp available but I do not think
						// it is necessary here because of its complexity:
						// http://www.schlitt.net/spf/tests/
						test: /^v=spf1(( [?~+-]?(((ip4|ip6|a|mx|)(:[^ ]+(\/[1-9][0-9]*)?)?)|((ptr)(:[^ ]+)?)|((exists|include):[^ ]+)|((a|mx)\/[1-9][0-9]*)))*( (redirect|exp)=[^ ]+)*( [?~+-]all))?$/,
						error: "Invalid SPF record for %@."
					}
				}
			},

			SRV: {
				value: ["priority", "weight", "port", "target"],
				validate: {
					// Format: 0 5 5060 sip.example.com.
					// (valuePriority valueWeight valuePort valueTarget)
					target: {
						test: domainRegex,
						error: "Invalid target for %@."
					},
					port: {
						test: numberRegex,
						error: "Invalid port for %@."
					},
					priority: {
						test: numberRegexLeadingZero,
						error: "Invalid priority for %@."
					},
					weight: {
						test: numberRegexLeadingZero,
						error: "Invalid weight for %@."
					}
				}
			},

			TXT: {
				validate: {
					// Only thing to check for TXT is that it is not empty.
					// This can contain anything.
					value: {
						test: "exists",
						error: "Invalid text for %@."
					}
				}
			},

            NS: {
                validate: {
                    value: {
                        test: domainRegex,
                        error: "Invalid mapping for %@."
                    }
                }
            },

            PTR: {
                validate: {
                    value: {
                        test: domainRegex,
                        error: "Invalid mapping for %@."
                    }
                }
            },

            SOA: {
                value: ["primary", "responsible", "version", "refresh", "retry", "timeout", "negative"],
                setErrorsOnMain: true,
                validate: {
                    primary: {
                        test: domainRegex,
                        error: "Invalid primary name server."
                    },
                    responsible: {
                        test: domainRegex,
                        error: "Invalid responsible party for the domain."
                    },
                    version: {
                        test: numberRegex,
                        error: "Invalid version."
                    },
                    refresh: {
                        test: numberRegex,
                        error: "Invalid refresh."
                    },
                    retry: {
                        test: numberRegex,
                        error: "Invalid retry."
                    },
                    timeout: {
                        test: numberRegex,
                        error: "Invalid timeout."
                    },
                    negative: {
                        test: numberRegex,
                        error: "Invalid negative."
                    },
                }
            }
		},

		actions: {

			toggleRecordForm: function(record) {
				if (this.get('isFormVisible')) {
					this.set('isAdding', false);
					this.set('isEditing', false);
					this.set('recordForEdit', null);
				} else {
					this._resetFields();
					this._resetErrors();
					this._setRecordType('A');
					this.set('isAdding', true);
					this.set('recordTTL', this.get('defaultTTL'));
					this.set('recordPermanent', false);
				}
			},

			toggleRecordType: function(type) {
				var name = this.get('recordName');
				var ttl = this.get('recordTTL');

				this._resetFields();
				this._resetErrors();
				this._setRecordType(type);

				this.set('recordName', name);
				this.set('recordTTL', ttl);
			},

			editAuthorativeEmail: function() {
				this.set('authorativeEmailError', false);
				this.set('editingAuthorativeEmail', true);
			},

			saveAuthorativeEmail: function() {
				var email = this.get('authorativeEmail');
				// Only special characters we allow in the local part are "_" and "-".
				if (/^[A-Za-z0-9_-]+@((?!-)[A-Za-z0-9-]{1,63}(?!-)\.)+[A-Za-z]{2,6}$/.test(email)) {
					this.set('editingAuthorativeEmail', false);

					// Update the SOA record if the email has changed,
					// also marking the record as dirty.
					var soa = this.get('soaRecord');
					var soaData = soa.get('datas')[0].split(" ");
					var authorativeEmail = email.replace('@', '.') + '.';
					if (soaData[1] != authorativeEmail) {
						soaData[1] = authorativeEmail;
						soa.set('datas', [soaData.join(" ")]);
					}
				} else {
					this.set('authorativeEmailError', true);
					alert("Invalid authorative email address provided. Do not use special characters or the dot character (.) in the local part of the email address.");
				}
			},

			addDataRow: function() {
				this.get('recordDataRows').pushObject({});
				this._renderRecordData();
			},

			updateDataRow: function(index, value) {
				var rows = this.get('recordDataRows');
				rows[index] = value;
			},

			removeDataRow: function(index) {
				this.get('recordDataRows').removeAt(index);
				this._renderRecordData();
			},

			addRecord: function() {
				var recordData = this._handleRecordForm();

				if (recordData) {
					// Check that there is not already an existing record of the same type and name.
					// Google Cloud DNS does not allow this, please check:
					// https://cloud.google.com/dns/migrating-bind-differences
					var type = this.get('recordType');
					var recordExists = this.get('model').any(function(item) {
						return item.get('type') == type && item.get('name') == recordData.name;
					});

					if (recordExists) {
						this.set('recordNameError', true);
						this.set('recordErrors', [Ember.String.fmt("%@-type record already exists with the given name.", [type])]);
					} else {
						var record = this.store.createRecord('record', {
							type: type,
							name: recordData.name,
							ttl: recordData.ttl,
							datas: recordData.datas
						});

						// Clear the values for further additions/editions
						this._resetFields();

						// Hide the adding form
						this.set('isAdding', false);
					}
				}
			},

			saveRecord: function(record) {
				var recordData = this._handleRecordForm();
				if (recordData) {
					record.set('name', recordData.name);
					record.set('ttl', recordData.ttl);
					record.set('datas', recordData.datas);

					// Clear the values for further additions/editions
					this._resetFields();
					this.set('recordForEdit', null);

					// Hide the adding form
					this.set('isEditing', false);
				}
			},

			editRecord: function(record) {
				this._resetFields();
				this._resetErrors();
				this.set('isAdding', false);
				this.set('isEditing', true);

				var type = record.get('type');
				var recordDataRows = this.get('recordDataRows');
				var editName = record.get('name');

				var dnsName = this.get('zone').get('dnsName');
				if (editName == dnsName) {
					editName = '@';
				} else {
					// -1 is for the extra dot in the end
					editName = editName.substring(0, editName.length - dnsName.length - 1);
				}

				// Pop the empty item out of the array
				recordDataRows.popObject();

				this._setRecordType(type);
				this.set('recordForEdit', record);
				this.set('recordName', editName);
				this.set('recordPermanent', record.get('permanent'));
				this.set('recordTTL', record.get('ttl'));

				record.get('datas').forEach(function(item) {
					var parts = item.split(" ");
					if (type == 'MX') {
						recordDataRows.push({
							priority: parts[0],
							hostname: parts[1]
						});
					} else if (type == 'SRV') {
						recordDataRows.push({
							priority: parts[0],
							weight: parts[1],
							port: parts[2],
							target: parts[3]
						});
					} else if (type == 'SOA') {
					    /* There should be only one SOA record! */
					    this.set('recordPrimary', parts[0]);
					    this.set('recordResponsible', parts[1]);
					    this.set('recordVersion', parts[2]);
					    this.set('recordRefresh', parts[3]);
					    this.set('recordRetry', parts[4]);
					    this.set('recordTimeout', parts[5]);
					    this.set('recordNegative', parts[6]);

					} else {
						recordDataRows.pushObject({value: item});
					}
				}, this);
			},

			removeRecord: function(record) {
				if (confirm("Are you sure you want to remove the selected DNS record?")) {
					// If the record is a new one, it has been added during this session
					// and it does not yet exist in the API. Therefore, we do not need
					// to delete it from the API.
					if (!record.get('isNew')) {
						this.get('deletedRecords').pushObject(record);
					}
					record.deleteRecord();

					// Make sure the form is not visible if the user was editing the record.
					if (this.get('isEditing')) {
						var er = this.get('recordForEdit');
						if (er.get('id') == record.get('id')) {
							this._resetFields();
							this.set('recordForEdit', null);
							this.set('isEditing', false);
						}
					}
				}
			},

			save: function() {
				// We want to send all the changes within a single backend request
				// instead of saving each record with individual calls, so this
				// is why we create the changes object manually and set the records
				// manually to their saved state (undirty).

				var model = this.get('model');

				var changes = this.store.createRecord('change', {
					additions: Ember.A(),
					deletions: Ember.A()
				});

				var hasChanges = model.any(function(item) {
					return item.get('hasDirtyAttributes');
				});
				if (hasChanges) {
					// Update the SOA record if some item has changed
					// i.e. increment the SOA serial number by 1.
					var soa = this.get('soaRecord');
					var soaData = soa.get('datas')[0].split(" ");

					// TODO: The SOA serial format could be configurable option (application config).
					// TODO: The same configuration should apply here and in the backend (Zone class).
					if (true) {
						// This only increments the SOA serial by 1 but does not have any limitations
						// in the amount of daily updates. Therefore, it is the default.
						soaData[2] = "" + (parseInt(soaData[2])+1);
					} else {
						// This puts the SOA serial in YYYYMMDDnn format but it has limitations
						// on the daily amount of changes allowed to the DNS records (99 max).
						var serial = soaData[2];
						var dt = new Date(), y = dt.getFullYear(), m = dt.getMonth()+1, d = dt.getDate();
						var currentDate = y + (m < 10 ? "0" : "") + m + (d < 10 ? "0" : "") + d;
						var soaIncrement = 0;
						if (serial.length == 10) {
							var datePart = serial.substring(0, 8);
							if (datePart == currentDate) {
								soaIncrement = parseInt(serial.substring(8, 10));
							}
						}
						if (soaIncrement > 98) {
							alert("Too many DNS changes within a day. Maximum number of changes within a single day is 99.");
							return false;
						}
						soaIncrement++;

						soaData[2] = currentDate + ((soaIncrement < 10 ? "0" : "") + soaIncrement);
					}
					soa.set('datas', [soaData.join(" ")]);
				}

				model.forEach(function(item) {
					if (item.get('isNew')) {
						changes.get('additions').pushObject(item.toJSON());
					} else if (item.get('hasDirtyAttributes')) {
						var attrs = item.changedAttributes();
						var del = {};
						var add = {};
						for (var key in attrs) {
							del[key] = attrs[key][0];
							add[key] = attrs[key][1];
						}

						// Merge the missing variables from the object
						// to the deletion and addition
						var values = item.toJSON();
						for (var key in values) {
							if (!del[key]) {
								del[key] = values[key];
							}
							if (!add[key]) {
								add[key] = values[key];
							}
						}

						changes.get('additions').pushObject(add);
						changes.get('deletions').pushObject(del);
					}
				}, this);

				this.get('deletedRecords').forEach(function(item) {
					changes.get('deletions').pushObject(item.toJSON());
				});

				if (changes.get('additions').length > 0 || changes.get('deletions').length > 0) {
					// Show loader
					this.set('isSaving', true);

					var self = this;
					changes.save().then(function() {
						// Mark the items as "undirty" as we have now handeled their saving prorcess.
						model.forEach(function(item) {
							if (item.get('hasDirtyAttributes')) {
								item.clean();
							}
						});

						// Remove deleted records from memory.
						self.set('deletedRecords', Ember.A());

						// Hide loader
						self.set('isSaving', false);

						// TODO: Wait for some time after which, reload the change
						// with the given ID. After the pending change is "done",
						// reload the records for this zone. Also note all the changes
						// that might have been made to the records and make sure that
						// dirty records are not replaced with those that are returned
						// by the server.
					}, function(response) {
						// Hide loader
						self.set('isSaving', false);

                        var title = "Save failed due to an error!";
                        var msg;
                        try {
                            msg = response.responseJSON.error.message;
                        } catch(e) {
                            msg = "Unknown error.";
                        }

                        if ($.fn.createModal) {
                            $.fn.createModal({ type: 'alert', title: title, message: msg });
                        } else {
                            alert(title + "\n\n" + msg);
                        }
					});
				} else {
					alert("No changes to be saved!");
				}
			},

			exit: function() {
				var unsavedChanges = this.get('model').any(function(item) {
					return item.get('hasDirtyAttributes');
				});
				var proceed = function() {
					var path = RecordsApp.get('backUrl');
					if (typeof Turbolinks !== "undefined") {
						Turbolinks.visit(path);
					} else {
						window.location = path;
					}
				};

				if (unsavedChanges) {
					if (confirm("There are unsaved changes. Are you sure you want to exit this view?")) {
						proceed();
					}
				} else {
					proceed();
				}
			}

		},

		init: function() {
			this._super();
		},

		startup: function() {
			var zone = this.get('zone');
			var soa = this.get('model').find(function(item) {
				return item.get('name') == zone.get('dnsName') && item.get('type') == 'SOA';
			});
			this.set('soaRecord', soa);
			this.set('authorativeEmail', soa.get('datas')[0].split(' ')[1].replace('.', '@').replace(/\.$/, ''));
			this.set('canEdit', RecordsApp.get('canEdit'));
		},

		isFormVisible: function() {
			return this.get('isAdding') || this.get('isEditing');
		}.property('isAdding', 'isEditing'),

		/**
		 * For some reason the sortProperties[] array does not currently support
		 * properties from the itemController because of which we need to
		 * customize the whole sorting function. See:
		 * https://github.com/emberjs/ember.js/issues/5267
		 *
		 * Otherwise we would use sortProperties together with itemController
		 * which would set the sortable properties on the model.
		 *
		 * Also, we don't want to override the arrangedContent property because
		 * we want to utilize the parent sorting methods if the result for both
		 * of our custom sorting methods are equal.
		 */
		orderBy: function(a, b) {
			var asort1 = a.get('name').split('.').length;
			var bsort1 = b.get('name').split('.').length;
			if (asort1 < bsort1) {
				return -1;
			} else if (asort1 > bsort1) {
				return 1;
			}

			var asort2 = RECORD_TYPE_SORT_ORDER.indexOf(a.get('type'));
			var bsort2 = RECORD_TYPE_SORT_ORDER.indexOf(b.get('type'));
			if (asort2 < bsort2) {
				return -1;
			} else if (asort2 > bsort2) {
				return 1;
			}

			return this._super(a, b);
		},

		_handleRecordForm: function() {
			this._resetErrors();

			var datas = [];
			var errors = [];
			var dataErrors = this.get('recordDataErrors');

			// Nor quite sure how to do proper validations in ember, so this
			// function is kind of bloated. Probably it would be better to
			// separate the handling of each form type to their own views and
			// sub-controllers but have not figured out yet how to do that...

			var recordType = this.get('recordType');
			var recordName = this._getString('recordName').toLowerCase(); // The API turns the names into lowercase format anyways.
			var recordTTL = this._getString('recordTTL');

			// This regex is different from the domainRegex because this also
			// allows single part domains because the domain name is appended
			// to them. Unfortunately, there is no lookbehind selector in the
			// JS implementation of the Regular Expression, so we need two
			// separate regexps to ensure that the string does not end with a
			// dash character (-).
			if (recordName != '@' && (!/^((?!-)((\*|[A-Za-z0-9-_]{1,63})\.)*([A-Za-z0-9-_]{1,63}))$/.test(recordName) || /-$/.test(recordName))) {
				this.set('recordNameError', true);
				errors.push("Invalid record name.");
			} else {
				// Change the record name for the actual representation
				var dnsName = this.get('zone').get('dnsName');
				if (recordName == '@') {
					// Google Cloud DNS does not allow @ records. Please check:
					// https://cloud.google.com/dns/migrating-bind-differences
					// But we use that to represent records for the top-level.
					recordName = dnsName;
				} else {
					// Google Cloud DNS requres the records to be in their full
					// representable format. Please check:
					// https://cloud.google.com/dns/migrating-bind-differences
					// We still allow and require the short syntax on the form.
					recordName = recordName + '.' + dnsName;
				}
			}

			if (!numberRegex.test(recordTTL)) {
				this.set('recordTTLError', true);
				errors.push("Invalid record TTL.");
			}

            var typeObject = this.recordTypes[recordType];

            /* Combine SOA record variables to recordData */
            if (recordType == "SOA") {
                var recordDataRow = [];
                Ember.A(typeObject.value).forEach(function(val) {
                    var valUpcase = val.charAt(0).toUpperCase() + val.slice(1);
                    recordDataRow[val] = this.get('record' + valUpcase);
                }, this);
                this.get('recordDataRows')[0] = recordDataRow;
            }

			if (typeObject) {
				var validations = typeObject.validate;
				var validRecord = true;
				if (validations) {
				    var model = this;
					// Go through all the validations for this record
					this.get('recordDataRows').forEach(function(data, index) {
						for (var key in validations) {
							var test = validations[key].test;
							var value = data[key];

							var success = false;
							if (value) {
								value = value.trim();

								if (test === "exists") {
									success = value.length > 0;
								} else if (test instanceof RegExp) {
									success = test.test(value);
								} else if (typeof test === "function") {
									success = test.call(this, value);
								}
							}

							if (!success) {
								validRecord = false;
								//this.set(dataKey + "Error", true);
								if (typeObject.setErrorsOnMain) {
								    var keyUpcase = key.charAt(0).toUpperCase() + key.slice(1);
								    model.set('record' + keyUpcase + 'Error', true);
								} else {
								    dataErrors.pushObject({index: index, key: key});
								}

								var message = Ember.String.fmt(validations[key].error, ["Record " + (index + 1)]);
								if (message) {
									errors.push(message);
								} else {
									errors.push("Invalid: " + key);
								}
							}
						}
					});
				}

				if (validRecord) {
					this.get('recordDataRows').forEach(function(rdata, index) {

						var value = "";
						if (typeObject.value) {
							for (var i=0; i < typeObject.value.length; i++) {
								var key = typeObject.value[i];
								if (i > 0) {
									value += " ";
								}
								var current = rdata[key];
								value += current.trim();
							}
						} else {
							value = rdata.value.trim();
						}
						datas.push(value);
					});
				}
				if (!validRecord || errors.length > 0) {
					// Run this to force the data elements to rerender with the errors.
					// Run also when there are other errors so that the error highlight
					// is taken off from a valid record.
					this._renderRecordData();
				}
			} else {
				errors.push("Invalid record type.");
			}

			if (errors.length > 0) {
				this.set('recordErrors', errors);
				return false;
			}

			return {
				name: recordName,
				ttl: recordTTL,
				datas: datas
			};
		},

		_renderRecordData: function() {
			// We need to swap the whole data array to be able to make the
			// #each block rerender itself. This is because we do not want
			// to create new observalbe objects for the data rows because
			// we want to represent them the same way they are represented
			// in the backend and the API.
			var newData = Ember.A();
			this.get('recordDataRows').forEach(function(item, index, enumerable) {
				newData.pushObject(item);
			});
			this.set('recordDataRows', newData);
		},

		_getString: function(key) {
			var val = this.get(key);
			if (val) {
				return val.toString().trim();
			}
			return "";
		},

		_setRecordType: function(type) {
			this.set('recordType', type);
			for (var testtype in this.recordTypes) {
				this.set('recordType' + testtype, type == testtype);
			}
		},

		_resetFields: function() {
			this.fields.forEach(function(value) {
				value = value.charAt(0).toUpperCase() + value.slice(1);
				this.set("record" + value, null);
			}, this);
			this.set('recordDataRows', Ember.A([{}]));
		},

		_resetErrors: function() {
			this.set('recordErrors', null);
			this.fields.forEach(function(value) {
				value = value.charAt(0).toUpperCase() + value.slice(1);
				this.set("record" + value + "Error", null);
			}, this);
			this.set('recordDataErrors', Ember.A([]));
		}

	});

});

})(jQuery);

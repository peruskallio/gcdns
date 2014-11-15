# GCDNS - UI for the Google Cloud DNS service

This software provides a UI for the Google Cloud DNS service. It is designed to work with the current version of the API (October, 2014) which is v1beta1.

Written in Ruby on Rails. Part of the UI is built with Ember.js.

Provided by [Mainio Tech](http://www.mainiotech.fi/).


## Update November 2014

As of November 2014, the [Google Cloud Developer Console](https://developers.google.com/console/help/new/) now also provides a UI for managing the records.
Therefore, it is unlikely that this project will see any progress in the future.

This will still be available here as a reference implementation or a way to import or export the records into the Cloud DNS platform as those features are
not provided by the current version of the Developer Console DNS management UI.


## Features

* Attaching projects from the Google API console to be managed with this software
* Managing the domain zones for the attached projects
* Managing the DNS records of the zones
* Importing DNS records from the bind zone format
* Exporting DNS records to the bind zone format


## Requirements

A server capable of running Ruby on Rails.


## Installation

* Configuration
* Database creation
* Database initialization
* Deployment instructions


### Rails Basics

Run the `bundle install` command to install all the gems. After that, create the database with `rake db:create`.

For starting up the development server, run `rails s`.


### Application Specific

Create the initial user for using the software with the following rake command:

```
rake gcdns:create_user[email@address.com,password]
```

Replace 'email@address.com' with your email you want to use for logging in and 'password' with your password. Remember to clear your shell history after running this command.


## Getting Started

There are some differences between what the Google Cloud DNS allows compared to bind. These differences are partly reasons for some of the decicions we have made in the UI.
Please see this article for more information about these differences:
https://cloud.google.com/dns/migrating-bind-differences


## Testing

No tests are written for this project. Feel free to contribute.


## Notes

* No parts of this project are very heavily tested. Use at your own risk and know what you are doing.
* You should understand at least the very basics of DNS and DNS records.


## TODO

* Import / Export refactoring:
* Remove duplicate code in import / export controllers and views. (Generalize)
* Move import / export view JS code into the view specific JS files.


## Missing Features and Improvements

Some missing features which would be nice if someone wants to contribute to this project:

* Default project on account-level (user is automatically redirected to this project after a successful login)
* Tests would be nice
* Support for UI translations (note: translating the API errors might be quite tricky as they are not documented anywhere...)
* User roles and permissions for the project-level access.
* Showing the changes backtrace for the zones (available through the API).
* Showing pending changes for the zones (available through the API).
* The UI could be optimized better for usability. It might be a bit hard to understand and use currently.
* Mass updates of multiple records at a time. E.g. if I want to update the TTL for all the records at once.
* Error handling could be improved at the server side.
* If the remote models were saved locally, the whole system would work much faster. However, it would require 2-way synchronization which is harder to implement than the current implementation.

Please first create Git issues for any features you would like to work on so that we can avoid duplicate work and coordinate the work properly.


## Future of This Project

Google Cloud Developer console now provides a UI for managing the Cloud DNS records so it is unlikely that this project will be maintained.

However, this project still acts as a good reference implementation on using the Cloud DNS API and also this provides some functionality that
the current (November 2014) Cloud DNS UI does not. This functionality includes importing and exportign the DNS records in the BIND zone format.


## Copyrights and License

All software related solely to this project is distributed under the MIT License. See the LICENSE document for more information.

All publicly available documents and images of this project, including this README file are under the CC BY 3.0 license.
See the following page for more information:
http://creativecommons.org/licenses/by/3.0/

The software and related documentation is written by Mainio Tech Ltd. (See: www.mainiotech.fi).

The original author of this software is Antti Hukkanen <antti.hukkanen (at) mainiotech.fi>.

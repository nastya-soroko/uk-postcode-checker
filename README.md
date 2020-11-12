# UK Postcode checker
Simple application with UI where users can input the UK postcode to find out if it is in the allowed zone. Zones and specific codes can be configurable.

## Setup
1. `cd` to the project directory
2. Use ruby version 2.7.2
3. Postgres is required and used as a DB, make sure it is installed and the user is configured
4. `bundle install`
5. `rake db:setup`
6. To run application use `rails s`, accessible in a browser on `localhost:3000`
7. To run all specs `rspec`, to see the coverage after `rspec` run `open coverage/index.html`
8. To analyze the code quality run `rubocop`


## Notes
- Assume this code can go to production. But before the actual production release, I would ask a lot of questions, like: postcode validations requirements; DB choice requirements, requirements about how to store allowed postcode lists, and if we should at all because it isn't clear how often the list can be updated; errors handling rules and layers; if we potentially need a localization in the future.
- According to all the mentioned questions there are assumptions about how to deal with them.
- Settings with allowed postcodes lists are stored to DB using 'rails-settings-cached' gem just to make it faster, specs for the model aren't present since there is no big sense to test how the gem works. Can be used to change lists in the admin UI or just in the rails console.
- Validation for a postcode is very simple on both client and server sides, using the simplest regexp from http://postcodes.io/ docs.
- Error handling is simple, rails logging for the server-side, and one general error message for the client-side since there is no requirement about this.
- Specs could be improved by extracting all the typical http://postcodes.io/ request's stubs to some common place to reuse in the different specs layers. But I think in the terms of test task it is ok without it.

Initializing Traitor
--------------------

**Note**: this document assumes you are using *Rspec* and Rails/ActiveRecord.

In your `spec_helper.rb`, add:

```ruby
require 'traitor'
Traitor.find_definitions # automatically load traitor definitions
Traitor::Config.configure_for_rails! # set up for ActiveRecord
```

The above configuration method will build objects passing in `without_protection: true`, will
save objects that are created with `create` by calling `object.save`, and will pass in
`validate: false` to the save method.

If you would prefer to keep validation intact, use `Traitor::Config.configure_safe_for_rails!`
instead.

Defining Traitors
------------------

Each traitor has a name and a set of attributes. `Traitor.define` takes as its first argument
a symbol representing the underscored version of the class name. Each subsequent keyword
argument is a key representing the name of the trait, and the value must be a hash. the
hash defines the attributes to pass into the object on initialization. If the value is
a lambda or proc, it will be called when the object is built or created.

```ruby
# This will guess the User class
Traitor.define :user,
  default_traits: {
    first_name: "John",
    last_name:  "Doe",
    admin: false
  },
  with_uuid: {
    uuid: ->{ SecureRandom.uuid } # this value is calculated at build/create time, not definition time.
  }
end
```

**Note**: Default attributes to be assigned must be underneath the `:default_traits` trait key. This is a
special key that is always the first to be merged into the list of attributes.

**Note**: Use lambdas without arguments (e.g. `->{ }`) to define a value that should be calculated at
construction time instead of definition time.

It is highly recommended that you have one traitor for each class that provides the simplest
set of attributes necessary to create an instance of that class. If you're creating ActiveRecord
objects, that means that you should only provide attributes that are required through validations
and that do not have defaults. Other traitors can be created through inheritance to cover common
scenarios for each class.

Attempting to define multiple traitors with the same name will raise an error.

traitors can be defined anywhere, but will be automatically loaded after
calling `Traitor.find_definitions` if traitors are defined in files at the
following locations:

    test/traitors.rb
    spec/traitors.rb
    test/traitors/*.rb
    spec/traitors/*.rb

Blocks/Triggers
---------------

Similar to FactoryGirl, a trait can define triggers to occur after build or create, but before the
record is handed off to the system. This is done by specifying a key of `:after_build` or
`:after_create` in your traitor definition, whose value must be a callable `Proc` or `Lambda`, with
a single parameter that represents the constructed object. `:after_build` occurs when both building
and creating, after the build has completed; `:after_create` occurs after the build AND the create's
save method have been called.

E.G.:

```ruby
Traitor.define :user,
  post_save_update: {
    after_create: ->(record) {
      puts "this occurs after the record has been saved, being created with this trait!"
      record.stubber = true
    },
  after_build: ->(record) {
    puts "this occurs every time a User is built, no matter what!"
    record.foo = :bar
  }
```

Note that these build/create triggers are *not* put in the `:default_traits` key.

Special Keys on Definitions
===========================

* `:default_traits` -- this defines attributes that will *always* be loaded on an object.
* `:after_build` -- this must have a value of a proc or lambda. That proc will be executed
  after the object has been built, passing in the built object.
* `:after_create` -- this must have a value of a proc or lambda. That proc will be executed
  after the object has been built and saved with the `Traitor::Config.create_method`., passing
  in the created object.
* `:create_using` -- objects for this object will be created using the value defined here instead
  of `Traitor::Config.create_method`
* `:create_using_kwargs` -- must be a hash. the keyword arguments to be passed in via ** when
  calling the `:create_using` method. ignored otherwise.

Special Keys On Traits
======================

* `:after_build` -- this must have a value of a proc or lambda. That proc will be executed
  after the object has been built, passing in the built object.
* `:after_create` -- this must have a value of a proc or lambda. That proc will be executed
  after the object has been built and saved with the `Traitor::Config.create_method`., passing
  in the created object.

Using Traitors
--------------

Simply use `Traitor.build` or `Traitor.create` to use your defined traitors. `build` will
just construct the object; `create` will, after building the object, call the save method
defined by `Traitor::Config.save_method` to save the object.

you can also use `Traitor.create_using(klass, alternate_create_method)` to create an object
using a different method just for that particular instance.

It is highly recommended that you prefer `build` whenever possible to avoid unnecessary
database usage.

Configuring Traitors
--------------------

The following can be configured:

* `Traitor::Config.build_kwargs` - must be a hash. Keyword arguments to pass as
  kwargs when calling class.new().
* `Traitor::Config.build_as_list` - boolean. Defaults to false. If false, new is
  called using `class.new(attributes, **build_kwargs)`. If true, attributes are
  also treated as kwargs, and build_kwargs are merged into it.
* `Traitor::Config.create_method` - The method to call to save the object after
  building it.
* `Traitor::Config.create_kwargs` - Must be a hash. Keyword arguments to pass as
  kwargs when calling the create method.
* `Traitor::Config.no_callbacks` - boolean. If true, raise an error if any definitions
  exist with :after_build/:after_create defined.

Helpers
-------

Traitor::Helpers::ActiveRecord
==============================

Right now, there is one helper for ActiveRecord, which extends ActiveRecord to add
a method which is incredibly fast, as it directly executes an insert statement. That
means there is no validation and no triggers. It is recommended to use this when you
are testing scopes or other database-based behavior but do not care about particular
values.

To use it, in your spec_helper.rb, add:

```ruby
require 'traitor/helpers/active_record'
Traitor::Config.create_method = :create_without_validations
# alternatively, define :create_using as :create_without_validations on the traitors you want to
# use this behavior, or call Traitor.create_using(<:class>, :create_without_validations, *traits, **attributes)
```

Traitor::Helpers::RSpec
=======================

In your `spec_helper.rb`, if you `require 'traitor/helpers/rspec'`, you can define
traitor configurations at the block level using metadata. Simply define a metadata
key with 'traitor_<config>: <value>', where config is one of the configurable values.

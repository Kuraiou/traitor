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
    uuid: ->{ SecureRandom.uuid }
  }
end
```

It is highly recommended that you have one traitor for each class that provides the simplest set of attributes necessary to create an instance of that class. If you're creating ActiveRecord objects, that means that you should only provide attributes that are required through validations and that do not have defaults. Other traitors can be created through inheritance to cover common scenarios for each class.

Attempting to define multiple traitors with the same name will raise an error.

traitors can be defined anywhere, but will be automatically loaded after
calling `Traitor.find_definitions` if traitors are defined in files at the
following locations:

    test/traitors.rb
    spec/traitors.rb
    test/traitors/*.rb
    spec/traitors/*.rb


v0.0.7
------
* added the '+' special character for attributes; if used, it will treate that
  attribute as a list, and concatenate the value to it. Note that attribute keys
  must still by symbols; use `:'+ATTR' => VALUE` to define the attribute.
* Minor refactoring.
* In `Traitor::Helpers::ActiveRecord#create_without_callbacks`:
  * Fixed an issue with the adapters not setting `@new_record` to false.
  * When using the PG adapter, the code will automatically assign `created_at` and
    `updated_at` if those attributes exist and are empty. This makes it much easier
    to deal with timestamps on the object, which are highly recommended.
  * When using the PG adapter, collect ALL values and assign them back, in case the
    DB has its own hooks that modify the data.
* Added code-level documentation.

v0.0.5
------

* added the `:create_using` special argument for defining a Traitor.
* refactored the code.
* added `Traitor::Config.no_callbacks` to prevent people from defining callbacks.
* added `Traitor::Helpers::ActiveRecord`, which defines a `create_without_callbacks`
  extension to ActiveRecord that ignores all validations and callbacks by doing a
  raw sql insert. See documentation for details.
* added `Traitor::Helpers::RSpec` which can be used to define traitor rules in
  metadata on RSpec groups.
* updated documentation.

v0.0.4
------

* changed `Traitor::Config.save_method` and `Traitor::Config.save_kwargs` to
  `Traitor::Config.create_method` and `Traitor::Config.create_kwargs` so all
  language is consistent.
* fixed a typo in the build kwarg `Traitor::Config.configure_for_rails!`

v0.0.3
------

* Added support for `:after_build`, `:after_create` blocks.
* Removed passed-in blocks; all triggers rely on Proc/Lambda.
* Added support for `Traitor::Config.build_with_list`.
* Improved documentation.

v0.0.1
------

* Initial release.
* can build or create(build + save) objects.
* basic configuration to support ActiveRecord.
* basic level of testing.

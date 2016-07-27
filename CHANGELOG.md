v0.0.5
------

* added the `:create_using` special argument for defining a Traitor.
* refactored the code.
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

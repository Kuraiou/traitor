# traitr
A lightweight system-agnostic spin on FactoryGirl.

Traitor has no DSLs and has no dependencies. It does one thing: allow you to group key/value pairs to a name, and then use that to easily build objects.

Documentation
-------------

See [GETTING_STARTED](GETTING_STARTED.md) for information on defining and using traitors.

Install
--------

Add the following line to Gemfile:

```ruby
gem 'traitr'
```

and run `bundle install` from your shell.

To install the gem manually from your shell, run:

```shell
gem install traitr
```

Once you've got it installed, in your spec_helper, use

```ruby
require 'traitor'
Traitor::Config.configure_for_rails!
```

or explicitly define `Traitor::Config.create_method`, `Traitor::Config.create_kwargs`, and `Traitor::Config.build_kwargs`.

**WARNING**: This gem is not related to nor compatible with [txus/traitor](https://github.com/txus/traitor), which is `traitor` on rubygems.org

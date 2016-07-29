Gem::Specification.new do |s|
  s.name = 'traitr'
  s.version = '0.0.6'
  s.summary = 'a lightweight way to bind groups of attributes to a trait.'
  s.description = 'a lightweight, simplified, pure-ruby way to handle object model construction, similar to FactoryGirl.'
  s.authors = ['Zach Lome']
  s.email = ['zslome@gmail.com']
  s.homepage = 'https://github.com/kuraiou/traitor'
  s.license = 'MIT'

  s.files = [
    'lib/traitor.rb', 'lib/traitor/config.rb', 'lib/traitor/error.rb',
    'lib/traitor/find_definitions.rb', 'lib/traitor/helpers/active_record.rb',
    'lib/traitor/helpers/rspec.rb'
  ]
  s.require_path = 'lib'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rspec',        '>= 3.0'
  s.add_development_dependency 'rspec-its',    '>= 1.0'
  s.add_development_dependency 'timecop'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'activerecord', '~> 4'
end

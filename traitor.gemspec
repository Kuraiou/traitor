Gem::Specification.new do |s|
  s.name = 'traitor'
  s.version = '0.0.1'
  s.summary = 'traitor provides a lightweight wrapper to group attributes as traits'
  s.description = 'a lightweight, simplified, DSL-less version of factory girl.'
  s.authors = ['Zach Lome']
  s.email = ['zslome@gmail.com']
  s.homepage = 'https://github.com/kuraiou/traitor'
  s.license = 'MIT'

  s.files = ['lib/traitor.rb']
  s.require_path = 'lib'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-its'

  s.add_dependency 'activerecord'
end

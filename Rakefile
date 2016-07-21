require 'rubygems'
require 'bundler'
require 'rspec/core/rake_task'

Bundler.setup :default, :test, :development
Bundler::GemHelper.install_tasks

namespace :spec do
  desc 'Run unit specs'
  RSpec::Core::RakeTask.new(:spec) do |spec|
    spec.pattern = 'spec/**/*_spec.rb'
  end
end

task :spec
task default: :spec

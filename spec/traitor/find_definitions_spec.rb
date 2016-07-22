# pulled from https://github.com/thoughtbot/traitor_girl/blob/master/spec/traitor_girl/find_definitions_spec.rb
# on 2016-07-22
require 'spec_helper'

shared_examples_for "finds definitions" do
  before do
    allow(Traitor).to receive(:load)
    Traitor.find_definitions
  end

  subject { Traitor }
end

RSpec::Matchers.define :load_definitions_from do |file|
  match do |given|
    @has_received = have_received(:load).with(File.expand_path(file))
    @has_received.matches?(given)
  end

  description do
    "load definitions from #{file}"
  end

  failure_message do
    @has_received.failure_message
  end
end

describe "definition loading" do
  def self.in_directory_with_files(*files)
    before do
      @pwd = Dir.pwd
      @tmp_dir = File.join(File.dirname(__FILE__), 'tmp')
      FileUtils.mkdir_p @tmp_dir
      Dir.chdir(@tmp_dir)

      files.each do |file|
        FileUtils.mkdir_p File.dirname(file)
        FileUtils.touch file
      end
    end

    after do
      Dir.chdir(@pwd)
      FileUtils.rm_rf(@tmp_dir)
    end
  end

  describe "with traitors.rb" do
    in_directory_with_files 'traitors.rb'
    it_should_behave_like "finds definitions" do
      it { should load_definitions_from('traitors.rb') }
    end
  end

  %w(spec test).each do |dir|
    describe "with a traitors file under #{dir}" do
      in_directory_with_files File.join(dir, 'traitors.rb')
      it_should_behave_like "finds definitions" do
        it { should load_definitions_from("#{dir}/traitors.rb") }
      end
    end

    describe "with a traitors file under #{dir}/traitors" do
      in_directory_with_files File.join(dir, 'traitors', 'post_traitor.rb')
      it_should_behave_like "finds definitions" do
        it { should load_definitions_from("#{dir}/traitors/post_traitor.rb") }
      end
    end

    describe "with several traitors files under #{dir}/traitors" do
      in_directory_with_files File.join(dir, 'traitors', 'post_traitor.rb'),
                              File.join(dir, 'traitors', 'person_traitor.rb')
      it_should_behave_like "finds definitions" do
        it { should load_definitions_from("#{dir}/traitors/post_traitor.rb") }
        it { should load_definitions_from("#{dir}/traitors/person_traitor.rb") }
      end
    end

    describe "with nested and unnested traitors files under #{dir}" do
      in_directory_with_files File.join(dir, 'traitors.rb'),
                              File.join(dir, 'traitors', 'post_traitor.rb'),
                              File.join(dir, 'traitors', 'person_traitor.rb')
      it_should_behave_like "finds definitions" do
        it { should load_definitions_from("#{dir}/traitors.rb") }
        it { should load_definitions_from("#{dir}/traitors/post_traitor.rb") }
        it { should load_definitions_from("#{dir}/traitors/person_traitor.rb") }
      end
    end

    describe "with deeply nested traitor files under #{dir}" do
      in_directory_with_files File.join(dir, 'traitors', 'subdirectory', 'post_traitor.rb'),
                              File.join(dir, 'traitors', 'subdirectory', 'person_traitor.rb')
      it_should_behave_like "finds definitions" do
        it { should load_definitions_from("#{dir}/traitors/subdirectory/post_traitor.rb") }
        it { should load_definitions_from("#{dir}/traitors/subdirectory/person_traitor.rb") }
      end
    end
  end
end

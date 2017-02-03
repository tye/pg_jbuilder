# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pg_jbuilder/version'

Gem::Specification.new do |spec|
  spec.name          = "pg_jbuilder"
  spec.version       = PgJbuilder::VERSION
  spec.authors       = ["tye"]
  spec.email         = ["tye@tye.ca"]
  spec.summary       = %q{Use PostgreSQL JSON functions to dump database queries directly to a JSON object or array.}
  spec.description   = %q{pg_jbuilder is a tool to dump database queries directly to a JSON object or array. It uses PostgreSQL's JSON functions ([array_to_json and row_to_json](http://www.postgresql.org/docs/9.3/static/functions-json.html)) to serialize the JSON completely bypassing ActiveRecord/Arel. This gives a large speed boost compared to serializing the JSON inside of Ruby/Rails. It is perfect for creating JSON APIs with very low response times.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'activerecord', '>= 3.0.0'
  spec.add_dependency 'pg', '>= 0'
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", '~> 10.4', '>= 10.4.2'
  spec.add_development_dependency "rspec", '~> 3.1', '>= 3.1.0'
  #spec.add_development_dependency 'guard-rspec', '~> 0'
  spec.add_development_dependency "rails", '~> 4.2.0'
  spec.add_development_dependency 'sqlite3'
end


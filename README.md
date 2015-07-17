# paperclip-sample
Rails 4 paperclip usage example has record with multiple image attachments

## The environment

We use [rbenv](https://github.com/sstephenson/rbenv) and current Ruby, 
`ruby 2.1.5p273 (2014-11-13 revision 48405) [x86_64-darwin13.0]`
(on a Mac OS X Yosemite Version 10.10.4, yes, we're spoiled).

We also use [RubyGems](https://rubygems.org) at version 2.4.8 and 
[Bundler](http://bundler.io/v1.9/)
at version 1.9.9 to avoid the dreaded "BUNDLED WITH" virus.
We hope someone soon succeeds in knocking some sense
into the people who added BUNDLED WITH to Bundler and have that removed.
(Several have tried.)
Until then, or until we give up, `gem install bundler -v 1.9.9`

We're used to [RSpec](http://www.rubydoc.info/gems/rspec-rails/frames).
We have nothing to say against MiniTest.
The RSpec people seduced us and that's the world we know.
The Gemfile.lock shows the version in use.
```
rails new -T paperclip-sample
cd paperclip-sample
rails generate rspec:install
```

We're not using RDoc, either.  But perhaps we ought to.


## Procedure

We start by bootstrapping a Rails 4 app according to
[Getting Started With Rails](http://guides.rubyonrails.org/getting_started.html)
Find the version in use documented in the Gemfile.


## A note about the license

This is on a Creative Commons license so you can copy, paste and modify any 
part of this code without attribution.  That seems reasonable for sample code that
most would use in precisely that way.

However, taking a wholesale copy and representing it as your own work would be
reprehensible.  Few people pay respect to a person who has done such a thing.

If you like, you can provide attribution with a reference to this project, e.g.
"Learned from telegraphy-interactive/paperclip-sample on GitHub,
https://github.com/telegraphy-interactive/paperclip-sample"

## Editor's guide from Rails

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions


+++
author = "Tommaso Visconti"
categories = ["ruby", "tdd", "kata", "testing", "rspec"]
date = 2014-06-24T10:53:00Z
description = ""
draft = false
slug = "basic-setup-for-a-ruby-based-tdd-code-kata"
tags = ["ruby", "tdd", "kata", "testing", "rspec"]
title = "Basic setup for a Ruby-based TDD Code Kata"

+++

In the last weeks with the guys of the [Firenze Ruby Social Club](http://firenze.ruby-it.org/) we started to think about organizing some [Code Katas](http://en.wikipedia.org/wiki/Kata_%28programming%29) to play with [test-driven development](http://en.wikipedia.org/wiki/Test-driven_development) and yesterday we met to play with [The Game of Life](http://en.wikipedia.org/wiki/Conway%27s_Game_of_Life).

We used Ruby and RSpec with a simple setup that I want to report here if you'd like to play with some katas.

Although probably a Kata exercise won't need many gems, in ruby projects I like to always use a `Gemfile` with the required gems:

```prettyprint
ruby '2.1.2'
source 'https://rubygems.org'
gem 'rspec'
```

After a `bundle install` you're ready to start writing some code (if you don't have the `bundle` command, install the bundler gem with `gem install bundler`). 

A basic example to begin TDD with [the Game of Life](http://en.wikipedia.org/wiki/Conway%27s_Game_of_Life) could be this:

`game_of_life_spec.rb`:

```prettyprint lang-ruby
require './game_of_life'

describe GameOfLife::Universe do
  it "should have an initial size" do
    u = GameOfLife::Universe.new(6)
    expect(u.size).to eq(36)
  end
end
```

`game_of_life.rb`:

```prettyprint lang-ruby
module GameOfLife
  class Universe
    attr_reader :size
    def initialize(side)
      @size = side**2
    end
  end
end
```

With this minimalistic setup, the test passes:

```prettyprint
~$ bundle exec rspec --color game_of_life_spec.rb
.

Finished in 0.00095 seconds (files took 0.0966 seconds to load)
1 example, 0 failures
```

You're now ready to start playing with TDD in Ruby :)
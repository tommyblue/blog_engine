+++
author = "Tommaso Visconti"
categories = ["node", "tdd", "testing", "kata", "mocha"]
date = 2014-06-27T13:36:57Z
description = ""
draft = false
slug = "basic-setup-for-a-node-js-based-tdd-code-kata"
tags = ["node", "tdd", "testing", "kata", "mocha"]
title = "Basic setup for a Node.js-based TDD Code Kata"

+++

In the [last post](http://www.tommyblue.it/2014/06/27/basic-setup-for-a-ruby-based-tdd-code-kata/) I suggested a minimal setup to begin with ruby-based TDD. In this post I want to show a possibile minimal setup for node.js-based TDD (node.js and npm must be installed). The kata will be again [The Game of Life](http://en.wikipedia.org/wiki/Conway%27s_Game_of_Life). 

_I'm not an expert of [Node.js](http://nodejs.org/), so I hope what I'm writing is correct :)_

I'll use the test framework [Mocha](http://visionmedia.github.io/mocha/) and [expect.js](https://github.com/LearnBoost/expect.js/), a _"Minimalistic BDD-style assertions for Node.JS and the browser"_.

Let's begin with the `package.json` file which will tell to [npm](https://www.npmjs.org/) what to install:

```
{
  "name": "game-of-life",
  "version": "0.0.1",
  "dependencies": {
    "mocha": "*",
    "expect.js": "*"
  }
}
```

With this file in the project folder you can run `npm install` to install the libraries. Then create the `test/` folder with the `mocha.opts` file, where you can specify various options, like the [reporter](http://visionmedia.github.io/mocha/#reporters) to use:

```
--reporter spec
```

With this file in place, the `mocha` command will launch the test.
So write the minimal js file and its corresponding test file:

`test/game_of_life_test.js`:

```prettyprint lang-js
var expect = require('expect.js'),
  GameOfLife = require('../lib/game_of_life');

describe('Universe', function(){
  it('should have an initial size', function() {
    var u = new GameOfLife(6)
    expect(u.getSize()).to.equal(36);
  });
})
```

`lib/game_of_life.js`:

```prettyprint lang-js
function GameOfLife(side){
  this.size = side * side;
}
GameOfLife.prototype.getSize = function() { return this.size; }

module.exports = GameOfLife;
```

Now launch `mocha` and the first test should pass:

```
~$ mocha

  Universe
    âœ“ should have an initial size 

  1 passing
```

To know something more about TDD and Node.js, start reading [this post](http://webapplog.com/test-driven-development-in-node-js-with-mocha/) from [Azat Mardan](http://azat.co/)
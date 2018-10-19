+++
author = "Tommaso Visconti"
categories = ["elixir", "phoenix", "react", "typescript", "webpack"]
date = 2018-10-19T18:26:09Z
description = ""
draft = false
slug = "add-a-js-frontend-to-an-api-only-phoenix-app"
tags = ["elixir", "phoenix", "react", "typescript", "webpack"]
title = "How to add a JS frontend to an API-only Phoenix app"
image = "/images/2018/10/jose-alejandro-cuffia-799485-unsplash.jpg"

+++

If you generated a [Phoenix](https://phoenixframework.org/) app with the `--no-brunch` option you probably needed an API backend app.

What if, with your app growing, you realize you'd like to add also some frontend code?
This short how-to will show you how integrate a [Webpack](https://webpack.js.org/) based app with
support to [Typescript](https://www.typescriptlang.org/), [React](https://reactjs.org/) and [Sass](https://sass-lang.com/).

<!--more-->

_If, instead, you have a standard Phoenix app (with Brunch support) and you want to switch to webpack, then [read my previous article](/2017/09/05/react-sass-typescript-with-phoenix-framework-usingwebpack/)._

### Create the Webpack scaffolding

To begin, let's create some initial files in the `frontend` folder (which
needs to be created):

```bash
mkdir -p frontend/src
cd frontend/
npm init
touch src/index.tsx
touch src/style.scss
```

_All future commands are supposed to be ran from within the `frontend/` folder._

The `npm init` helped you create an initial `package.json` file. It is now time to add some required packages.

**Webpack**
```bash
yarn add -D webpack webpack-cli
```

**Babel**
```bash
yarn add -D babel-loader @babel/core @babel/preset-env
```

**Sass and CSS**
```bash
yarn add -D style-loader css-loader sass-loader node-sass
```

**Typescript**
```bash
yarn add -D typescript awesome-typescript-loader
```

**React** and its typings
```bash
yarn add react react-dom
yarn add -D @types/react @types/react-dom
```

Webpack's **extract-text plugin** (I'm using `@next` version because of an [annoying bug](https://stackoverflow.com/questions/51383618/chunk-entrypoints-use-chunks-groupsiterable-and-filter-by-instanceof-entrypoint) in the stable version):

```bash
yarn add -D extract-text-webpack-plugin@next
```

Don't forget to add the `node_modules` folder to your `.gitignore` file or you'll commit a lot of useless files:
```bash
echo node_modules > ../.gitignore
```

Also create Typescript config and linting files:

`tsconfig.json`
```json
{
	"compilerOptions": {
		"allowJs": true,
		"baseUrl": "js",
		"jsx": "react",
		"module": "commonjs",
		"moduleResolution": "node",
		"noImplicitAny": true,
		"outDir": "ts-build",
		"sourceMap": false,
		"target": "es5"
	},
	"include": [
		"./src/**/*"
	]
}
```

`tslint.json`
```json
{
  "extends": ["tslint:recommended", "tslint-react"],
  "rules": {
    "no-console": [false]
  }
}
```

_If, like me, you're running an editor that supports linting and you'll run it from the main app
folder, you probably want to symlink the `tslint.json` from there (or configure the editor linter
to find it inside the `frontend/` folder)._

Final step is to create the webpack configuration with the `frontend/webpack.config.js` file:

```js
const env =  process.env.NODE_ENV
const path =  require('path');

const ExtractTextPlugin =  require("extract-text-webpack-plugin");

module.exports = {
	entry: ['./src/index.tsx', './src/style.scss'],
	output: {
		path: path.resolve(__dirname, "../priv/static"),
		filename: "js/app.js"
	},
	resolve: {
		extensions: [".ts", ".tsx", ".js", ".jsx"],
		modules: ["deps", "node_modules"]
	},
	module: {
		rules: [{
			test: /\.scss$/,
			use: ExtractTextPlugin.extract({
				use: [{
					loader: "css-loader",
					options: {
						minimize: true,
						sourceMap: env ===  'production',
					}
				}, {
					loader: "sass-loader",
					options: {
						includePaths: [path.resolve('node_modules')]
					}
				}],
				fallback: "style-loader"
			})
		}, {
			test: /\.tsx?$/,
			loader: "awesome-typescript-loader"
		}, {
			test: /\.js$/,
			exclude: /(node_modules|bower_components)/,
			use: {
				'loader': 'babel-loader',
				options: {
					presets: ['@babel/preset-env']
				}
			}
		}]
	},
	plugins: [
		new  ExtractTextPlugin({
		filename: "css/app.css"
	})
	]
};
```

At this point the frontend pipeline is ready to be executed. From the `frontend` folder, run
```bash
webpack --watch-stdin --progress --color
```
and, hopefully, your app will be correctly compiled.

### Run the pipeline with Phoenix server

We want to run the pipeline when we execute `mix phx.server`. This can be done editing the `config/dev.exs` file:

```elixir
watchers: [
  node: [
    "node_modules/webpack/bin/webpack.js", "--watch-stdin", "--progress", "--color",
    cd: Path.expand("../frontend", __DIR__)
  ]
]
```

### React "Hello, World!"

Our scaffolding _should_ work, to verify it, let's create a simple React "Hello, World!".

It's simple enough to only be contained in the `frontend/src/index.tsx` file:

```js
import * as React from "react";
import * as ReactDOM from "react-dom";

const MainComponent = () => (<div className="hello-world">Hello, World!</div>);

ReactDOM.render(
    <MainComponent />,
    document.getElementById("app")
);

```

The template file at `lib/<app>_web/templates/layout/app.html.eex` must be edited adding the react entrypoint `<div id="app" />`.

It's done, run `mix phx.server` and profit:
```bash
mix phx.server

[info] Running <app>.Endpoint with Cowboy using http://0.0.0.0:4000
 10% building modules 1/1 modules 0 active
webpack is watching the files…
...
[debug] Live reload: priv/static/js/app.js
[debug] Live reload: priv/static/css/app.css
...
```

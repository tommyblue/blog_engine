+++
author = "Tommaso Visconti"
date = 2017-09-05T19:37:00Z
description = ""
draft = false
image = "/images/2018/03/1_ffJ5VWBKVuOnBBxhrKfXKQ-1.jpeg"
slug = "react-sass-typescript-with-phoenix-framework-using-webpack"
title = "React+Sass+Typescript with Phoenix framework using Webpack"

+++

If you’re playing with [Elixir](https://elixir-lang.org/) and [Phoenix](http://phoenixframework.org/) you’ll probably already know that Phoenix uses Brunch.io to build the assets pipeline.
I initially started building my app with React / Redux + SASS and I was quite happy, but when I decided to add Typescript to the recipe, I found Brunch.io wasn’t very helpful!

I’ve already used these tools using [Webpack](https://webpack.github.io/) as building tool, so I decided to switch to it.
I had a working Webpack configuration I was using in other projects, so I only had to find out how to apply it to Phoenix.

When I initially generated the Phoenix app, I didn’t use the `--no-brunch` command line flag to generate it without Brunch, and the app itself was alreadyt working. So I wanted to replace the existing Brunch config with the new one without nuking any existing feature.

Below you can find the (few) steps required for this upgrade.

## Remove Brunch and install Webpack

To remove Brunch, just remove the `assets/brunch-config.js` file and uninstall all brunch-related packages. In my case:

```bash
yarn remove brunch babel-brunch clean-css-brunch sass-brunch uglify-js-brunch
```

In the `assets/package.json` file you can also see that Brunch is mentioned in the scripts commands:

```json
"scripts": {
  "deploy": "brunch build --production",
  "watch": "brunch watch --stdin"
},
```

Replace them with the Webpack commands (to run the `webpack` command you’d probably need to globally install it with `yarn global add webpack`):

```json
"scripts": {
  "deploy": "webpack -p",
  "compile": "webpack --progress --color",
  "watch": "webpack --watch-stdin --progress --color"
},
```

You’re now ready to install the webpack ecosystem we’re going to use:

```bash
yarn add -D webpack babel-core babel-loader babel-preset-es2015 copy-webpack-plugin css-loader extract-text-webpack-plugin file-loader node-sass sass-loader style-loader webpack-notifier
```

## Add Typescript to the project
To add Typescript support we need some more packages too:

```bash
yarn add -D typescript ts-loader tslint tslint-react @types/phoenix @types/react @types/react-dom @types/react-redux
```

The Typescript configuration file is `assets/tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "es2015",
    "module": "es2015",
    "jsx": "preserve",
    "moduleResolution": "node",
    "baseUrl": "js",
    "outDir": "ts-build",
    "allowJs": true
  },
  "exclude": [
    "node_modules",
    "priv",
    "ts-build"
  ]
}
```

As you probably noticed in the previous command, I also installed [TSLint](https://palantir.github.io/tslint/) support for linting features. Add the related package to your editor (like vscode-tslint for VSCode) to have (almost-)real-time linting warnings.
You also need a configuration file, here’s `mytslint.json` file:

```json
{
  "extends": ["tslint:recommended", "tslint-react"],
  "rules": {
    "no-console": [false]
  }
}
```

## Webpack configuration
Before configuring Webpack, let’s configure Babel, using the `assets/.babelrc` file:

```json
{
  "presets": ["es2015", "react"]
}
```

And now, finally, the big part, the Webpack configuration file, `assets/webpack.config.js`:

```javascript
const env = process.env.NODE_ENV
const path = require("path")
const ExtractTextPlugin = require("extract-text-webpack-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin")
const config = {
  entry: ["./css/app.scss", "./js/app.js"],
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
      test: /\.tsx?$/,
      use: ["babel-loader", "ts-loader"]
    }, {
      test: /\.jsx?$/,
      use: "babel-loader"
    }, {
      test: /\.scss$/,
      use: ExtractTextPlugin.extract({
        use: [{
          loader: "css-loader",
          options: {
            minimize: true,
            sourceMap: env === 'production',
          },
        }, {
          loader: "sass-loader",
          options: {
            includePaths: [path.resolve('node_modules')],
          }
        }],
        fallback: "style-loader"
      })
    }, {
      test: /\.(ttf|otf|eot|svg|woff(2)?)(\?[a-z0-9]+)?$/,
      // put fonts in assets/static/fonts/
      loader: 'file-loader?name=/fonts/[name].[ext]'
    }]
  },
  plugins: [
    new ExtractTextPlugin({
      filename: "css/[name].css"
    }),
    new CopyWebpackPlugin([{ from: "./static" }])
  ]
};
module.exports = config;
```

## Final polishing and tests
The final step is to update the main template file `app.html.eex` to use the generated files (that you can find in the `priv/static` folder once compiled):

```html
[..]
<link rel="stylesheet" href="<%= static_path(@conn, "/css/main.css") %>">
[..]
<script src="<%= static_path(@conn, "/js/app.js") %>"></script>
```

The whole pipeline is now ready, except we must tell Phoenix to run Webpack when the server is launched.
At the moment you can already test the pipeline running, from the `assets/` folder, the command: `yarn run compile`

To configure Phoenix, update the `config/dev.exs` file replacing Brunch command with Webpack:

```javascript
watchers: [
  node: [
    "node_modules/webpack/bin/webpack.js", "--watch-stdin", "--progress", "--color",
    cd: Path.expand("../assets", __DIR__)
  ]
]
```

That’s it.
Run `mix phx.server` and you’ll have both the Phoenix server running and the assets pipeline compiled and watching for file updates.

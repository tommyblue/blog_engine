+++
author = "Tommaso Visconti"
categories = ["jekyll", "sito", "informatica", "sinatra", "heroku", "how-to", "ruby"]
date = 2012-08-28T10:49:43Z
description = ""
draft = false
slug = "create-a-contact-form-for-jekyll"
tags = ["jekyll", "sito", "informatica", "sinatra", "heroku", "how-to", "ruby"]
title = "Create a contact form for Jekyll"

+++



As I promised to a reader who wrote me an email some days ago, with this post I'll explain how I built the contact form of this website using Sinatra and Sendgrid. As you know (or you're just learning) this site is made by [Jekyll](https://github.com/mojombo/jekyll), a static site generator written in Ruby. As the result of the work of Jekyll it is a static HTML website, so it's not immediate to build a contact form. I tried to find a JS solution to maintain a full static website, but didn't find any. So I wrote a few Ruby lines and the contact form is now working.

How to let the form work is strictly dependent on how you deploy your Jekyll website. I use [Heroku](http://www.heroku.com/) so I deploy the site as a [Rack-based app](https://devcenter.heroku.com/articles/rack) using [Sinatra](http://www.sinatrarb.com/), this how-to works only if you have my deployment configuration. If not, you must adapt it to your needs.

The first step is to register a free account to [reCAPTCHA](http://www.google.com/recaptcha) and get the public and private API keys. Then register a [Sendgrid free account as Heroku add-on](https://devcenter.heroku.com/articles/sendgrid) in your website app.

To use a rack-based app on Heroku you need a *config.ru* file, this is mine:

```ruby

require 'rubygems'
require 'sinatra'
require 'rack/recaptcha'

use Rack::Recaptcha, :public_key => 'MyPublicKey', :private_key => 'TheS3cr3tS3cr3tKey'
helpers Rack::Recaptcha::Helpers
enable :sessions

require './application'
run Sinatra::Application

```


Just insert the reCAPTCHA keys and the file is ready. Now the *application.rb* file called by the *require* above:

```ruby

set :public, Proc.new { File.join(root, "_site") }

post '/send' do
  if recaptcha_valid?
    session[:captcha] = true
    { :message => 'success' }.to_json
  else
    session[:captcha] = false
    { :message => 'failure' }.to_json
  end
end

post '/send_email' do
    require 'pony'
    require 'json'

    if session[:captcha]
      session[:captcha] = false
      res = Pony.mail(
	:from => params[:name] + "<" + params[:email] + ">",
	:to => 'me@mydomain.com',
	:subject => "Message from your awesome website :)",
	:body => params[:message],
	:port => '587',
	:via => :smtp,
	:via_options => {
	  :address              => 'smtp.sendgrid.net',
	  :port                 => '587',
	  :enable_starttls_auto => true,
	  :user_name            => ENV['SENDGRID_USERNAME'],
	  :password             => ENV['SENDGRID_PASSWORD'],
	  :authentication       => :plain,
	  :domain               => 'heroku.com'
	})
      content_type :json
      if res
	  { :message => 'success' }.to_json
      else
	  { :message => 'failure' }.to_json
      end
    else
      { :message => 'failure' }.to_json
    end
end

before do
    response.headers['Cache-Control'] = 'public, max-age=36000'
end

not_found do
    File.read('_site/404.html')
end

get '/*' do
    file_name = "_site#{request.path_info}/index.html".gsub(%r{\/+},'/')
    if File.exists?(file_name)
	File.read(file_name)
    else
	raise Sinatra::NotFound
    end
end

```


As you see in the code I use two methods, *send* and *send_email*: the first check the captcha and set a session variable, returning a JSON message (*success*). The second method sends the email using Pony only if the captcha was verified.
The SendGrid username and password are loaded automatically from your Heroku environment.

The last step is to create the contact form page, including the reCAPTCHA js:

```html

<script type="text/javascript" src="http://www.google.com/recaptcha/api/js/recaptcha_ajax.js"></script>

<script type="text/javascript">
  function showRecaptcha(element) {
     Recaptcha.create("MyPublicKey", element, {
       theme: "red",
       callback: Recaptcha.focus_response_field});
   }
   $(document).ready(function(){
	showRecaptcha('recaptcha_div');

	$("#form").submit(function(ev){
	    ev.preventDefault();
	    if (!$(this).valid()) return;
	    $.ajax({
	      type: "post",
	      url: "/send",
	      data: $('#form').serialize(),
	      dataType: "json",
	      success: function(response) {
		if(response.message === "success") {
		  $.ajax({
		      type: "post",
		      url: "/send_email",
		      data: $('#form').serialize(),
		      dataType: "json",
		      success: function(response) {
			  $('#form').html("<div id='message'></div>");
			  if(response.message === "success") {
			      $('#message').html("<h2>Message successfully sent.</h2>").hide().fadeIn(1500);
			  } else {
			      $('#message').html("<h2>Error sending the message</h2>").hide().fadeIn(1500);
			  }
		      },
		      error: function(xhr, ajaxOptions, thrownError){
			  $('#form').html("<div id='message'></div>");
			  $('#message').html("<h2>Error sending the message</h2>").hide().fadeIn(1500);
		      }
		  });
		} else {
		  showRecaptcha('recaptcha_div');
		  $('#notice').html("Captcha failed!").hide().fadeIn(1500);
		}
	      },
	      error: function(xhr, ajaxOptions, thrownError){
		  $('#form').html("<div id='message'></div>");
		  $('#message').html("<h2>Error sending the message</h2>").hide().fadeIn(1500);
	      }
	    });
	});
    });
</script>

```


**The code seems a bit tricky :)** but it's simple. It just intercepts the form submission, send a first POST call to */send* and, if the captcha is verified, generates a second POST call to */send_email*, which sends the email.
The last piece is the form HTML code:

```html

<form id="form" method="post">
	<label for="name">Name</label>
	<input type="text" name="name" id="name" />

	<label for="email">Email</label>
	<input type="text" name="email" id="email" />

	<label for="message" class="label">Message</label>
	<textarea name="message" id="message"></textarea>

	<div id="recaptcha_div"></div>
	<div id="notice"></div>

	<input class="submit" type="submit" value="Send" />
</form>

```


That's it, now you can send email from a *static* website.

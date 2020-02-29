+++
author = "Tommaso Visconti"
categories = ["informatica", "ruby", "paypal", "rails", "how-to"]
date = 2013-07-02T20:12:19Z
description = ""
draft = false
slug = "paypal-express-checkout-with-ruby-on-rails-and-paypal-sdk-merchant"
tags = ["informatica", "ruby", "paypal", "rails", "how-to"]
title = "Paypal Express Checkout with Ruby on Rails and paypal-sdk-merchant"

+++

In my last work, [Agrimè.it](http://www.agrime.it), an ecommerce built using Ruby on rails, I had to implement the cart payment using Paypal Express Checkout.

Sadly, I found that was the worst time to do it, because Paypal was migrating the [classic API](https://developer.paypal.com/webapps/developer/docs/classic/lifecycle/apps101/) to the [new REST API](https://developer.paypal.com/webapps/developer/docs/api/) and the documentation was a real mess! Walking through the doc links, I jumped (without a particular logic) from the new to the old API reference and vice versa.

After a long work, me and [Alessandro](http://scia.mp) were able to create a working Ruby class to implement Express Checkout using the classi API and the [paypal-sdk-merchant gem](https://github.com/paypal/merchant-sdk-ruby).

If you want to try the new REST API check this link [http://paypal.github.io/](http://paypal.github.io/) and use the [paypal-sdk-rest gem](https://github.com/paypal/rest-api-sdk-ruby). If you succeed in using it, please let me know or write something about it.

**For non-US developers**: before using the new REST API check if they work in your country. Only after a few days of work we found a little and tiny box which said the new API only work in US at that moment and they will be able worldwide in the late 2013!

# Configure paypal-sdk-merchant

To use the **paypal-sdk-merchant** gem in a Rails app just add:

```sh
gem 'paypal-sdk-merchant'
```

in the *Gemfile*, then install with _bundle install_.
You can generate the _config/paypal.yml_ config file with

```sh
rails g paypal:sdk:install
```

You can find an example in [https://github.com/paypal/merchant-sdk-ruby](https://github.com/paypal/merchant-sdk-ruby) . To obtain the configuration values you must register the app both in the [Paypal sandbox](https://developer.paypal.com/webapps/developer/applications/myapps) (for development use) and in [Paypal Apps](https://apps.paypal.com/).

To integrate the gem with Rails, create a file _config/initializers/paypal.rb_ with the content:

```ruby
PayPal::SDK.load("config/paypal.yml", Rails.env)
PayPal::SDK.logger = Rails.logger
```

Now the Rails app is ready to go. But... where?? :)

# Express checkout, how it works?

Paypal has a lot of different workflows. Before start hacking, I want to explain how the express checkout works.

It's essentialy constituted by 3 steps:

1. **Set express checkout:** makes a call to the API sending the details of the payment to obtain a token and generate a payment url
2. **Get express checkout:** redirects the user to the payment url and obtains the authorization
3. **Do express checkout:** uses the given authorization to make the real payment

Remember the third step. Without it you just ask for a payment authorization without ever getting it!
To clearify these steps you can play with the sample app at [https://paypal-sdk-samples.herokuapp.com/merchant/set_express_checkout](https://paypal-sdk-samples.herokuapp.com/merchant/set_express_checkout)

# Code implementation

## The paypal library file

I put the Paypal logic in the _lib/modules/paypal\_interface.rb_ file. Its basic structure is:

```ruby
require 'paypal-sdk-merchant'

class PaypalInterface
  attr_reader :api, :express_checkout_response

  PAYPAL_RETURN_URL = Rails.application.routes.url_helpers.paid_orders_url(host: HOST_WO_HTTP)
  PAYPAL_CANCEL_URL = Rails.application.routes.url_helpers.revoked_orders_url(host: HOST_WO_HTTP)
  PAYPAL_NOTIFY_URL = Rails.application.routes.url_helpers.ipn_orders_url(host: HOST_WO_HTTP)

  def initialize(order)
    @api = PayPal::SDK::Merchant::API.new
    @order = order
  end
end
```

The **@order** variable is an instance of the Order model, which referers to the order going to be paid. I'll use this model later to save the data needed to manage the payment.

## Required routes

As you can see in the code below, the library needs three routes. This is the pertinent code from _config/routes.rb_:

```ruby
resources :orders do
  collection do
    get :paid
    get :revoked
    post :ipn
  end
end
```

I defined the _HOST\_WO\_HTTP_ variable in a custom initializer because it differs depending on the environment, here it is:

```ruby
if Rails.env.production?
  HOST_WO_HTTP = 'www.agrime.it'
else
  HOST_WO_HTTP = 'localhost:3000'
end
HOST = "http://#{HOST_WO_HTTP}"
```

I'm sure a better (and more railsy) way exists, but I didn't find it. Any suggestion is welcome! :)

## Get express checkout

Now it's time do make the first step and request the url for the payment. Imagine we have an unpaid order and in its show action, we want to add a _"Pay with Paypal"_ button.

This is the controller action:

```ruby
def show
  @order = Order.find(params[:id])
  @paypal = PaypalInterface.new(@order)
  @paypal.express_checkout
  if @paypal.express_checkout_response.success?
    @paypal_url = @paypal.api.express_checkout_url(@paypal.express_checkout_response)
  else
    # manage error
  end
end
```

The main method used here is _express\_checkout_, defined in the _PaypalInterface_ class:

```ruby
class PaypalInterface
  [..]
  def express_checkout
    @set_express_checkout = @api.build_set_express_checkout({
      SetExpressCheckoutRequestDetails: {
        ReturnURL: PAYPAL_RETURN_URL,
        CancelURL: PAYPAL_CANCEL_URL,
        PaymentDetails: [{
          NotifyURL: PAYPAL_NOTIFY_URL,
          OrderTotal: {
            currencyID: "EUR",
            value: @order.total
          },
          ItemTotal: {
            currencyID: "EUR",
            value: @order.total
          },
          ShippingTotal: {
            currencyID: "EUR",
            value: "0"
          },
          TaxTotal: {
            currencyID: "EUR",
            value: "0"
          },
          PaymentDetailsItem: [{
            Name: @order.code,
            Quantity: 1,
            Amount: {
              currencyID: "EUR",
              value: @order.total
            },
            ItemCategory: "Physical"
          }],
          PaymentAction: "Sale"
        }]
      }
    })

    # Make API call & get response
    @express_checkout_response = @api.set_express_checkout(@set_express_checkout)

    # Access Response
    if @express_checkout_response.success?
      @order.set_payment_token(@express_checkout_response.Token)
    else
      @express_checkout_response.Errors
    end
  end
end
```

The _Order.set\_payment\_token_ method just saves the token in the order model. It will be used after the payment, to link the payment with the correct order.

At the end of the API call you can use the _@paypal\_url_ variable to build the "Pay with Paypal" button. This is the view:

```txt
<%= link_to @paypal_url do %>
  <img src="https://www.paypalobjects.com/it_IT/IT/Marketing/i/bnr/bnr_horizontal_solutiongraphic_335x80.gif" style="margin-right:7px;" />
<% end %>
```


Clicking in the button the user will be redirected to Paypal, where he can pay using it's account or a credit card.

## Get express checkout

If the user accepts the payment, Paypal redirects to the _PAYPAL\_RETURN\_URL_ passing two arguments: the **token** and the **PayerID**. The _OrdersController.paid_ method is simple:

```ruby

class OrdersController < ApplicationController
  [..]
  def paid
    if order = Order.pay(params[:token], params[:PayerID])
      # success message
    else
      # error message
    end
    redirect_to orders_path
  end
end

```


The following is the _Order.pay_ method:

```ruby

class Order < ActiveRecord::Base
  [..]
  def self.pay(token, payerID)
    begin
      order = self.find_by_payment_token(token)
      order.payerID = payerID
      order.save
      PaypalWorker.perform_async(order.id)
      return order
    rescue
      false
    end
  end
end

```


The code finds the correct order using the token and saves the PayerID. Now the payment is just authorized. To obtain the real payment we must proceed with the third step. I use a [Sidekiq](http://sidekiq.org/) worker to perform this action asynchronously while the user is immediatly redirected to the orders page.

Before proceeding to the last step let's check the revoke action. Paypal redirects to the _PAYPAL\_CANCEL\_URL_ if the user doesn't authorize the payment and clicks in the "Cancel" button.

```ruby

class OrdersController < ApplicationController
  [..]
  def revoked
    if order = Order.cancel_payment(params)
      # set a message for the user
    end
    redirect_to orders_path
  end
end

```


The _params\[:token\]_ param let you find the canceled order. I do nothing particular with the other params, just save it for logging.

## Do express checkout

Now that the payment is authorized we must obtain the real payment. As mentioned before I use an asyncronous job to make it, just to speed up the user experience. The worker code is really simple:

```ruby

class PaypalWorker
  include Sidekiq::Worker

  def perform(order_id)
    @order = Order.find(order_id)

    @paypal = PaypalInterface.new(@order)
    @paypal.do_express_checkout
  end
end

```


Let's jump to the _PaypalInterface.do\_express\_checkout_ method:

```ruby

class PaypalInterface
  [..]
  def do_express_checkout
    @do_express_checkout_payment = @api.build_do_express_checkout_payment({
      DoExpressCheckoutPaymentRequestDetails: {
        PaymentAction: "Sale",
        Token: @order.payment_token,
        PayerID: @order.payerID,
        PaymentDetails: [{
          OrderTotal: {
            currencyID: "EUR",
            value: @order.total
          },
          NotifyURL: PAYPAL_NOTIFY_URL
        }]
      }
    })

    # Make API call & get response
    @do_express_checkout_payment_response = @api.do_express_checkout_payment(@do_express_checkout_payment)

    # Access Response
    if @do_express_checkout_payment_response.success?
      details = @do_express_checkout_payment_response.DoExpressCheckoutPaymentResponseDetails
      @order.set_payment_details(prepare_express_checkout_response(details))
    else
      errors = @do_express_checkout_payment_response.Errors # => Array
      @order.save_payment_errors errors
    end
  end
end

```


Essentially the method sends to paypal the token, the PayerID and the order details. If the values are correct, Paypal will make the real payment and will return a successful response. In addition it will make a POST call to the IPN url (we'll see this below).

If something goes wrong we'll get an error array like this:

```ruby

[{
  :ShortMessage => "This Express Checkout session has expired.",
  :LongMessage => "This Express Checkout session has expired.  Token value is no longer valid.",
  :ErrorCode => "10411",
  :SeverityCode => "Error"
}]

```


Error codes and details are documented here: [https://developer.paypal.com/webapps/developer/docs/classic/api/errorcodes/](https://developer.paypal.com/webapps/developer/docs/classic/api/errorcodes/)

If the payments is correct, the method calls _Order.save\_payment\_details_, saving the payment details (I use a _Payment_ model with an _has\_one_ association with _Order_).

## IPN

After the express checkout, Paypal send a POST call to the IPN url:

```ruby

class OrdersController < ApplicationController
  [..]
  def ipn
    if payment = Payment.find_by_transaction_id(params[:txn_id])
      payment.receive_ipn(params)
    else
      Payment.create_by_ipn(params)
    end
  end
end

```


The action tries to find the payment using the transaction ID and sends to it the params. If it doesn't find it (and this is strange!) it creates a Payment saving the params (about payments, I prefer to log everything!).
The IPN params are really a lot (check them [here](https://developer.paypal.com/webapps/developer/docs/classic/ipn/integration-guide/IPNandPDTVariables/)), I saves only a few of them in dedicated columns, then I put a raw copy of the params (using _params.to\_s_ ) in a text field for debugging porpouses.

# Conclusion

I showed the basic code to implement **Paypal Express Checkout** using the  _paypal-sdk-merchant_ gem. The Paypal API is complex but the gem is quite simple to use, I hope the code is easy to understand.
If you want to use it in a real app, I suggest to add some methods to manage the order status (new, paid, etc.) and to notify the user of what's happening in the background.

Take a look at the webography below. When I started this project a few months ago, due to the migration to the new Paypal Developers Platform, all the documentation was quite unreadable. I reread some docs now while writing this post and I must admit the Paypal guys made a big step forward, probably your experience will be easier than mine :)

Thanks to [Alessandro](http://scia.mp) for his great help and good code for this project! :)

# Webography

Some of the links used to write the code and this post:

**CLASSIC API**

- [https://github.com/paypal/merchant-sdk-ruby](https://github.com/paypal/merchant-sdk-ruby)
- [https://developer.paypal.com/webapps/developer/docs/api/](https://developer.paypal.com/webapps/developer/docs/api/)
- [https://developer.paypal.com/webapps/developer/docs/classic/lifecycle/apps101/](https://developer.paypal.com/webapps/developer/docs/classic/lifecycle/apps101/)
- [https://developer.paypal.com/webapps/developer/docs/classic/ipn/integration-guide/IPNandPDTVariables/](https://developer.paypal.com/webapps/developer/docs/classic/ipn/integration-guide/IPNandPDTVariables/)
- [http://www.paypalobjects.com/en_US/ebook/PP_ExpressCheckout_IntegrationGuide/HowExpressCheckoutWorks.html](http://www.paypalobjects.com/en_US/ebook/PP_ExpressCheckout_IntegrationGuide/HowExpressCheckoutWorks.html)
- [https://developer.paypal.com/webapps/developer/docs/classic/api/errorcodes/](https://developer.paypal.com/webapps/developer/docs/classic/api/errorcodes/)

**REST API**

- [http://paypal.github.io/](http://paypal.github.io/)
- [https://github.com/paypal/rest-api-sdk-ruby](https://github.com/paypal/rest-api-sdk-ruby)
- [https://developer.paypal.com/webapps/developer/docs/api/#payments](https://developer.paypal.com/webapps/developer/docs/api/#payments)

**CODE SAMPLES**

- [https://paypal-sdk-samples.herokuapp.com/merchant/set_express_checkout](https://paypal-sdk-samples.herokuapp.com/merchant/set_express_checkout)
- [https://developer.paypal.com/webapps/developer/docs/classic/lifecycle/code-samples/](https://developer.paypal.com/webapps/developer/docs/classic/lifecycle/code-samples/)
- [https://github.com/paypal/codesamples-ruby](https://github.com/paypal/codesamples-ruby)

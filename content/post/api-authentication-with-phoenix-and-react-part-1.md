+++
author = "Tommaso Visconti"
categories = ["elixir", "phoenix", "react"]
date = 2018-03-28T20:08:09Z
description = ""
draft = false
image = "/images/2018/03/1_-MTuYZ4k46A8JJdWlq_x5A.png"
slug = "api-authentication-with-phoenix-and-react-part-1"
tags = ["elixir", "phoenix", "react"]
title = "API Authentication with Phoenix and React - part 1"

+++

**Scenario:** you just wrote a cool web app using React for the frontend part and Phoenix as the API server.
Then you realize everybody can poke around your stuff and you decide **it’s time to restrict the access to known users**, how to do it?

I’ll configure a [Phoenix](http://phoenixframework.org/) server to manage [access tokens](https://tools.ietf.org/html/rfc6750), used by a [React](https://reactjs.org/) app to make authenticated calls.

This blog post only deals with the backend part and consists of these steps:

* add users and give them the ability to sign in
* manage authentication tokens for the users
* define a pipeline to grant access to restricted routes only to authenticated requests

**I’m not going to cover the SSL configuration here, but it’s fundamental to only serve the endpoints over HTTPS. You can check out [this article](https://spin.atomicobject.com/2018/03/07/force-ssl-phoenix-framework/) which explains how to force SSL in Phoenix.**

## Create the Users

Let’s create the schemas for the User:

```bash
$ mix phx.gen.schema User users email:string:unique password_hash:string
```

The `mix` command doesn’t accept any option to avoid null values, so the migration files must be edited.
This is the final version of the migration file (only the relevant parts):

```elixir
create table(:users) do
  add :email, :string, null: false
  add :password_hash, :string, null: false
  timestamps()
end
create unique_index(:users, [:email])
```

We're going to save hashed password, not clear-text passwords, so our schema will have a virtual `password` field which, behind the scenes, will be hashed and saved.

To crypt passwords we’re going to use the [Comeonin](https://github.com/riverrun/comeonin/) lib, that must be added to the dependencies, together with BCrypt (don’t forget to run `mix deps.get` after you made the changes):

```elixir
# mix.exs
defp deps do
  [...]
  {:comeonin, "~> 4.0"},
  {:bcrypt_elixir, "~> 1.0"}
end
```

Let’s now see the `User` module:

```elixir
defmodule MyApp.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias MyApp.User

  schema "users" do
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    timestamps()
  end

  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> unique_constraint(:email, downcase: true)
    |> put_password_hash()
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(
            changeset,
            :password_hash,
            Comeonin.Bcrypt.hashpwsalt(pass)
        )
      _ ->
        changeset
    end
  end
end
```

At this point we can create new users:

```elixir
$ iex -S mix
iex(1)> MyApp.repo.insert!(MyApp.User.changeset(
  %MyApp.User{}, %{
    email: “my_email@provider.com”,
    password: “s3cr3t”
  }
))
[..]
%MyApp.User{
  __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
  email: "my_email@provider.com",
  id: 1,
  inserted_at: ~N[2018-03-24 22:47:37.981969],
  password: "s3cr3t",
  password_hash: "<cut>",
  updated_at: ~N[2018-03-24 22:47:37.984213]
}
```

## User tokens

Ok, now that we have users, we must generate tokens for them, so that they can access restricted routes.

The first step is to create the schema:

```bash
$ mix phx.gen.schema AuthToken auth_tokens user_id:references:users token:text:unique revoked:boolean revoked_at:utc_datetime
```

As before, we must edit the migration to add missing `null: false`:

```elixir
create table(:auth_tokens) do
  add :user_id, references(:users, on_delete: :nothing), null: false
  add :token, :text, null: false
  add :revoked, :boolean, default: false, null: false
  add :revoked_at, :utc_datetime
  timestamps()
end
create unique_index(:auth_tokens, [:token])
create index(:auth_tokens, [:user_id])
```

The schema is the following:

```elixir
defmodule MyApp.AuthToken do
  use Ecto.Schema
  import Ecto.Changeset
  alias MyApp.AuthToken
  alias MyApp.User

  schema "auth_tokens" do
    belongs_to :user, User
    field :revoked, :boolean, default: false
    field :revoked_at, :utc_datetime
    field :token, :string
    timestamps()
  end

  def changeset(%AuthToken{} = auth_token, attrs) do
    auth_token
    |> cast(attrs, [:token])
    |> validate_required([:token])
    |> unique_constraint(:token)
  end
end
```

We’ve added the `belongs_to` relationship there, we must also edit the `User` schema adding:

```elixir
schema "users" do
  has_many :auth_tokens, MyApp.AuthToken
  [...]
end
```

We’re going to need a bunch of methods to deal with authorization headers and tokens, so a service could be useful.
Let’s create an `Authenticator` service with the first methods we’ll use to generate and verify tokens with [Phoenix.Token](https://hexdocs.pm/phoenix/Phoenix.Token.html):

```elixir
defmodule MyApp.Services.Authenticator do
  # These values must be moved in a configuration file
  @seed "user token"
  # good way to generate:
  # :crypto.strong_rand_bytes(30)
  # |> Base.url_encode64
  # |> binary_part(0, 30)
  @secret "CHANGE_ME_k7kTxvFAgeBvAVA0OR1vkPbTi8mZ5m"

  def generate_token(id) do
    Phoenix.Token.sign(@secret, @seed, id, max_age: 86400)
  end

  def verify_token(token) do
    case Phoenix.Token.verify(@secret, @seed, token, max_age: 86400) do
      {:ok, id} -> {:ok, token}
      error -> error
    end
  end
end
```

## Sign in and out the users

We now need to let the users sign in (create a token for the user) and sign out (delete the token).

We’ll manage the logic inside the User module:

```elixir
defmodule MyApp.User do
  [...]
  alias MyApp.Services.Authenticator

  def sign_in(email, password) do
    case Comeonin.Bcrypt.check_pass(Repo.get_by(User, email: email), password) do
      {:ok, user} ->
        token = Authenticator.generate_token(user)
        Repo.insert(Ecto.build_assoc(user, :auth_tokens, %{token: token}))
      err -> err
    end
  end

  def sign_out(conn) do
    case Authenticator.get_auth_token(conn) do
      {:ok, token} ->
        case Repo.get_by(AuthToken, %{token: token}) do
          nil -> {:error, :not_found}
          auth_token -> Repo.delete(auth_token)
        end
      error -> error
    end
  end
end
```

The first line of the `sign_in` function looks for the user in the `Repo` then passes it to `Bcrypt.check_pass` together with the provided password, to verify it.

In the case the user can’t be found, `check_pass` receives a wrong user and returns `{:error, "invalid user-identifier"}` while in the case the password verification fails it returns `{:error, "invalid password"}`.
So, in both cases, we return a `{:error, reason}` tuple (we’ll later use this in the controller).

If the user is found and the password is valid, we create a token for the user and return it.

The `sign_out` function looks for the token in the header and deletes it if found.

The function that extracts the token is based on a simple regexp:

```elixir
defmodule MyApp.Services.Authenticator do
  [...]
  def get_auth_token(conn) do
    case extract_token(conn) do
      {:ok, token} -> verify_token(token)
      error -> error
    end
  end

  defp extract_token(conn) do
    case Plug.Conn.get_req_header(conn, "authorization") do
      [auth_header] -> get_token_from_header(auth_header)
       _ -> {:error, :missing_auth_header}
    end
  end

  defp get_token_from_header(auth_header) do
    {:ok, reg} = Regex.compile("Bearer\:?\s+(.*)$", "i")
    case Regex.run(reg, auth_header) do
      [_, match] -> {:ok, String.trim(match)}
      _ -> {:error, "token not found"}
    end
  end
end
```

At this point all the underground pieces are in place, but we need to create the endpoints to let the user make the actions.

First, add the required routes:

```elixir
scope "/sessions" do
  post "/sign_in", SessionsController, :create
  delete "/sign_out", SessionsController, :delete
end
```

We can check the result with `mix phx.routes`:
```ini
sessions_path  POST    /sessions/sign_in    MyApp.SessionsController :create
sessions_path  DELETE  /sessions/sign_out    MyApp.SessionsController :delete
```

We must then create the `SessionsController`:

```elixir
defmodule MyAppWeb.SessionsController do
  use MyAppWeb, :controller
  alias MyApp.User

  def create(conn, %{"email" => email, "password" => password}) do
    case User.sign_in(email, password) do
      {:ok, auth_token} ->
        conn
        |> put_status(:ok)
        |> render("show.json", auth_token)
      {:error, reason} ->
        conn
        |> send_resp(401, reason)
    end
  end

  def delete(conn, _) do
    case User.sign_out(conn) do
      {:error, reason} -> conn |> send_resp(400, reason)
      {:ok, _} -> conn |> send_resp(204, "")
    end
  end
end
```

and its view:

```elixir
defmodule MyAppWeb.SessionsView do
  use MyAppWeb, :view
  def render("show.json", auth_token) do
    %{data: %{token: auth_token.token}}
  end
end
```

Done, it’s now time to make some tests calling these endpoints. I personally use [Advanced Rest Client](https://install.advancedrestclient.com/#/install) (aka ARC), a Chrome extension to make HTTP calls.

To test sign in, we must make a `POST` call to `http://localhost:4000/sessions/sign_in` with the following JSON body:

```json
{
  "email":"my_email@provider.com",
  "password": "s3cr3t"
}
```

If we didn’t make any error we’ll get back the token in a json structure as we defined in `show.json`:

```json
{
  "data": {
    "token": "SFMyNTY.g3QAAAAC[...cut...]"
  }
}
```

Now make a `DELETE` call against `http://localhost:4000/sessions/sign_out`, adding an authorization header in the form: `Authorization: Bearer SFMyNTY.g3QAAAAC[…cut…]`. You should receive a 204 response.

Take a look at the database for further feedback. A new token for the user must be created at sign in and it must be deleted at sign out.

## Require the token to access restricted routes

We’re almost there: users are able to sign in and receive an authentication token, we should now restrict the access to private routes requiring an authorization token.

The key is a basic component of Phoenix: the [Plug](https://hexdocs.pm/phoenix/plug.html).

To apply one or more plugs to routes, we need to create a pipeline and pipe the routes through it:

```elixir
defmodule MyAppWeb.Router do
  pipeline :authenticate do
    plug MyAppWeb.Plugs.Authenticate
  end
  scope "/restricted", Restricted do
    pipe_through :authenticate
    resources "/private"
    # more routes
  end
  [...]
end
```

The Authenticate plug will look for the authorization token in the request headers and will validate it. Only requests with valid tokens will go through. Invalid requests will get a 401 response.

This is the plug file:

```elixir
defmodule MyAppWeb.Plugs.Authenticate do
  import Plug.Conn
  def init(default), do: default

  def call(conn, _default) do
    case MyApp.Services.Authenticator.get_auth_token(conn) do
      {:ok, token} ->
        case MyApp.Repo.get_by(MyApp.AuthToken, %{token: token, revoked: false})
        |> Repo.preload(:user) do
          nil -> unauthorized(conn)
          auth_token -> authorized(conn, auth_token.user)
        end
      _ -> unauthorized(conn)
    end
  end

  defp authorized(conn, user) do
    # If you want, add new values to `conn`
    assign(conn, :signed_in, true)
    assign(conn, :signed_user, user)
    conn
  end

  defp unauthorized(conn) do
    conn |> send_resp(401, "Unauthorized") |> halt()
  end
end
```

## Revoke a compromised token

In the case a token is somehow “compromised”, the user can revoke it.

We need a new restricted route which updates the compromised token setting the `revoked=true` and `revoked_at=<current timestamp>`.

I’m going to leave this as an exercise for the readers.

## Consume the APIs with React

In the [next part of this guide](https://www.tommyblue.it/2018/03/31/api-authentication-with-phoenix-and-react-part-2/), I’ll show how to use what done here in a frontend app built using React. [Read it here](https://www.tommyblue.it/2018/03/31/api-authentication-with-phoenix-and-react-part-2/).

## Note: JWT and why I didn’t use it

In the first iteration of the code I decided to use [Guardian](https://github.com/ueberauth/guardian) and [JWT](https://jwt.io/) (JSON Web Tokens) but then I realized I couldn’t revoke tokens without store them in the db and actually make a query at each API call (and avoiding a query was the main reason that lead me to use JWT), so I decided it was a over-engineered solution and moved to the integrated [Phoenix.Token](https://hexdocs.pm/phoenix/Phoenix.Token.html).

If you’re interested in the JWT revoke topic, check the [GuardianDB README](https://github.com/ueberauth/guardian_db/blob/master/README.md#disadvantages) which has a good explanation:

> In other words, once you have reached a point where you think you need Guardian.DB, it may be time to take a step back and reconsider your whole approach to authentication!

## References

* http://learningwithjb.com/posts/authenticating-users-using-a-token-with-phoenix
* https://dennisreimann.de/articles/phoenix-passwordless-authentication-magic-link.html
* http://whatdidilearn.info/2018/02/18/authentication-in-phoenix.html
* https://itnext.io/authenticating-absinthe-graphql-apis-in-phoenix-with-guardian-d647ea45a69a
* https://medium.freecodecamp.org/authentication-using-elixir-phoenix-f9c162b2c398

+++
author = "Tommaso Visconti"
categories = ["elixir", "react", "phoenix"]
date = 2018-03-31T19:34:35Z
description = ""
draft = false
image = "/images/2018/03/1_-MTuYZ4k46A8JJdWlq_x5A-1.png"
slug = "api-authentication-with-phoenix-and-react-part-2"
tags = ["elixir", "react", "phoenix"]
title = "API Authentication with Phoenix and React - part 2"

+++

[In the first part of this post](/2018/03/28/api-authentication-with-phoenix-and-react---part1/) I've shown how to configure the API server to let the user authenticate, return an authentication token, and request it to access protected routes.
Now I'm going to configure a [React](https://reactjs.org/) app to consume that API and manage authentication.

The app uses [React Router](https://reacttraining.com/react-router/) to manage routes and [Redux](https://redux.js.org/) for the state of the app.

## Protect private routes

I'm going to define a `PrivateRoute` component as a wrapper around `Route`. The component will check the user authentication.

The router configuration will have a standard `Route` component for the `Login` page and will use `PrivateRoute` for the rest of the routes:

```jsx
<Router>
    <Switch>
        <Route path='/login' component={Login} />
        <PrivateRoute path='/private' component={PrivateComponent}/>
    </Switch>
</Router>
```

The `PrivateRoute` component will check the `isAuthenticated` flag in the state and will redirect back to login if `false` or will render the private component otherwise:

```jsx
import React from 'react';
import { Route, Redirect } from 'react-router-dom';
import { connect } from 'react-redux';

const mapStateToProps = state => {
    return {
        isAuthenticated: state.isAuthenticated,
    };
};

class PrivateRoute extends React.Component {
    render() {
        if (!this.props.isAuthenticated) {
            return (
                <Redirect
                    to={{
                    pathname: "/login",
                    state: { from: this.props.location }
                    }}
                />
            );
        }

        return (
            <Route component={this.props.Component} {...this.props} />
        );
    }
}

export default connect(mapStateToProps)(PrivateRoute);
```

## Sign in and receive the token from the server

The `Login` component will simply show a form and will manage the initial authentication, saving the token in a cookie for later use:

```jsx
import React from 'react';
import { connect } from 'react-redux';

import {
    signIn,
} from '../actions';

const mapStateToProps = state => {
    return {
        isAuthenticated: state.isAuthenticated,
    };
};

const mapDispatchToProps = dispatch => {
    return {
        onSignIn: (email, password) => dispatch(signIn(email, password)),
    };
};

class Login extends React.Component {
    constructor(props) {
        super(props);
        this.onSignIn = this.onSignIn.bind(this);
        this.state = {email: "", password: ""};
    }

    render() {
        return (
            <div className="container">
                <h1 className="title">Login</h1>
                {this.props.isAuthenticated ? this.alreadyAuthenticated() : this.form()}
            </div>
        );
    }

    alreadyAuthenticated() {
        return ("You're already authenticated.")
    }

    form() {
        return (
            <form>
                <div className="field">
                    <label className="label">Email</label>
                    <div className="control">
                        <input
                            className="input"
                            type="email"
                            placeholder="Your email address"
                            value={this.state.email}
                            autoFocus={true}
                            onChange={(e) => this.setState({...this.state, email: e.target.value})}
                        />
                    </div>
                </div>

                <div className="field">
                    <label className="label">Password</label>
                    <div className="control">
                        <input
                            className="input"
                            type="password"
                            placeholder="Your password"
                            value={this.state.password}
                            onChange={(e) => this.setState({...this.state, password: e.target.value})}
                        />
                    </div>
                </div>

                <button
                    className="button is-primary"
                    onClick={this.onSignIn}
                >Sign in</button>
            </form>
        );
    }

    onSignIn() {
        this.props.onSignIn(this.state.email, this.state.password);
    }
}

export default connect(
    mapStateToProps,
    mapDispatchToProps
)(Login);
```

The `signIn` action is where the "magic" happens:

```jsx
export const signIn = (email, password) => ((dispatch) => {
    return fetch(`http://<server_url>/api/sessions/sign_in}`, {
        method: "POST",
        headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({email, password}),
      }).then(
        response => {
            if (!response.ok) {
                // Manage error
                return dispatch(errorOnFetch(response.statusText));
            }
            return response.json().then(response => dispatch(signInSuccessfull(response.data)));
        },
        error => {
            return dispatch(errorOnFetch(error))
        }
    );
});

const signInSuccessfull = (data) => {
    setAuthToken(data.token);
    return {
        type: AUTHENTICATION_SUCCEDED,
    }
};
```

Two main things happen in the `signInSuccessfull` method: the token returned by the server is passed to the `setAuthToken` method and the `AUTHENTICATION_SUCCEEDED` action is returned to the redux reducer.

The reducer sets the `isAuthenticated` flag to `true` (do you remember the check in the `PrivateRoute` component?):
```jsx
const mainReducer = (state = initialState, action) => {
    switch (action.type) {
        case AUTHENTICATION_SUCCEDED:
            return ({...state,
                isAuthenticated: true,
            });
        case AUTHENTICATION_SIGNOUT:
            return ({...state,
                isAuthenticated: false,
            });
    }
}
```

The `setAuthToken` method saves the token in a cookie, so that it will be then available for the next requests:

```jsx
const setAuthToken = (token) => {
    const cookies = new Cookies();
    cookies.set('my_auth_token', token, {
        path: '/'
    });
};
```

I'm using the [universal-cookie](https://github.com/reactivestack/cookies/tree/master/packages/universal-cookie) package here, so we need to install it:

```bash
yarn add universal-cookie
```

Other useful methods will permit to get the cookie or delete it:

```jsx
export const getAuthToken = () => {
    const cookies = new Cookies();
    return cookies.get('my_auth_token');
};

const removeAuthToken = () => {
    const cookies = new Cookies();
    cookies.remove('my_auth_token', {
        path: '/',
    });
};
```

## Use the token for private routes

At this point we have a valid token saved in a cookie. We just need to use it when making a request for a private API endpoint.

I'll use a wrapper function around `fetch` to add the Authorization header to the requests:

```jsx
const authFetch = (url, options) => (
    fetch(url, mergeAuthHeaders(options)).then(
        response => {
            // Sign out if we receive a 401!
            if (response.status === 401) {
                store.dispatch(signOut());
                throw new Error("Unauthorized");
            }
            return response;
        },
        error => error
    )
);

const mergeAuthHeaders = (baseOptions) => {
    const options = _.isUndefined(baseOptions) ? {} : baseOptions;
    if (!_.has(options, 'headers')) {
        options.headers = {};
    }
    options.headers = {
        ...options.headers,
        'Authorization': `Bearer ${getAuthToken()}`,
    };
    return options;
}
```

The `authFetch` method receives a URL to fetch and the options for the `fetch` method. It merges the authentication header in the options and makes the request.
If it receives a 401 response, then it makes the sign out, deleting the cookie and setting the `isAuthenticated` flag to `false`:

```jsx
export const signOut = () => {
    removeAuthToken();
    return {
        type: AUTHENTICATION_SIGNOUT,
    }
};
```

That's it, you should probably add more logic to manage side cases and errors, but this is enough to consume the APIs we built.

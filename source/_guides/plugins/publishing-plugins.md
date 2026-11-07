---
title: Publishing Plugins
description: |
  How to publish a plugin to the appstore with `pebble publish`, and how to let
  it sign users in to a service with OAuth.
guide_group: plugins
generate_toc: true
---

## Publish a plugin

Run `pebble publish` in the plugin's project, the same way as for an app (see
{% guide_link appstore-publishing/publishing-an-app %}):

```nc|text
$ pebble login
$ pebble publish
```

The first time, the command creates the plugin's listing: it asks for a name,
a description and a plugin category. Plugins have no screenshots. Pass
`--icon-small` and `--icon-large`, or let the appstore generate a line icon from
the description. Later runs upload a new release to the same listing.

### From the Developer Dashboard

Plugins can also be submitted from the web, the same way as apps (see
{% guide_link appstore-publishing/publishing-an-app %}):

* Open the [Developer Dashboard]({{ site.links.devportal }}) and click
  *New Plugin*.

* Upload the plugin's `.pbw`. It must have a `plugin` block and no watch
  binary. The dashboard shows the plugin's category, read from its manifest,
  and the permissions and OAuth connectors it declares.

* Enter the *App Name* and *Description*, and upload the *Small Icon* and
  *Large Icon* or leave them empty to have a line icon generated.

* Click *Submit App*. A plugin that declares OAuth connectors goes on to connector
  setup (see [Sign users in with OAuth](#sign-users-in-with-oauth)).

To release a new version, open the plugin in the dashboard and click
*New Release*.

## Sign users in with OAuth

A plugin that calls an API on the user's behalf can sign them in to it without
shipping your client secret in the `.pbw`. The appstore keeps the secret and
runs the token exchange; the plugin only receives the user's tokens.

1. Declare a connector in `package.json`, under `pebble.plugin`, with a slug of
   your choice:

    ```json
    "oauth": { "my-service": {} }
    ```

2. Register an OAuth app with the service and set its redirect URI to:

    ```nc|text
    https://appstore-api.repebble.com/api/oauth/broker/callback
    ```

3. Give the appstore the service's settings. `pebble publish` offers to do this
   after uploading; to do it later, or to change them:

    ```nc|text
    $ pebble oauth-connector set --slug my-service
    ```

    It asks for the authorization URL, token URL, scopes, client ID and client
    secret. The same settings are on the plugin's **OAuth connector** page in the
    [Developer Dashboard]({{ site.links.devportal }}).

4. In the plugin, start the sign-in and keep the tokens in secure storage:

    ```js
    var tokens = await Pebble.oauth.authorize('my-service');
    await Pebble.secureStorage.setItem('access_token', tokens.access_token);
    ```

    `tokens` has `access_token` and, when the service issues a refresh token,
    `broker_refresh`. When the access token expires, pass `broker_refresh` to
    `Pebble.oauth.refresh('my-service', brokerRefresh)` for a new one.

`authorize` also works on the emulator: it opens the service's sign-in page in
your browser, signed in as your `pebble login` account. The connector must be
set up first.

dtour-bot
---------

Based on the excellent [dlang-bot](https://github.com/MartinNowak/dlang-bot).

What does it do?
----------------

The Dlang bot is subscribed to all language repositiories and listens to their events.
For now it just restart the last build of master repository to trigger a new build.

Build & run
-----------

```
MASTER_REPO=stonemaster/dlang-tour GITHUB_TOKEN=xyz TRAVIS_TOKEN=abc dub
```

- the [Github Token](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) needs no scopes,
- see the [Travis Docs](https://blog.travis-ci.com/2013-01-28-token-token-token) on how to obtain a Token for Travis

Deployment
----------

It runs on Heroku, new commits to are automatically deployed.
See the [deploy on Heroku guide](http://tour.dlang.org/tour/en/vibed/deploy-on-heroku) if you want to deploy your own bot.

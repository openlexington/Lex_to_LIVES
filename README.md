# Lex to LIVES

A Ruby script that takes Lexington Health Department restaurant inspection
scores to the [LIVES standard](http://www.yelp.com/healthscores).

Assembled by OpenLexington for Code Across America 2013

## To convert health department food scores

`mv .env-sample .env`
Add your GitHub creds (or use a dummy GitHub account for automation)

* extracts scores from health department site
* transforms them to lives format
* loads to github repo

`bundle exec ruby lives_etl.rb`

## Deploy to Heroku

Install buildpack to enable rugged gem

```
$ heroku create my-etl-app
$ heroku buildpacks:set https://github.com/ddollar/heroku-buildpack-multi.git
$ heroku config:set GITHUB_USER=foo
$ heroku config:set GITHUB_PASS=bar
$ git push heroku master
$ heroku run bundle exec irb

irb(main):001:0> require 'rugged'
=> true
```

Warning: The buildpack succeeds on initial deploy and then fails on
later deploys. This fixes the issue:

```
heroku plugins:install https://github.com/heroku/heroku-repo.git
heroku repo:purge_cache -a my-etl-app
```

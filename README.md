# Lex to LIVES

A Ruby script that takes Lexington Health Department restaurant inspection
scores to the [LIVES standard](http://www.yelp.com/healthscores).

Assembled by OpenLexington for Code Across America 2013

It is deployed on Heroku (app name: `lives-etl`), which runs a scheduled job each day to look for new [health dept scores](http://lexingtonhealthdepartment.org/ProgramsServices/RestaurantInspections/FoodEstablishmentInspectionScores/tabid/235/Default.aspx).

**The health scores data generated by this script is stored in a [separate GitHub repo](https://github.com/openlexington/health-department-yelp-data)**

## To convert health department food scores manually

`mv .env-sample .env`
Add your GitHub creds (or use a dummy GitHub account for automation)

* extracts scores from health department site
* transforms them to lives format
* loads to [github repo](https://github.com/openlexington/health-department-yelp-data)

`bundle exec ruby lives_etl.rb`

## Deploy to Heroku for automation

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

## Enable automated ETL

Add Heroku Scheduler add-on to Heroku instance

set to run daily:

`bundle exec ruby lives_etl.rb <permalinik to health scores>`

eg `bundle exec ruby lives_etl.rb "http://lexingtonhealthdepartment.org/Portals/0/environmental%20health/most_recent_food_scores.xls"`

## To check when scores have changed on the Health Dept page

Use http://www.changedetection.com/monitor.html

That way you get a notification that the scores have changed and the automation should have kicked off.

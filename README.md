# Lex to LIVES

A Ruby script that takes Lexington Health Department restaurant inspection
scores to the [LIVES standard](http://www.yelp.com/healthscores).

Assembled by OpenLexington for Code Across America 2013

## To convert health department food scores

`mv .env-sample .env`
Add your s3 creds env

# extracts scores from health department site
# transforms them to lives format
# loads to s3 bucket
`ruby lives_etl.rb`

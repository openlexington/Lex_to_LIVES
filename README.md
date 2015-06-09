# Lex to LIVES

A Ruby script that takes Lexington Health Department restaurant inspection
scores to the [LIVES standard](http://www.yelp.com/healthscores).

Assembled by OpenLexington for Code Across America 2013

## To convert health department food scores manually
* Download [most_recent_food_scores](http://www.lexingtonhealthdepartment.org/Portals/0/environmental%20health/most_recent_food_scores.xls) xls file
* `ruby xls_to_csv.rb` # outputs most_recent_food_scores.csv but the xls parser skips empty cells causing errors
* upload xls to google docs and export as most_recent_food_scores.csv
* `fig run cmd ./lex_to_lives.rb most_recent_food_scores.csv`
* `zip most_recent_food_scores.zip {businesses,inspections,violations}.csv`

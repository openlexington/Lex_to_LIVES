#!/usr/bin/env ruby

require 'rubygems'
require 'csv'
require 'roo-xls'
require './lex_to_lives'

s = Roo::Excel.new('most_recent_food_scores.xls')

headers = []
(1..10).each do |i|
  headers.push(s.cell(1,i).to_s.to_sym)
end

def csv_write(output_file, row_headers, spreadsheet)
  csv_opts = {headers: row_headers, write_headers: true}

  CSV.open(output_file, "wb", csv_opts) do |csv|
    for i in 2..spreadsheet.last_row do
      csv << spreadsheet.row(i)
    end
  end
end

temp_file = Tempfile.new('most_recent_food_scores.csv')
csv_write(temp_file.path, headers, s)

LexToLIVES.new.transform(temp_file.path)

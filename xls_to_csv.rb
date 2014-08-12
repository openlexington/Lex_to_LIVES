require 'rubygems'
require 'csv'
require 'roo'

s = Roo::Excel.new('most_recent_food_scores.xls')

headers = []
for i in 1..10
  headers.push(s.cell(1,i).to_sym)
end

def csv_write(output_file, row_headers, spreadsheet)
  csv_opts = {headers: row_headers, write_headers: true}

  CSV.open(output_file, "wb", csv_opts) do |csv|
    for i in 2..spreadsheet.last_row do
      csv << spreadsheet.row(i).compact
    end
  end
end

csv_write('most_recent_food_scores.csv', headers, s)

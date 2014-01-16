require 'rubygems'
require 'csv'
require 'roo'

s = Roo::Excel.new('Jan2014_Restaurant Scores.xls')

headers = []
for i in 1..8
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

csv_write('test.csv', headers, s)

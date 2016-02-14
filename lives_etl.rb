#!/usr/bin/env ruby

require 'rubygems'
require 'csv'
require 'roo-xls'
require './lex_to_lives'
require 'aws'
require 'net/http'
require 'dotenv'
Dotenv.load

HEALTH_DEPT_PERMALINK = 'http://www.lexingtonhealthdepartment.org/Portals/0/environmental%20health/most_recent_food_scores.xls'

s3 = Aws::S3.new(ENV['S3_KEY'], ENV['S3_SECRET'])
bucket = Aws::S3::Bucket.create(s3, ENV['S3_BUCKET'])

def save_to_tempfile(url)
  uri = URI.parse(url)
  Net::HTTP.start(uri.host, uri.port) do |http|
    resp = http.get(uri.path)
    file = Tempfile.new(['foo', '.xls'])
    file.binmode
    file.write(resp.body)
    file.flush
    file
  end
end

def csv_write(output_file, row_headers, spreadsheet)
  csv_opts = {headers: row_headers, write_headers: true}

  CSV.open(output_file, "wb", csv_opts) do |csv|
    for i in 2..spreadsheet.last_row do
      csv << spreadsheet.row(i)
    end
  end
end

def to_lives_zip(csv_file)
  outfiles = {
    businesses_file: Tempfile.new('businesses.csv').path,
    inspections_file: Tempfile.new('inspections.csv').path,
    violations_file: Tempfile.new('violations.csv').path,
  }

  LexToLIVES.new(csv_file.path, outfiles).transform

  zip_file = Tempfile.new("most_recent_food_scores.zip")

  Zip::File.open(zip_file.path, Zip::File::CREATE) do |zipfile|
    outfiles.each do |key, filename|
      zipfile.add(key.to_s.sub('_file', '.csv'), filename)
    end
  end
  zip_file
end

xls_file = save_to_tempfile(HEALTH_DEPT_PERMALINK)

xls = Roo::Excel.new(xls_file)
headers = []
(1..10).each do |i|
  headers.push(xls.cell(1,i).to_s.to_sym)
end

csv_file = Tempfile.new('most_recent_food_scores.csv')
csv_write(csv_file.path, headers, xls)
zip_file = to_lives_zip(csv_file)

bucket.put("most_recent_food_scores.xls", IO.read(xls_file), {}, 'authenticated-read')
bucket.put("most_recent_food_scores.csv", IO.read(csv_file), {}, 'authenticated-read')
bucket.put("most_recent_food_scores.zip", IO.read(zip_file), {}, 'authenticated-read')

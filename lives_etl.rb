#!/usr/bin/env ruby

require 'rubygems'
require 'csv'
require 'roo-xls'
require './lex_to_lives'
require 'net/http'
require 'rugged'
require 'dotenv'

Dotenv.load

HEALTH_DEPT_PERMALINK = 'http://www.lexingtonhealthdepartment.org/Portals/0/environmental%20health/most_recent_food_scores.xls'
TEMP_DIR = Dir.mktmpdir

git_email = 'erik@erikschwartz.net'
git_name = 'Erik Schwartz'

clone_url = 'https://github.com/eeeschwartz/lexingtonky-lives-data.git'
repo = Rugged::Repository.clone_at(clone_url, TEMP_DIR)

# (2)
repo.checkout 'refs/heads/gh-pages'

# (3)
index = repo.index


File.open(File.join(TEMP_DIR, 'feed_info.csv'), 'w') do |f|
  f.write("Now: #{Time.now}")
end

index.add path: 'feed_info.csv',
  oid: (Rugged::Blob.from_workdir repo, 'feed_info.csv'),
  mode: 0100644

# (6)
commit_tree = index.write_tree repo

# (7)
index.write

# (8)
commit_author = { email: git_email, name: git_name, time: Time.now }
Rugged::Commit.create repo,
  author: commit_author,
  committer: commit_author,
  message: 'Testing the rugged gem',
  parents: [repo.head.target],
  tree: commit_tree,
  update_ref: 'HEAD'

user = ENV['GITHUB_USER']
pass = ENV['GITHUB_PASS']

credentials = Rugged::Credentials::UserPassword.new(username: user, password: pass)

repo.push('origin', ['refs/heads/gh-pages'], { credentials: credentials })
#
# def save_to_tempfile(url)
#   uri = URI.parse(url)
#   Net::HTTP.start(uri.host, uri.port) do |http|
#     resp = http.get(uri.path)
#     file = File.new('most_recent_food_scores.xls', TEMP_DIR)
#     file.binmode
#     file.write(resp.body)
#     file.flush
#     file
#   end
# end
#
# def csv_write(output_file, row_headers, spreadsheet)
#   csv_opts = {headers: row_headers, write_headers: true}
#
#   CSV.open(output_file, "wb", csv_opts) do |csv|
#     for i in 2..spreadsheet.last_row do
#       csv << spreadsheet.row(i)
#     end
#   end
# end
#
# def to_lives_zip(csv_file)
#   outfiles = {
#     businesses_file: File.new('businesses.csv', TEMP_DIR).path,
#     inspections_file: File.new('inspections.csv', TEMP_DIR).path,
#     violations_file: File.new('violations.csv', TEMP_DIR).path,
#   }
#
#   LexToLIVES.new(csv_file.path, outfiles).transform
#
#   zip_file = File.new("most_recent_food_scores.zip")
#
#   Zip::File.open(zip_file.path, Zip::File::CREATE) do |zipfile|
#     outfiles.each do |key, filename|
#       zipfile.add(key.to_s.sub('_file', '.csv'), filename)
#     end
#   end
#   zip_file
# end
#
# xls_file = save_to_tempfile(HEALTH_DEPT_PERMALINK)
#
# xls = Roo::Excel.new(xls_file)
# headers = []
# (1..10).each do |i|
#   headers.push(xls.cell(1,i).to_s.to_sym)
# end
#
# csv_file = File.new('most_recent_food_scores.csv', TEMP_DIR)
# csv_write(csv_file.path, headers, xls)
# zip_file = to_lives_zip(csv_file)

p `cat #{TEMP_DIR}/feed_info.csv`

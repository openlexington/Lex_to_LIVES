#!/usr/bin/env ruby

require 'rubygems'
require 'csv'
require 'roo-xls'
require './lex_to_lives'
require 'rugged'
require 'net/http'
require 'dotenv'
Dotenv.load

HEALTH_DEPT_PERMALINK = 'http://www.lexingtonhealthdepartment.org/Portals/0/environmental%20health/most_recent_food_scores.xls'

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

def push_to_github(files)
  git_email = 'erik+civichelper@erikschwartz.net'
  git_name = 'Civic Helper Bot'

  clone_url = 'https://github.com/eeeschwartz/lexingtonky-lives-data.git'
  repo = Rugged::Repository.clone_at(clone_url, Dir.mktmpdir)
  repo.checkout('refs/heads/gh-pages')

  files.each do |git_path, file_path|
    repo.index.add(path: git_path,
      oid: Rugged::Blob.from_disk(repo, file_path),
      mode: 0100644)
  end

  commit_tree = repo.index.write_tree(repo)
  repo.index.write
  commit_author = { email: git_email, name: git_name, time: Time.now }

  Rugged::Commit.create(repo,
    author: commit_author,
    committer: commit_author,
    message: 'Automatic feed update',
    parents: [repo.head.target],
    tree: commit_tree,
    update_ref: 'HEAD')

  credentials = Rugged::Credentials::UserPassword.new(username: ENV['GITHUB_USER'], password: ENV['GITHUB_PASS'])

  repo.push('origin', ['refs/heads/gh-pages'], { credentials: credentials })
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

push_to_github({
  'most_recent_food_scores.xls' => xls_file.path,
  'most_recent_food_scores.csv' => csv_file.path,
  'most_recent_food_scores.zip' => zip_file.path,
})

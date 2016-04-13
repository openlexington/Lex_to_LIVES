#!/usr/bin/env ruby

require 'rubygems'
require 'csv'
require 'roo-xls'
require './lex_to_lives'
require 'rugged'
require 'net/http'
require 'dotenv'
Dotenv.load

HEALTH_DEPT_PERMALINK = 'http://lexingtonhealthdepartment.org/Portals/0/most_recent_food_scores.xls'

TEMPDIR = Dir.mktmpdir
clone_url = 'https://github.com/openlexington/health-department-yelp-data.git'
repo = Rugged::Repository.clone_at(clone_url, TEMPDIR)
repo.checkout('refs/heads/gh-pages')

def save_to_tempfile(url)
  uri = URI.parse(url)
  Net::HTTP.start(uri.host, uri.port) do |http|
    resp = http.get(uri.path)
    file = File.open(File.join(TEMPDIR, 'most_recent_food_scores.xls'), 'w+')
    file.binmode
    file.write(resp.body)
    file.flush
    file
  end
end

def csv_write(output_file, row_headers, spreadsheet)
  csv_opts = {headers: row_headers, write_headers: true}

  CSV.open(output_file, "wb", csv_opts) do |csv|
    (2..spreadsheet.last_row).each do |row|
      csv << spreadsheet.row(row)
    end
  end
end

def to_lives_zip(csv_file)
  outfiles = {
    businesses_file: File.join(TEMPDIR, 'businesses.csv'),
    inspections_file: File.join(TEMPDIR, 'inspections.csv'),
    violations_file: File.join(TEMPDIR, 'violations.csv'),
    feed_info_file: File.join(TEMPDIR, 'feed_info.csv'),
  }

  LexToLIVES.new(csv_file.path, outfiles).transform

  zip_file = File.join(TEMPDIR, 'most_recent_food_scores.zip')

  File.delete(zip_file) if File.exists?(zip_file)

  Zip::File.open(zip_file, Zip::File::CREATE) do |zipfile|
    outfiles.each do |key, filename|
      zipfile.add(key.to_s.sub('_file', '.csv'), filename)
    end
  end
  zip_file
end

def stage_changes(repo)
  should_push = false
  repo.index.diff.each_delta do |d|
    # only push if scores have changed
    if d.old_file[:path] == 'most_recent_food_scores.csv'
      should_push = true
    end

    repo.index.add(path: d.new_file[:path],
      oid: Rugged::Blob.from_workdir(repo, d.new_file[:path]),
      mode: 0100644)
  end
  should_push
end

def push_to_github(repo)
  git_email = 'erik+civichelper@erikschwartz.net'
  git_name = 'Civic Helper Bot'
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

  credentials = Rugged::Credentials::UserPassword.new(username: ENV.fetch('GITHUB_USER'),
    password: ENV.fetch('GITHUB_PASS'))

  repo.push('origin', ['refs/heads/gh-pages'], { credentials: credentials })
end

xls_file = save_to_tempfile(HEALTH_DEPT_PERMALINK)

xls = Roo::Excel.new(xls_file)
headers = []
(1..10).each do |i|
  headers.push(xls.cell(1,i).to_s.to_sym)
end

csv_file = File.new(File.join(TEMPDIR, 'most_recent_food_scores.csv'), 'w+')
csv_write(csv_file.path, headers, xls)
zip_file = to_lives_zip(csv_file)

push_to_github(repo) if stage_changes(repo)

#!/usr/bin/env ruby

require "json"
require "time"
require "optparse"

class RegistryCleaner
  def initialize(options = {})
    @dry_run = options[:dry_run] || false
    @keep_count = options[:keep_count] || 1
    @min_age_days = options[:min_age_days] || 7
    @repositories = options[:repositories] || []
  end

  def run
    puts "Starting DigitalOcean Container Registry cleanup..."
    puts "Mode: #{@dry_run ? "DRY RUN" : "LIVE"}"
    puts "Keep last #{@keep_count} tag(s)"
    puts "Minimum age: #{@min_age_days} days"
    puts "-" * 50

    repositories = @repositories.empty? ? fetch_all_repositories : @repositories

    repositories.each do |repo|
      puts "\nProcessing repository: #{repo}"
      clean_repository(repo)
    end

    puts "\nCleanup complete!"
  end

  private

  def fetch_all_repositories
    puts "Fetching all repositories..."
    output = execute_command("doctl registry repository list-v2 --output json")

    repositories = JSON.parse(output)
    repository_names = repositories.map { |r| r["name"] }

    puts "Found #{repository_names.length} repositories"
    repository_names
  end

  def clean_repository(repository_name)
    tags = fetch_tags(repository_name)

    if tags.empty?
      puts "  No tags found"
      return
    end

    puts "  Found #{tags.length} tags"

    # Sort tags by updated_at, newest first
    sorted_tags = tags.sort_by { |tag| Time.parse(tag["updated_at"]) }.reverse

    # Determine which tags to keep
    tags_to_keep = []
    tags_to_delete = []

    sorted_tags.each_with_index do |tag, index|
      tag_age_days = (Time.now - Time.parse(tag["updated_at"])) / (24 * 60 * 60)

      if index < @keep_count
        tags_to_keep << tag
        puts "  KEEP: #{tag["tag"]} (position: #{index + 1}, age: #{tag_age_days.round} days)"
      elsif tag_age_days < @min_age_days
        tags_to_keep << tag
        puts "  KEEP: #{tag["tag"]} (too new: #{tag_age_days.round} days old)"
      else
        tags_to_delete << tag
        puts "  DELETE: #{tag["tag"]} (age: #{tag_age_days.round} days)"
      end
    end

    # Delete old tags
    if tags_to_delete.empty?
      puts "  No tags to delete"
    else
      puts "  Deleting #{tags_to_delete.length} tags..."
      delete_tags(repository_name, tags_to_delete)
    end
  end

  def fetch_tags(repository_name)
    output = execute_command("doctl registry repository list-tags #{repository_name} --output json")
    JSON.parse(output)
  rescue => e
    puts "  Error fetching tags: #{e.message}"
    []
  end

  def delete_tags(repository_name, tags)
    tags.each do |tag|
      if @dry_run
        puts "    [DRY RUN] Would delete: #{tag["tag"]}"
      else
        begin
          execute_command("doctl registry repository delete-tag #{repository_name} #{tag["tag"]} --force")
          puts "    Deleted: #{tag["tag"]}"
        rescue => e
          puts "    Error deleting #{tag["tag"]}: #{e.message}"
        end
      end
    end
  end

  def execute_command(command)
    output = `#{command} 2>&1`
    if $?.success?
      output
    else
      raise "Command failed: #{command}\nOutput: #{output}"
    end
  end
end

# Parse command-line options
options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-d", "--dry-run", "Run in dry-run mode (no deletions)") do
    options[:dry_run] = true
  end

  opts.on("-k", "--keep-count COUNT", Integer, "Number of recent tags to keep (default: 1)") do |count|
    options[:keep_count] = count
  end

  opts.on("-a", "--min-age-days DAYS", Integer, "Minimum age in days before deletion (default: 7)") do |days|
    options[:min_age_days] = days
  end

  opts.on("-r", "--repository REPO", "Specific repository to clean (can be specified multiple times)") do |repo|
    options[:repositories] ||= []
    options[:repositories] << repo
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end

parser.parse!

# Run the cleaner
cleaner = RegistryCleaner.new(options)
cleaner.run

#!/usr/bin/env ruby
# manage_resources.rb
#
# Interactive CLI to add, edit, or delete resource entries
# for a Jekyll site organized as collections:
#   _math_resources/, _cs_resources/, _other_resources/
#
# Run from the root of your Jekyll repo:
#   ruby scripts/manage_resources.rb

require 'yaml'
require 'fileutils'

COLLECTIONS = {
  "math"   => "math_resources",
  "cs"     => "cs_resources",
  "others" => "other_resources"
}.freeze

TYPES  = %w[article video].freeze
LEVELS = %w[newbie advanced].freeze

# ---------- helpers ----------

def ask(prompt)
  print "#{prompt}: "
  gets.strip
end

def linux?
  RUBY_PLATFORM.include?("linux")
end

def command_exists?(cmd)
  system("command -v #{cmd} > /dev/null 2>&1")
end

REQUIRED_TOOLS = {
  "git"     => "git",
  "bundle"  => "ruby-bundler"
}.freeze

def check_dependencies!
  missing = REQUIRED_TOOLS.reject { |cmd, _| command_exists?(cmd) }
  return if missing.empty?

  puts "\nMissing dependencies detected: #{missing.keys.join(', ')}"

  unless linux?
    puts "Automatic installation is only supported on Linux."
    puts "Please install manually and re-run this script: #{missing.keys.join(', ')}"
    exit 1
  end

  unless command_exists?("apt-get")
    puts "Automatic installation only supports apt-based distros (Debian/Ubuntu)."
    puts "Please install manually and re-run this script: #{missing.values.join(', ')}"
    exit 1
  end

  missing.each do |cmd, apt_package|
    answer = ask("'#{cmd}' is not installed. Install '#{apt_package}' now via apt? (y/n)")
    if answer.strip.downcase == "y"
      puts "Installing #{apt_package}..."
      success = system("sudo apt-get install -y #{apt_package}")
      unless success
        puts "Failed to install #{apt_package}. Exiting."
        exit 1
      end
    else
      puts "'#{cmd}' is required to run this script. Exiting."
      exit 1
    end
  end
end

def check_bundle_install!
  return unless File.exist?("Gemfile")
  return if system("bundle check > /dev/null 2>&1")

  puts "\nSome Ruby gems required by this Jekyll site are not installed."
  answer = ask("Run 'bundle install' now? (y/n)")
  if answer.strip.downcase == "y"
    success = system("bundle install")
    unless success
      puts "'bundle install' failed. Exiting."
      exit 1
    end
  else
    puts "Required gems are missing. Exiting."
    exit 1
  end
end

def ask_from_list(prompt, options)
  loop do
    puts "#{prompt}:"
    options.each_with_index { |o, i| puts "  #{i + 1}) #{o}" }
    choice = ask("Choose a number")
    idx = choice.to_i - 1
    return options[idx] if idx >= 0 && idx < options.length
    puts "Invalid choice, try again."
  end
end

def slugify(title)
  title.downcase
       .gsub(/[^a-z0-9\s-]/, '')
       .strip
       .gsub(/\s+/, '-')
       .gsub(/-+/, '-')
end

def collection_dir(collection_key)
  "_#{COLLECTIONS[collection_key]}"
end

def list_items(collection_key)
  dir = collection_dir(collection_key)
  FileUtils.mkdir_p(dir)
  Dir.glob(File.join(dir, "*.md")).sort
end

def read_item(path)
  content = File.read(path)
  if content.start_with?("---")
    _, fm, body = content.split("---", 3)
    front_matter = YAML.safe_load(fm) || {}
    body = body.to_s.strip
  else
    front_matter = {}
    body = content.strip
  end
  [front_matter, body]
end

def write_item(path, front_matter, body)
  File.open(path, "w") do |f|
    f.puts "---"
    f.puts front_matter.to_yaml.sub(/\A---\n/, '')
    f.puts "---"
    f.puts body unless body.to_s.empty?
  end
end

def pick_item(collection_key)
  files = list_items(collection_key)
  if files.empty?
    puts "No resources found in '#{collection_key}'."
    return nil
  end

  puts "\nResources in '#{collection_key}':"
  files.each_with_index do |file, i|
    fm, = read_item(file)
    puts "  #{i + 1}) #{fm['title']} (#{fm['type']}, #{fm['level']})"
  end

  choice = ask("Choose a number (or blank to cancel)")
  return nil if choice.empty?

  idx = choice.to_i - 1
  return nil unless idx >= 0 && idx < files.length

  files[idx]
end

# ---------- actions ----------

def add_resource
  puts "\n--- Add a resource ---"
  collection_key = ask_from_list("Where do you want to add it", COLLECTIONS.keys)
  type  = ask_from_list("Type", TYPES)
  level = ask_from_list("Level", LEVELS)

  title       = ask("Title")
  link        = ask("Source link")
  tags_input  = ask("Tags (comma-separated)")
  description = ask("Short description")

  tags = tags_input.split(",").map(&:strip).reject(&:empty?)

  dir = collection_dir(collection_key)
  FileUtils.mkdir_p(dir)

  slug = slugify(title)
  slug = "resource-#{Time.now.to_i}" if slug.empty?

  filename = "#{slug}.md"
  path = File.join(dir, filename)

  if File.exist?(path)
    suffix = 2
    loop do
      candidate = File.join(dir, "#{slug}-#{suffix}.md")
      unless File.exist?(candidate)
        path = candidate
        break
      end
      suffix += 1
    end
  end

  front_matter = {
    "title"       => title,
    "type"        => type,
    "level"       => level,
    "link"        => link,
    "tags"        => tags,
    "description" => description
  }

  write_item(path, front_matter, "")
  puts "Added: #{path}"
end

def edit_resource
  puts "\n--- Edit a resource ---"
  collection_key = ask_from_list("Which collection", COLLECTIONS.keys)
  path = pick_item(collection_key)
  return unless path

  front_matter, body = read_item(path)

  fields = %w[title type level link tags description]
  puts "\nCurrent values:"
  fields.each { |f| puts "  #{f}: #{front_matter[f]}" }

  field = ask_from_list("Which field do you want to change", fields)

  new_value =
    case field
    when "type"
      ask_from_list("New type", TYPES)
    when "level"
      ask_from_list("New level", LEVELS)
    when "tags"
      ask("New tags (comma-separated)").split(",").map(&:strip).reject(&:empty?)
    else
      ask("New #{field}")
    end

  front_matter[field] = new_value
  write_item(path, front_matter, body)
  puts "Updated: #{path}"
end

def delete_resource
  puts "\n--- Delete a resource ---"
  collection_key = ask_from_list("Which collection", COLLECTIONS.keys)
  path = pick_item(collection_key)
  return unless path

  confirm = ask("Delete #{path}? Type 'yes' to confirm")
  if confirm.downcase == "yes"
    File.delete(path)
    puts "Deleted: #{path}"
  else
    puts "Cancelled."
  end
end

# ---------- main menu ----------

check_dependencies!
check_bundle_install!

loop do
  puts "\n=== Resource manager ==="
  action = ask_from_list("What do you want to do", ["Add resource", "Edit resource", "Delete resource", "Exit"])

  case action
  when "Add resource"    then add_resource
  when "Edit resource"   then edit_resource
  when "Delete resource" then delete_resource
  when "Exit"
    puts "Bye."
    break
  end
end

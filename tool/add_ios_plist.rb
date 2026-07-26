#!/usr/bin/env ruby
# Adds ios/Runner/GoogleService-Info.plist to the Runner target so it is bundled
# into the app. Idempotent. Requires the `xcodeproj` gem.
require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
plist_name = 'GoogleService-Info.plist'

project = Xcodeproj::Project.open(project_path)
runner = project.targets.find { |t| t.name == 'Runner' }
abort('Runner target not found') unless runner

group = project.main_group['Runner']
unless group.files.any? { |f| f.display_name == plist_name }
  file_ref = group.new_reference(plist_name)
  runner.add_resources([file_ref])
  project.save
  puts "  Added #{plist_name} to Runner target."
else
  puts "  #{plist_name} already in Runner target."
end

require 'xcodeproj'
project_path = 'Drink Reminder.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first
group = project.main_group.find_subpath('Drink Reminder/Utils', true)
file = group.new_file('UpdateManager.swift')
target.source_build_phase.add_file_reference(file)
project.save

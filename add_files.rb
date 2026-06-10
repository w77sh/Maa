require 'xcodeproj'

project_path = 'Drink Reminder.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

group = project.main_group.find_subpath(File.join('Drink Reminder', 'UI'), true)
model_group = project.main_group.find_subpath(File.join('Drink Reminder', 'Model'), true)

ui_files = ['ReminderPopupView.swift', 'StatisticsView.swift', 'WindowManager.swift']
model_files = ['DailyHistoryStore.swift', 'ReminderStateStore.swift']

ui_files.each do |file|
    path = "Drink Reminder/UI/#{file}"
    unless group.files.any? { |f| f.path == file }
        file_ref = group.new_reference(file)
        target.add_file_references([file_ref])
    end
end

model_files.each do |file|
    path = "Drink Reminder/Model/#{file}"
    unless model_group.files.any? { |f| f.path == file }
        file_ref = model_group.new_reference(file)
        target.add_file_references([file_ref])
    end
end

project.save

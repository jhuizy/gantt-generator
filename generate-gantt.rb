require "csv"
require "date"
require "optparse"

Task = Data.define(:name, :duration) do
  def to_gantt_task(start_date)
    GanttTask.new(name: name, start_date: start_date, end_date: start_date + duration * 7)
  end
end

GanttTask = Data.define(:name, :start_date, :end_date) do
  def format_to_mermaid
    "#{name} :active, #{start_date.strftime("%Y-%m-%d")}, #{duration}w"
  end

  # calculate weeks bewteen dates
  def duration
    (end_date - start_date).to_i / 7
  end
end

# Takes an array of tasks and returns an array of GanttTask objects
# @param tasks [Array<Task>]
# @param start_date [Date] The start date of the project
# @param max_work_in_progress [Integer] The maximum number of tasks that can be in progress at the same time
# @return [Array<GanttTask>]
def tasks_to_gantt(tasks, start_date, max_work_in_progress)
  if tasks.length <= max_work_in_progress
    return tasks.map { |task| task.to_gantt_task(start_date) }
  end

  in_progress = tasks.take(max_work_in_progress).map { |task| task.to_gantt_task(start_date) }
  gantt_tasks = in_progress.dup

  tasks[max_work_in_progress..].each do |task|
    # pop the task with earliest end date
    start_date = in_progress.sort_by!(&:end_date).reverse!.pop.end_date + 1

    gantt_task = task.to_gantt_task(start_date)
    in_progress << gantt_task
    gantt_tasks << gantt_task
  end

  gantt_tasks
end

def csv_to_tasks(csv_file)
  tasks = CSV.read(csv_file, headers: true)
  tasks.map do |row|
    sum = row[1].to_i + row[2].to_i
    average = sum / 2
    Task.new(name: row[0], duration: average)
  end
end

def generate_mermaid_gantt(csv_file, start_date, max_work_in_progress)
  tasks = csv_to_tasks(csv_file)
  gantt_tasks = tasks_to_gantt(tasks, start_date, max_work_in_progress)

  gantt_chart = "gantt\n    title Project Timeline\n    dateFormat  YYYY-MM-DD\n    axisFormat  %d-%m-%Y\n\n"
  gantt_chart + gantt_tasks.map { |task| "    #{task.format_to_mermaid}" }.join("\n")
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: generator.rb -f CSV_FILE [-s START_DATE] [-m MAX_WORK_IN_PROGRESS]"

  opts.on("-f", "--file CSV_FILE", "The CSV file containing the tasks") do |csv_file|
    options[:csv_file] = csv_file
  end

  opts.on("-s", "--start_date [STRING]", String, "The start date of the project") do |start_date|
    options[:start_date] = Date.parse(start_date)
  end

  opts.on("-m", "--max_work_in_progress [INTEGER]", Integer, "The maximum number of tasks that can be in progress at the same time") do |max_work_in_progress|
    options[:max_work_in_progress] = max_work_in_progress
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end

  opts.parse!

  unless options[:csv_file]
    puts "Missing required argument: -f CSV_FILE"
    puts opts
    exit
  end

  begin
    puts generate_mermaid_gantt(options[:csv_file], options[:start_date] || Time.zone.today, options[:max_work_in_progress] || 2)
  rescue => e
    puts "Error: #{e.message}"
    exit
  end
end

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

class SimpleFormatter
  def format(tasks)
    tasks.map do |task|
      "Task: #{task.name}, Start: #{task.start_date}, End: #{task.end_date}, Duration: #{task.duration}"
    end 
  end
end

class MermaidGanttFormatter
  def format(tasks)
    output = "gantt\n    title Project Timeline\n    dateFormat  YYYY-MM-DD\n    axisFormat  %d-%m-%Y\n\n"
    output += tasks.map { |task| "    #{task.format_to_mermaid}" }.join("\n")
    output  
  end
end

class ConfluenceTableFormatter
  def format(tasks)
    table = "|Item|Start|Time Taken|End|\n"
    table << "|:------|------:|------:|-----:|\n"
    tasks.each do |task|
      table << "|#{task.name}|#{format_date(task.start_date)}|#{task.duration}|#{format_date(task.end_date)}|\n"
    end
    table
  end

  private

  def format_date(date)
    # print date in the format: MMM DD, YYYY, eg. Jul 01, 2025
    date.strftime("%b %d, %Y")
  end
end

class MarkdownTableFormatter
  def format(tasks)
    table = "| Item | Start | Time Taken | End |\n"
    table << "|------|-------|------------|-----|\n"
    tasks.each do |task|
      table << "| #{task.name} | #{task.start_date} | #{task.duration} | #{task.end_date} |\n"
    end
    table
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

# Takes an array of Tasks and applies the given multiplier to the duration.
# Multiplier is a float value that will be multiplied by the duration of each task.
# For example, if the duration was 10, and multiplier 1.3, the new duration will be 13.
# It always rounds up.
# @param tasks [Array<Task>]
# @param multiplier [Float]
# @return [Array<Task>]
def apply_multiplier(tasks, multiplier)
  tasks.map do |task|
    Task.new(name: task.name, duration: (task.duration * multiplier).ceil)
  end
end

def csv_to_tasks(csv_file)
  tasks = CSV.read(csv_file, headers: true)
  tasks.map do |row|
    sum = row[1].to_i + row[2].to_i
    average = sum / 2
    Task.new(name: row[0], duration: average)
  end
end

def generate_output(csv_file, start_date, max_work_in_progress, multiplier, formatter)
  tasks = apply_multiplier(csv_to_tasks(csv_file), multiplier)
  gantt_tasks = tasks_to_gantt(tasks, start_date, max_work_in_progress)

  formatter.format(gantt_tasks)
end

def output_to_mermaid(gantt_tasks)
  output = "gantt\n    title Project Timeline\n    dateFormat  YYYY-MM-DD\n    axisFormat  %d-%m-%Y\n\n"
  output += gantt_tasks.map { |task| "    #{task.format_to_mermaid}" }.join("\n")
  output
end

def output_to_string(gantt_tasks)
  gantt_tasks.map do |task|
    "Task: #{task.name}, Start: #{task.start_date}, End: #{task.end_date}, Duration: #{task.duration}"
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: generate-gantt.rb -f CSV_FILE -o FORMAT [-s START_DATE] [-m MAX_WORK_IN_PROGRESS] [-m MULTIPLIER]"

  opts.on("-f", "--file CSV_FILE", "The CSV file containing the tasks") do |csv_file|
    options[:csv_file] = csv_file
  end

  opts.on("-s", "--start_date [STRING]", String, "The start date of the project") do |start_date|
    options[:start_date] = Date.parse(start_date)
  end

  opts.on("-m", "--max_work_in_progress [INTEGER]", Integer, "The maximum number of tasks that can be in progress at the same time") do |max_work_in_progress|
    options[:max_work_in_progress] = max_work_in_progress
  end

  # add option to add multiplier to the duration
  opts.on("-m", "--multiplier [FLOAT]", Float, "The multiplier to the duration") do |multiplier|
    options[:multiplier] = multiplier
  end

  opts.on("-o", "--output [FORMAT]", String, "The output format, one of (g|gantt|mermaid), (s|string), (c|confluence) or (m|markdown)") do |output|
    case output
    when "g", "mermaid", "gantt"
      options[:formatter] = MermaidGanttFormatter.new
    when "s", "string"
      options[:formatter] = SimpleFormatter.new
    when "c", "confluence"
      options[:formatter] = ConfluenceTableFormatter.new
    when "m", "markdown"
      options[:formatter] = MarkdownTableFormatter.new
    else
      raise "Invalid output format: #{output}"
      puts opts
      exit
    end
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

  unless File.exist?(options[:csv_file])
    puts "Error: File not found: #{options[:csv_file]}"
    exit
  end
  
  unless options[:formatter]
    puts "Error: Missing output format option"
    puts opts
    exit
  end

  begin
    puts generate_output(options[:csv_file], options[:start_date] || Date.today, options[:max_work_in_progress] || 2, options[:multiplier], options[:formatter])
  rescue => e
    puts "Error: #{e.message}"
    exit
  end
end

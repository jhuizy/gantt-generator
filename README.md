# Mermaid Gantt Generator
This program generates a [mermaid.js compatible gantt chart](https://mermaid.js.org/syntax/gantt.html). 

# Usage

You will need to have ruby (>3.2) installed. Once installed simply invoke the generate-gantt.rb file with ruby.

For a list of different options use the `--help` command line flag.

```
ruby generate-gantt.rb --help

Usage: generate-gantt.rb -f CSV_FILE [-s START_DATE] [-m MAX_WORK_IN_PROGRESS]
    -f, --file CSV_FILE              The CSV file containing the tasks
    -s, --start_date [STRING]        The start date of the project
    -m [INTEGER],                    The maximum number of tasks that can be in progress at the same time
        --max_work_in_progress
    -h, --help                       Prints this help
```

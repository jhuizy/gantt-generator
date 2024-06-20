# Gantt Generator
This program generates a gantt chart based on a number of items in priority order and how long they would be expected to take.

# Output Formats
This program supports a number of output options, including:
- [mermaid.js compatible gantt chart](https://mermaid.js.org/syntax/gantt.html). 
- Markdown table
- Plain text text
- "Confluence compatible table" (you can copy/paste the output into confluence and it will render as a table)

# Usage

You will need to have ruby (>3.2) installed. Once installed simply invoke the generate-gantt.rb file with ruby.

For a list of different options use the `--help` command line flag.

```
ruby generate-gantt.rb --help

Usage: generate-gantt.rb -f CSV_FILE -o FORMAT [-s START_DATE] [-m MAX_WORK_IN_PROGRESS] [-m MULTIPLIER]
    -f, --file CSV_FILE              The CSV file containing the tasks
    -s, --start_date [STRING]        The start date of the project
        --max_work_in_progress [INTEGER]
                                     The maximum number of tasks that can be in progress at the same time
    -m, --multiplier [FLOAT]         The multiplier to the duration
    -o, --output [FORMAT]            The output format, one of (g|gantt|mermaid), (s|string), (c|confluence) or (m|markdown)
    -h, --help                       Prints this help
```

Example CSV File would look something like this

```csv
Item,Min Duration,Max Duration
Login,4,4
Place Order,6,6
Returns,26,26
Invoicing,12,12
```
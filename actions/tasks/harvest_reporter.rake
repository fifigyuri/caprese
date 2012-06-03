require 'psych'
require 'harvested'
require 'date'
require 'debugger'

namespace :harvest do

  def gather_timesheet
    Dir['offline_cache/*.descriptions'].
      inject({}) do |timesheets_total, reportname|
      date_arr = reportname.scan(/(\d{4})-(\d{2})-(\d{2})\.descriptions/)[0]
      date = Date.new *date_arr.map(&:to_i) 
      File.open(reportname) do |reportfile|
        timesheets_total[date] =
          reportfile.each_line.inject({}) do |timesheet, description|
            timesheet[description] = (timesheet[description] || 0) + 1
            timesheet
          end
      end
      timesheets_total
    end
  end

  def config
    @config ||= Psych.load(File.open('harvest_reporter.yml').read)
  end

  def harvest
    @harvest ||= Harvest.hardy_client config['credentials']['subdomain'],
                                      config['credentials']['username'],
                                      config['credentials']['password'] 
  end
  def harvest_projects
    @harvest_projects ||= harvest.projects.all.select { |prj| prj.active }
  end
  def harvest_tasks
    @harvest_tasks ||= harvest.tasks.all
  end

  desc "Log time reports performed offline."
  task :push_reports do
    gather_timesheet.each_pair do |date, tasks|
      tasks.each_pair do |desc, pomodori|
        STDOUT << '-'*20+"\n"
        match = desc.match config['tokenizer']
        if match
          proj_code, task_code, note = match.captures
          note.strip!
        else
          STDOUT << "Pomodoro description could not be tokenized.\n"
          return false
        end
        
        project = harvest_projects.find { |prj| prj.code.match /^#{proj_code}/ }
        task = harvest_tasks.find { |task| task.name.match /^#{task_code}/ }
        duration = pomodori*0.5

        if project and task
          time_entry = Harvest::TimeEntry.new notes:      note,
                                              hours:      duration,
                                              spent_at:   date,
                                              project_id: project.id,
                                              task_id:    task.id 
          STDOUT << <<-CODE 
Date:     #{date.to_s}
Project:  #{project.code}
Task:     #{task.name}
Note:     #{note}
Duration: #{duration} h
CODE
          harvest.time.create(time_entry)
        else
          STDERR << "****No project or task found for description \"#{desc}\""
        end
      end
    end
  end

  desc "Delete all offline time-reports from the cache."
  task :clear do
    `rm offline_cache/*.descriptions`
  end
end

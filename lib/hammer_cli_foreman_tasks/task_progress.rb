require 'powerbar'
module HammerCLIForemanTasks
  class TaskProgress
    attr_accessor :interval, :task, :exit_code

    def initialize(task_id, &block)
      @update_block = block
      @task_id      = task_id
      @interval     = 2
    end

    def render
      update_task
      render_progress
    end

    private

    def render_progress
      progress_bar do |bar|
        begin
          while true
            bar.show(:msg => progress_message, :done => @task['progress'].to_f, :total => 1)
            if task_pending?
              sleep interval
              update_task
            else
              break
            end
          end
        rescue Interrupt
          # Inerrupting just means we stop rednering the progress bar
        end
      end
    end

    def progress_message
      "Task #{@task_id} #{task_pending? ? @task['state'] : @task['result']}"
    end

    def render_result
      puts @task['humanized']['output'] unless @task['humanized']['output'].to_s.empty?
      STDERR.puts @task['humanized']['errors'].join("\n") unless @task['humanized']['errors'].to_s.empty?
      self.exit_code = @task['humanized']['errors'].to_s.empty? ? HammerCLI::EX_OK : HammerCLI::EX_DATAERR
    end

    def update_task
      @task = @update_block.call(@task_id)
    end

    def task_pending?
      !%w[paused stopped].include?(@task['state'])
    end

    def progress_bar
      bar                                      = PowerBar.new
      @closed = false
      bar.settings.tty.finite.template.main    = '[${<bar>}] [${<percent>%}]'
      bar.settings.tty.finite.template.padchar = ' '
      bar.settings.tty.finite.template.barchar = '.'
      bar.settings.tty.finite.output           = Proc.new { |s| $stderr.print s }
      yield bar
    ensure
      bar.close
      render_result
    end
  end
end

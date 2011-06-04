require 'open4'
require 'grit'


class TddGitRunner

  @commit_msg = ""
  @had_errors = false
  @failures= 0
  @pending =  0
  @skipped= 0
  @rspec_output = ""

  def run_git_if_needed
    repo = Grit::Repo.new('.')
    repo.add(".")
    repo.commit_index(@commit_msg)
    puts "=========tddgit============"
    puts repo.log('master',nil,{:max_count => 1}).first.message
    puts "==========================="
  end


  def run_rspec
    @finished = false
    copy_msg = false
    @commit_msg = ""
    @commit_msg+= "tddgit: auto-commit after rspec"
    status = 
      Open4::popen4("sh") do |pid, stdin, stdout, stderr|
      stdin.puts "rspec "+ ARGV.join(' ')
      stdin.close
      begin
        while ((line = stderr.readpartial(10240).strip))
          @had_errors = true
          puts line 
        end
      rescue EOFError
      end
      begin
          while ((line = stdout.readpartial(10240).strip))
            puts line 
            @rspec_output += line
            @finished =  true   if line.match("Finished\ in\ \[0-9]+")
          end
        rescue EOFError
        end
      end
  end

  def collect_data
    unless @rspec_output =~ /([0-9]+)\ examples,\ ([0-9]+)\ failures?,\ ([0-9]+)\ pending/
      puts "NOT FOUBD MATCH"
       debugger
        true
    end
    @total_specs = $1.to_i
    @failures= $2.to_i
    @pending = $3.to_i
    @commit_msg = "tddgit: all good" if @failures == 0
    @commit_msg = "tddgit: #{@failures} failed of #{@total_specs} with #{@pending} pending." if @failures > 0
  end

  def run
    @rspec_output = ""
    @commit_msg = ""
    @finished = false
    run_rspec
    collect_data
    run_git_if_needed
  end
end

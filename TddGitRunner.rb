require 'open4'
require 'grit'


class TddGitRunner


  def run_git_if_needed(msg)
    repo = Grit::Repo.new('.')
    repo.add(".")
    repo.commit_index(msg)
    puts "=========tddgit============"
    puts repo.log('master',nil,{:max_count => 1}).first.message
    puts "==========================="
  end


  def run_rspec
    output = ""
    status = 
      Open4::popen4("sh") do |pid, stdin, stdout, stderr|
      stdin.puts "rspec "+ ARGV.join(' ')
      stdin.close
      begin
        while ((line = stderr.readpartial(10240).strip))
          puts line 
          output+= line
        end
      rescue EOFError
      end
      begin
          while ((line = stdout.readpartial(10240).strip))
            puts line 
            output += line
          end
        rescue EOFError
        end
      end
    output
  end

  def collect_data(log)
    unless log =~ /([0-9]+)\ examples,\ ([0-9]+)\ failures?,\ ([0-9]+)\ pending/
      puts "NOT FOUBD MATCH"
       debugger
        true
    end
    total_specs = $1.to_i
    failures= $2.to_i
    pending = $3.to_i
    commit_msg = "tddgit: all good" if failures == 0
    commit_msg = "tddgit: #{failures} failed of #{total_specs} with #{pending} pending." if failures > 0
    commit_msg
  end

  def run
    output = run_rspec
    msg = collect_data(output)
    run_git_if_needed (msg)
  end
end

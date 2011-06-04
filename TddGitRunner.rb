require 'open4'
require 'FileUtils'
require 'grit'


class TddGitRunner

  @commit_msg = ""
  MSG_FILE = ".git/msg.tddgit" 

  def make_commit_msg_file
    open(MSG_FILE, 'a') do |f|
      f.puts "tddgit: auto-commit after rspec"
      f.puts @commit_msg
    end
  end

  def run_git_if_needed_old
    status = 
      Open4::popen4("sh") do |pid, stdin, stdout, stderr|
      puts "tddgit: auto-committing.."
      make_commit_msg_file
      stdin.puts "git add ."
      stdin.puts "git commit -F #{MSG_FILE}"
      stdin.close
      begin
        while ((line = stdout.readpartial(10240).strip))
          puts line 
        end
      rescue EOFError
        if @finished
          puts "tddgit: commited"
        end
      end
      end

    FileUtils.rm MSG_FILE
  end

  def run_git_if_needed_old
    run_child_process("sh") do |stdin, stdout, stderr|
      puts "tddgit: auto-committing.."
      make_commit_msg_file
      stdin.puts "git add ."
      stdin.puts "git commit -F #{MSG_FILE}"
    end
    FileUtils.rm MSG_FILE
  end

  def run_git_if_needed
    repo = Grit::Repo.new('.')
    repo.add(".")
    repo.commit_index(@commit_msg)
    puts repo.log('master',nil,{:max_count => 1}).first.commit_message
  end

  def run_child_process(name)
    status = 
      Open4::popen4(name) do |pid, stdin, stdout, stderr|
      yield stdin, stdout, stderr if block_given?
      stdin.close
      begin
        while ((line = stdout.readpartial(10240).strip))
          puts line 
        end
      rescue EOFError
      end
      end
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
        while ((line = stdout.readpartial(10240).strip))
          puts line 
          @commit_msg += line if copy_msg
          copy_msg = true    if line.match("^Failures:")
          @finished =  true   if line.match("Finished\ in\ \[0-9]+")
        end
      rescue EOFError
        if @finished
          puts "tddgit: rspec done detected"
        end
      end
      end

  end

  def run
    @commit_msg = ""
    @finished = false
    run_rspec
    run_git_if_needed
  end
end

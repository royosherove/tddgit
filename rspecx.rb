#! /usr/bin/ruby
require 'open4'
require 'FileUtils'


class TddGitRunner

  @commit_msg = ""
  MSG_FILE = "msg.tddgit" 

  def make_commit_msg_file
    open(MSG_FILE, 'a') do |f|
      f.puts "tddgit: auto-commit after rspec"
      f.puts @commit_msg
    end
  end

  def run_git_if_needed
    status = 
      Open4::popen4("sh") do |pid, stdin, stdout, stderr|
      puts "tddgit: auto-committing.."
      stdin.puts "git add ."
      make_commit_msg_file
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

  def gitignore_msg

  end
  def run_rspec
    @finished = false
    copy_msg = false
    @commit_msg = ""
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
          puts "DONE DONE DONE!"
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
TddGitRunner.new.run

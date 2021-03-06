require "#{ENV["WEBSERVER_ROOT"]}/scripts/load_needed.rb"
require 'daemons'

Daemons.daemonize # Runs the script in the background

bug_id = ARGV[0]
bug = Bug.find(bug_id)

BUG_MAIL_DETAILS = {
  :from => "support@jammm.in",
  :password => "3WiseMen",
  :subject => "BUG REPORT - #{bug.subject}",
  :body => get_localhost_response("/partial/mail/bug_report?bug_id=#{bug.id}")
}

# The whole jammm.in team
address = [
    "prakashraman@jammm.in", 
    "tarunrs@jammm.in",
    "minesh.jatania@jammm.in",
    "karthik@jammm.in",
    "pallavi@jammm.in"
  ]
mail_to = (address + bug.contributors.map(&:email)).compact.uniq

mail BUG_MAIL_DETAILS.clone.update({:to => mail_to.join(",")})
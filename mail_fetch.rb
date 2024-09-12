#!/usr/bin/env ruby
# encoding: utf-8
#
# Copyright 2012 - 2024, Geir Isene. Released under the GPL v. 3
# Version 1.6 (2024-06-18)
# http://isene.com

#  Load modules {{{1
require 'net/imap'
require 'fileutils'

# Show help text when option "-h" is passed to mail_fetch {{{1
def help
puts <<HELPTEXT

  mail_fetch is a system that retrieves and filters mail from remote IMAP
  accounts and delivers to local folders according to user-defined rules.
  It includes examples and is intended to be run from cron.

  The main file "mail_fetch.rb" is packeged together with the files
  "mail.conf" and "mail.pw" as well as an example Conky configuration file
  ("conkyrc") and "README-mail_fetch.txt" into the package file
  "mail_fetch.tar.gz".

  Simply put the file "mail_fetch.rb" into a folder in your defined PATH.
  Rename the file "mail.conf" to ".mail.conf" and "mail.pw" to ".mail.pw".
  Put the files into your home directory.  Edit the file ".mail.conf" to
  include the path to the files ".mail" and ".mail2" as well as to the
  possibly created file "dead.letter". Add your remote servers with imap
  url and username - but do not put your passwords into ".mail.conf".  The
  passwords are instead entered into the file named ",mail.pw". Ensure
  this file is seen only by you (do "chmod 700 .mail.pw").

  Add filter rules to each remote server so that mail_fetch.rb knows where
  to deliver the retreived mail. Just follow the examples in the files, and
  you'll be fine.

  You need to have Ruby installed to run mail_fetch.rb.

  My "conkyrc" is included in the package mail_fetch.tar.gz as an example
  of how you can get visual notice of the mail_fetch running, network
  being unreachable, inability to login to local imap or remote servers
  and new mail count for the mail folders you decide to keep a tab on.

  Add an entry as a cron job using "crontab -e" that lookes like this:

  * * * * * /home/yourusername/bin/mail_fetch.rb >/dev/null 2>&1

  SYNOPSIS: 

    mail_fetch.rb [OPTION]

  OPTIONS:
  
    -h
      Displays the help text

    -n
      Toggles the "NoMail" directive (creates or removes a file named ".nomail")

    -f
      Forces execution of mail_fetch even if "NoMail" is set

    -d
      Deletes the lock file in case the program hangs during suspend or otherwise

  COPYRIGHT:
      
    Copyright 2012, Geir Isene. Released under the GPL v. 3
    See http://isene.com for more contributions by Geir Isene.

HELPTEXT
end

if ARGV[0] == "-h"
    help
    exit
end

# Delete lock-file with -d option {{{1
if ARGV[0] == "-d" or ARGV[0] == "-f"
  begin
    FileUtils.rm(".mail.lock")
	  exit
  rescue
	  exit
  end
end

# Exit if lock-file detected {{{1
if File.exist?(".mail.lock")
  puts "Busy!"
  exit
end

# Create lock-file {{{1 
# Ensures only one instance of mail_fetch is running.
# Avoids duplicate retrieval of mails
FileUtils.touch(".mail.lock")

# Toggle the NoMail directive {{{1
if ARGV[0] == "-n"
  if File.exist?(".nomail")
	  FileUtils.rm(".nomail")
	  puts "mail_fetch enabled"
  else
	  FileUtils.touch(".nomail")
	  puts "mail_fetch disabled"
  end
end

# Exit if file ".nomail" exists" {{{1
#  ".nomail" makes it possible for Conky to notify that no mail will be fetched
#  You can override the NoMail directive by using the argument "-f" (force)
if File.exist?(".nomail") and ARGV[0] != "-f"
  puts "NoMail"
  # Unlock before exit
  FileUtils.rm(".mail.lock")
  exit
end

# Exit if network is unavailable {{{1
# Create file ".nonet" to let Conky pick up if the Net is down
require 'open-uri'
begin
  URI.open("http://www.google.com/", :open_timeout=>5)
rescue
  FileUtils.touch(".nonet")
  puts "Network unreachable."
  # Unlock before exit
  FileUtils.rm(".mail.lock")
  exit
end

begin
  FileUtils.rm(".nonet")
rescue
end

# Initialize {{{1

#  Declare the variable $Mailserver as an array
$Mailserver = Array.new

#  Mail configuration for localhost and remote servers reside in ~/.mail.conf
#  Passwords resides in ~/.mail.pw
load	'/home/.safe/mail.pw'
load    '~/.mail.conf'

#  Declare the value that holds the number of mails filtered
$count = 0
puts "initialized"

# Define functions {{{1
#  Main Fetch & Filter function {{{2
def matching (match, match_in, to_box, del)
  res = []
  message = ""
  to_box = "INBOX." + to_box
  if match_in =~ /s/ then res = res + $imap_from.search(["UNSEEN", "SUBJECT", match]) end
  if match_in =~ /b/ then res = res + $imap_from.search(["UNSEEN", "BODY", match]) end
  if match_in =~ /f/ then res = res + $imap_from.search(["UNSEEN", "FROM", match]) end
  if match_in =~ /t/ then res = res + $imap_from.search(["UNSEEN", "TO", match]) end
  if match_in =~ /c/ then res = res + $imap_from.search(["UNSEEN", "CC", match]) end
  if match_in =~ /h/ then res = res + $imap_from.search(["UNSEEN", "HEADER", match]) end
  if match_in =~ /a/ then res = res + $imap_from.search(["UNSEEN", "TEXT", match]) end
  res.uniq!
  res.each do |message_id|
    message = $imap_from.fetch(message_id,'RFC822')[0].attr['RFC822']
    $imap_to.append(to_box, message)
    if del == 1
  $imap_from.store(message_id, "+FLAGS", [:Deleted])
    else 
  $imap_from.store(message_id, "+FLAGS", [:Seen])
    end
    $count = $count + 1
  end
end

#  Check for new mails in folders and write result to file {{{2
def writefile()
    open($Mailfile1, 'w') do |f|
	    $Mailboxes.each do |a|
	      f.write( a[0] + $imap_to.status("INBOX." + a[1], "UNSEEN")["UNSEEN"].to_s + "\n" )
	    end
    end
    puts "Written: #{$Mailfile1}"
    # Copy file to another file to ensure no blinking in Conky
    # Read the file from Conky to display new email in each folder
    FileUtils.cp($Mailfile1, $Mailfile2)
    puts "Copied:  #{$Mailfile2}"
end

# Log into the target (local) IMAP server {{{1
begin
  $imap_to = Net::IMAP.new($Localserver[0], port="143")
  $imap_to.login($Localserver[1], $Localserver[2])
  $imap_to.select("INBOX")
  begin
    FileUtils.rm(".mail.fail")
  rescue
  end
  puts "Success: Login to local IMAP server"
rescue
  open($Mailfile1, 'w') do |f|
    $Mailboxes.each do |a|
      f.write( a[0] + "X\n" )
    end
  end
  FileUtils.cp($Mailfile1,$Mailfile2)
  puts "Login to local IMAP server failed"
  # Create file to flag a failed login
  FileUtils.touch(".mail.fail")
  # Unlock before exit
  FileUtils.rm(".mail.lock")
  exit
end

# Log into each "from"-server, fetch, filter and log out from each {{{1
$Mailserver.each do |ms|
  begin
    # Login
    puts "Trying:  Login to #{ms[0][1]}"
    $imap_from = Net::IMAP.new(ms[0][0], port="993", usessl="true")
    $imap_from.login(ms[0][1], ms[0][2])
    $imap_from.select("INBOX")
    puts "Success: Login to #{ms[0][1]}"
    # Filter mails
    ms[1].each do |m|
      matching( m[0], m[1], m[2], m[3] )
    end
    # Expunge mails that are set to be deleted and then disconnect
    $imap_from.expunge
    $imap_from.disconnect
    puts "Success: Filter and Disconnect from #{ms[0][1]}"
  rescue
    puts "Failed: Login to #{ms[0][1]}"
    # Create file to flag a failed login
    FileUtils.touch(".mail.fail")
  end
end

# Write mailbox status to file {{{1
#  Makes it possible for Conky to show number of mails in mailboxes
writefile()

# Disconnect from target server & display number of mails filtered, delete, unlock {{{1
begin
  $imap_to.disconnect
rescue
end

# Run "notmuch new" for indexing new mails 
# and remove the possibly created "dead.letter" file
system('notmuch new') if $count > 0
begin
  FileUtils.rm($Deadfile)
rescue
end
puts "#{$count} mails filtered"

# Finally unlock
begin
	FileUtils.rm(".mail.lock")
rescue
end

# Modeline {{{1
# vim: set foldmethod=marker:

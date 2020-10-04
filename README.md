# mailfetch
Collect mail from various accounts, filter and store locally


## WHY?

Beacuse you have several imap mail accounts and would like to retreive mail to
local folders so you can read and handle email faster and more convenient.


## WHAT?

mailfetch is a system for retreiving mail from different remote imap accounts,
filtering the mail according to the rules you set up and storing the mail into
local imap folders.


## HOW?

Simply put the file "mail_fetch.rb" into a folder in your defined PATH. Rename
the file "mail.conf" to ".mail.conf" and "mail.pw" to ".mail.pw". Put the files
into your home directory.  Edit the file ".mail.conf" to include the path to
the files ".mail" and ".mail2" as well as to the possibly created file
"dead.letter". Add your remote servers with imap url and username - but do not
put your passwords into ".mail.conf".  The passwords are instead entered into
the file named ",mail.pw". Ensure this file is seen only by you 
(do "chmod 700 .mail.pw").

Add filter rules to each remote server so that mail_fetch.rb knows where to
deliver the retreived mail. Just follow the examples in the files, and you'll
be fine.

You need to have Ruby installed to run mail_fetch.rb.

My "conkyrc" is included as an example of how you can get visual notice of the
mail_fetch running, network being unreachable, inability to login to local imap 
or remote servers and new mail count for the mail folders you decide to keep a 
tab on.

For more conky magic, check [my conky bar setup](https://github.com/isene/conky).


## WHEN?

Add an entry as a cron job using "crontab -e" that lookes like this:

* * * * * /home/yourusername/bin/mail_fetch.rb >/dev/null 2>&1


## WHO?

Copyright 2017, Geir Isene. Released under the GPL v. 3, Version 1.1 (2012-09-30), http://isene.com

require 'pg'
require 'net/imap'
require 'erb'
require_relative './Database'

module Mailmon

    class MailItem

        attr_reader :uid
        attr_reader :sender
        attr_reader :subject
        attr_reader :sent_at

        def initialize(uid, sender, subject, sent_at)
            @uid, @sender, @subject, @sent_at = 
                uid, sender, subject, sent_at
        end

    end

    class Mailbox

        attr_reader :id
        attr_reader :name
        attr_reader :address
        attr_reader :last_uid

        def initialize(id, name, address, password, server, port, use_tls, last_uid)
            @id, @name, @address, @password, @server, @port, @use_tls, @last_uid = 
              id, name, address, password, server, port, use_tls, last_uid
        end

        def get_unread 

            yesterday = Date.today.prev_day.strftime('%d-%b-%Y')

            imap = Net::IMAP.new @server, @port, @use_tls
            imap.login @address, @password

            imap.examine 'INBOX'

            unread = []
            messages = (imap.uid_search "SINCE #{yesterday}").select { |uid| uid > @last_uid }

            if !messages.empty?
                imap.uid_fetch(messages, 'ENVELOPE').each do |env|
                    uid = env.attr['UID']
                    eattr = env.attr['ENVELOPE']
                    sender = "#{eattr.from[0].mailbox}@#{eattr.from[0].host}"
                    subject = eattr.subject
                    sent_at = Date.parse eattr.date
                    unread << MailItem.new(uid, sender, subject, sent_at)
                    @last_uid = uid if uid > @last_uid
                end
            end
            
            imap.disconnect

            return unread

        end

    end

    class Monitor

        def run

            db = Database.new

            schedules = db.get_schedules

            schedules.each do |sch|

                puts "Checking mailbox '#{sch['name']}'"

                mailbox = Mailbox.new \
                    sch['mailbox_id'].to_i,
                    sch['name'],
                    sch['address'],
                    sch['password'],
                    sch['server'],
                    sch['port'].to_i,
                    sch['use_tls'].downcase == 't',
                    sch['last_uid'].to_i

                
               msgs = mailbox.get_unread.select do |msg|
                   ( sch['subject_regex'] &&
                        msg.subject =~ Regexp.new(sch['subject_regex'], Regexp::IGNORECASE) ) ||
                   ( sch['sender_regex'] &&
                        msg.sender =~ Regexp.new(sch['sender_regex'], Regexp::IGNORECASE) ) 
               end

               msgs.each do |msg|
                   sender = msg.sender
                   subject = msg.subject
                   puts "From: #{sender} Subject: #{subject}"
                   if sch['type'].downcase == 'speech'
                       erb = ERB.new sch['text'].gsub('"','\"')
                       system "nohup espeak \"#{erb.result binding}\" &"
                   elsif sch['type'].downcase == 'file'
                       system "nohup mpg321 \"#{sch['text']}\" &"
                   end
               end

               db.set_last_uid mailbox.id, mailbox.last_uid

            end

        end

    end

end

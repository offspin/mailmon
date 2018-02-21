require 'pg'
module Mailmon

    class Database

        attr_accessor :connection

        def initialize
            @connection = self.class.connect
        end
        
        def self.connect
            db = PG::Connection.new :dbname => 'mailmon'
        end

        def get_schedules

            sql = <<-EOS
                select mbx.id as mailbox_id
                     , mbx.name
                     , mbx.address
                     , mbx.password
                     , mbx.server
                     , mbx.port
                     , mbx.use_tls
                     , mbx.last_uid
                     , snd.type
                     , case lower(snd.type)
                         when 'file' then sloc.string_value || '/' 
                         else ''
                       end || snd.text as text
                     , sch.sender_regex
                     , sch.subject_regex
                  from schedule sch
                    inner join mailbox mbx 
                      on sch.mailbox_id = mbx.id
                    inner join sound snd 
                      on sch.sound_id = snd.id
                    cross join system_config sloc
                    cross join system_config mons
                 where current_timestamp::time between sch.run_from and sch.run_to
                   and sloc.name = 'sounds_location'
                   and mons.name = 'monitoring' and mons.string_value = 'on';
            EOS

            res = (@connection.exec sql).to_a

        end

        def set_last_uid mailbox_id, last_uid

            sql = <<-EOS
                update mailbox
                   set last_uid = $1
                 where id = $2;
            EOS

            @connection.exec sql, [last_uid, mailbox_id]

        end

        def set_monitoring state

            sql = <<-EOS
                update system_config
                   set string_value = $1
                 where name = 'monitoring';
            EOS

            @connection.exec sql, [state.downcase]

        end

    end

end

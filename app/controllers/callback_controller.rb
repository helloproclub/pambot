class CallbackController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:index]

  def root
    render plain: 'Pambot'
  end

  def index
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature body, signature
      render plain: 'Bad Request', status: :bad_request
      return
    end

    logger.info "Request body: #{body}"

    events = client.parse_events_from body
    events.each do |event|
      @event = event

      case event
      when Line::Bot::Event::Follow
        logger.info "Followed by user with ID: #{current_id}"

        msg = <<~MSG
          Beep... beep...

          Halo! Pambot adalah personal assistant bot yang dibuat khusus anggota Proclub.
          Kalau kamu bukan anggota dari grup PROCLUB di LINE maka kamu tidak akan dapat menggunakan bot ini~

          Proclub
          Dream. Think. Code. Win.

          #2019ProclubAllOut
        MSG

        reply ({
          type: 'text',
          text: msg.rstrip!,
        })
      when Line::Bot::Event::Unfollow
        logger.info "Unfollowed by user with ID: #{current_id}"
      when Line::Bot::Event::Join
        logger.info "Joined a chat with source ID: #{current_id}"

        msg = 'Memberikan anggota izin akses menggunakan Pambot... '

        if not granted? current_id
          msg += "gagal.\n\nGrup/room ini tidak diberikan izin.\n"
          msg += 'Sebaiknya aku keluar deh...'

          reply ({
            type: 'text',
            text: msg,
          })

          leave_group! if is_group?
          leave_room! if is_room?
          return
        end

        msg += "pending.\n\n"
				msg += 'LINE udah ga support ini lagi. '
				msg += 'Ku tambahin izinnya ketika kamu ngirim pesan di grup/room ini '
        msg += 'aja deh'

				reply ({
					type: 'text',
					text: msg,
				})
      when Line::Bot::Event::Message
        logger.info "Got a message from #{current_id}"

        if not is_user? and not granted? current_id
          reply ({
            type: 'text',
            text: 'Ah, aku gadiizinin buat di sini. Aku keluar aja deh...',
          })

          leave_group! if is_group?
          leave_room! if is_room?
        end

        if is_user?
          granted_members = []
          if not granted_members.include? current_id
            reply ({
              type: 'text',
              text: 'Kamu gadapet izin buat make bot ini...',
            })
            return
          end

          case event.type
          when Line::Bot::Event::MessageType::Text
            reply ({
              type: 'text',
              text: 'Tunggu bentar ya, masih lagi nyoba nambahin fitur baru',
            })
          end
        else
          member = Member.find_by(line_user_id: user_id)
          if not member.present?
            member = Member.new line_user_id: user_id
            if member.save
              logger.info "Success to registering #{user_id}"
            else
              logger.info "Failed to registering #{user_id}"
            end
          end
        end
      end
    end
  end
end

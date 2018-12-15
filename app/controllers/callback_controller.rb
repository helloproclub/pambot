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

        if not granted?
          client.leave_group(current_id) if is_group?
          client.leave_room(current_id) if is_room?
        end

        members = []
        members = client.get_group_member_ids if is_group?
        members = client.get_room_member_ids if is_room?

        logger.info "Members: #{members}"
      when Line::Bot::Event::Message
        logger.info "Got a message from #{current_id}"

        case event.type
        when Line::Bot::Event::MessageType::Text
          reply ({
            type: 'text',
            text: event.message['text'],
          })
        end
      end
    end
  end
end

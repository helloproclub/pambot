module Line
	module Bot
		class Authorized < Line::Bot::Request
			def authorized_header
				header = {
					'Content-Type' => 'application/json; charset=UTF-8',
					'User-Agent' => "LINE-BotSDK-Ruby/#{Line::Bot::API::VERSION}",
					'Authorization' => "Bearer #{ENV['LINE_CHANNEL_TOKEN']}"
				}
        hash = credentials.inject({}) { |h, (k, v)| h[k] = v.to_s; h }

				header.merge hash
			end

			def authorized_get
				assert_for_getting_message
				httpclient.get(endpoint + endpoint_path, authorized_header)
			end
		end
	end
end

module Line
  module Bot
    class Exclusive < Line::Bot::Client
      def get_group_member_ids group_id, continuation_token = nil
        endpoint_path = "/bot/group/#{group_id}/members/ids"
        endpoint_path += "?start=#{continuation_token}" if continuation_token

        authorized_get endpoint_path
      end

      def get_room_member_ids room_id, continuation_token = nil 
        endpoint_path = "/bot/room/#{room_id}/members/ids"
        endpoint_path += "?start=#{continuation_token}" if continuation_token

				authorized_get endpoint_path
      end

			def authorized_get endpoint_path
				raise Line::Bot::API::InvalidCredentialsError, 'Invalidates credentials' unless credentials?

				request = Authorized.new do |config|
					config.httpclient     = httpclient
					config.endpoint       = endpoint
					config.endpoint_path  = endpoint_path
					config.credentials    = credentials
				end

				request.authorized_get
			end
    end
  end
end

class ApplicationController < ActionController::Base
  protected

  attr_accessor :event

  def client
    @client ||= Line::Bot::Client.new do |config|
      config.channel_secret = ENV['LINE_CHANNEL_SECRET']
      config.channel_token = ENV['LINE_CHANNEL_TOKEN']
    end
  end

	def exclusive
		@exclusive ||= Line::Bot::Exclusive.new do |config|
			config.channel_secret = ENV['LINE_CHANNEL_SECRET']
			config.channel_token = ENV['LINE_CHANNEL_TOKEN']
		end
	end

  def grants
    [
      ENV['PAMBOT_STAGGING_ID'],
      ENV['PAMBOT_PROCLUB_ID'],
    ]
  end

  def granted? current_id
    grants.include? current_id
  end

  def is_group?
    @event['source']['type'] == 'group'
  end

  def is_room?
    @event['source']['type'] == 'room'
  end

  def is_user?
    @event['source']['type'] == 'user'
  end

  def current_id
    ret = nil
    ret = @event['source']['groupId'] if is_group?
    ret = @event['source']['roomId'] if is_room?
    ret = @event['source']['userId'] if is_user?

    ret
  end

  def reply message
    client.reply_message @event['replyToken'], message
  end

  def get_member_ids
    ret = []
    ret = exclusive.get_group_member_ids(current_id) if is_group?
    ret = exculisve.get_room_member_ids(current_id) if is_room?

    ret
  end

  def leave_group!
    client.leave_group current_id
  end

  def leave_room!
    client.leave_room current_id
  end
end

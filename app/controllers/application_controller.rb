class ApplicationController < ActionController::Base
  protected

  attr_accessor :event

  def client
    @client ||= Line::Bot::Client.new do |config|
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
    ret = client.get_group_member_ids(current_id) if is_group?
    ret = client.get_room_member_ids(current_id) if is_room?

    ret
  end

  def leave_group!
    client.leave_group current_id
  end

  def leave_room!
    client.leave_room current_id
  end
end

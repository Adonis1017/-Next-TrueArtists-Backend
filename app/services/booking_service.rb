class BookingService
  attr_accessor :params

  def initialize(params = {})
    @params = params
  end

  def call
    message = MessageService.new(
      message_id: params[:message_id],
      receiver_id: params[:receiver_id],
      sender_id: params[:sender_id]
    ).call

    if message && message.success?
      booking = Booking.new(params)
      booking.message_id = message.payload.id
      if booking.save
        OpenStruct.new({ success?: true, payload: booking })
      else
        handle_error(booking.errors.full_messages)
      end
    else
      handle_error(message&.error)
    end
  end

  private

  def handle_error(error)
    OpenStruct.new({ success?: false, errors: error })
  end
end

Spree::CheckoutController.class_eval do
  unless Rails.application.config.consider_all_requests_local
    rescue_from ::Cielo::PaymentError, :with => :handle_cielo_error
  end

  def update
    if @order.update_attributes(object_params)
      fire_event('spree.checkout.update')

      unless @order.next
        flash[:error] = @order.errors[:base].join("\n")
        redirect_to checkout_state_path(@order.state) and return
      end

      if @order.completed? and @order.payments.last.payment_method.class == Spree::PaymentMethod::CieloRegularMethod && !@order.paid?
        redirect_to @order.payments.last.source.authentication_url
      elsif @order.completed?
        session[:order_id] = nil
        flash.notice = Spree.t(:order_processed_successfully)
        flash[:commerce_tracking] = "nothing special"
        redirect_to completion_route
      else
        redirect_to checkout_state_path(@order.state)
      end
    else
      render :edit
    end
  end

  private
    def handle_cielo_error(e)
      flash[:error] = e.model_errors
      redirect_to checkout_state_path(:payment)
    end
end
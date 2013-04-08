class Spree::CieloController < Spree::BaseController

  def reauthenticate
    payment = Spree::Payment.by_order(params[:payment_id], params[:order_number]).first
    if payment
      payment.state = "pending" #handles already failed payments
      payment.save
      source = payment.source
      source.authentication_url = nil
      source.process! payment
      redirect_to source.authentication_url
    else
      redirect_to root_path, :alert => t(:order_not_found)
    end
  end
  
  def verify
    payment = Spree::Payment.by_order(params[:payment_id], params[:order_number]).first
    if payment
      payment.source.verify payment
      if payment.reload.completed?
        flash[:commerce_tracking] = "true"
        redirect_to order_path(payment.order), :notice => t(:order_processed_successfully)
      else
        handle_unconfirmed_payment
        redirect_to order_path(payment.order), :alert => t(:payment_not_identified)
      end
    else
      redirect_to root_path, :alert => t(:order_not_found)
    end
  end

  private
    # Trigger to handle unconfirmed status from cielo.
    # Can be used to schedule another verification in a few minutes.
    def handle_unconfirmed_payment;end;
end
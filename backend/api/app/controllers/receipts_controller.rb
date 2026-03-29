class ReceiptsController < ApplicationController
  before_action :authenticate_user!

  def create
    chave = Receipt.chave_from_source_url(receipt_params[:source_url].to_s)
    if chave.present? && Receipt.exists?(chave_acesso: chave)
      return render json: { error: "Receipt already registered", chave_acesso: chave }, status: :conflict
    end

    receipt = current_user.receipts.build(
      receipt_params.merge(status: "queued", chave_acesso: chave.presence)
    )

    begin
      if receipt.save
        ProcessReceiptJob.perform_later(receipt.id)
        render json: {
          id: receipt.id,
          status: receipt.status,
          message: "Receipt received and queued for processing."
        }, status: :accepted
      else
        render json: { errors: receipt.errors.full_messages }, status: :bad_request
      end
    rescue ActiveRecord::RecordNotUnique
      raise unless chave.present?

      render json: { error: "Receipt already registered", chave_acesso: chave }, status: :conflict
    end
  end

  private

  def receipt_params
    params.permit(:source_url)
  end
end

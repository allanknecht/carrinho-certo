class ReceiptsController < ApplicationController
  before_action :authenticate_user!

  def create
    chave = Receipt.chave_from_source_url(receipt_params[:source_url].to_s)
    if chave.present? && Receipt.exists?(chave_acesso: chave)
      return render json: { error: "Nota já cadastrada", chave_acesso: chave }, status: :conflict
    end

    receipt = current_user.receipts.build(receipt_params.merge(status: "queued"))
    if receipt.save
      ProcessReceiptJob.perform_later(receipt.id)
      render json: {
        id: receipt.id,
        status: receipt.status,
        message: "Nota recebida e enfileirada para processamento."
      }, status: :accepted
    else
      render json: { errors: receipt.errors.full_messages }, status: :bad_request
    end
  end

  private

  def receipt_params
    params.permit(:source_url)
  end
end

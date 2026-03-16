class ReceiptsController < ApplicationController
  def create
    receipt = Receipt.create!(
      source_url: receipt_params[:source_url],
      status: "queued"
    )

    render json: {
      id: receipt.id,
      status: receipt.status,
      message: "Nota recebida e enfileirada para processamento."
    }, status: :accepted
  end

  private

  def receipt_params
    params.require(:receipt).permit(:source_url)
  end
end

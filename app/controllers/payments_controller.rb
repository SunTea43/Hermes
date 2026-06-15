class PaymentsController < ApplicationController
  before_action :set_payment, only: %i[ show edit update destroy ]

  # GET /payments or /payments.json
  def index
    @payments = policy_scope(Payment)
  end

  # GET /payments/1 or /payments/1.json
  def show
    authorize @payment
  end

  # GET /payments/new
  def new
    @payment = Payment.new
    authorize @payment
  end

  # GET /payments/1/edit
  def edit
    authorize @payment
  end

  # POST /payments or /payments.json
  def create
    @payment = Payment.new(payment_params)
    authorize @payment

    respond_to do |format|
      if @payment.save
        format.html { redirect_to @payment, notice: "Payment was successfully created." }
        format.json { render :show, status: :created, location: @payment }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @payment.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /payments/1 or /payments/1.json
  def update
    authorize @payment

    respond_to do |format|
      if @payment.update(payment_params)
        format.html { redirect_to @payment, notice: "Payment was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @payment }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @payment.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /payments/1 or /payments/1.json
  def destroy
    authorize @payment
    @payment.destroy!

    respond_to do |format|
      format.html { redirect_to payments_path, notice: "Payment was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_payment
      @payment = Payment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def payment_params
      params.expect(payment: [ :sales_order_id, :amount, :paid_at, :payment_method, :payment_type, :payment_status, :recorded_by_id, :notes ])
    end
end

class SalesOrdersController < ApplicationController
  before_action :set_sales_order, only: %i[ show edit update destroy ]

  # GET /sales_orders or /sales_orders.json
  def index
    @sales_orders = SalesOrder.all
  end

  # GET /sales_orders/1 or /sales_orders/1.json
  def show
  end

  # GET /sales_orders/new
  def new
    @sales_order = SalesOrder.new
  end

  # GET /sales_orders/1/edit
  def edit
  end

  # POST /sales_orders or /sales_orders.json
  def create
    @sales_order = SalesOrder.new(sales_order_params)

    respond_to do |format|
      if @sales_order.save
        format.html { redirect_to @sales_order, notice: "Sales order was successfully created." }
        format.json { render :show, status: :created, location: @sales_order }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @sales_order.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /sales_orders/1 or /sales_orders/1.json
  def update
    respond_to do |format|
      if @sales_order.update(sales_order_params)
        format.html { redirect_to @sales_order, notice: "Sales order was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @sales_order }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @sales_order.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /sales_orders/1 or /sales_orders/1.json
  def destroy
    @sales_order.destroy!

    respond_to do |format|
      format.html { redirect_to sales_orders_path, notice: "Sales order was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sales_order
      @sales_order = SalesOrder.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def sales_order_params
      params.expect(sales_order: [ :business_id, :reference_number, :created_by_id, :customer_name, :customer_identifier, :payment_condition, :payment_status, :payment_due_at, :total, :notes ])
    end
end

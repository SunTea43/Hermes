class PurchaseOrdersController < ApplicationController
  before_action :set_purchase_order, only: %i[ show edit update destroy ]

  # GET /purchase_orders or /purchase_orders.json
  def index
    @purchase_orders = policy_scope(PurchaseOrder)
  end

  # GET /purchase_orders/1 or /purchase_orders/1.json
  def show
    authorize @purchase_order
  end

  # GET /purchase_orders/new
  def new
    @purchase_order = PurchaseOrder.new
    @purchase_order.purchase_order_items.build
    authorize @purchase_order
  end

  # GET /purchase_orders/1/edit
  def edit
    authorize @purchase_order
  end

  # POST /purchase_orders or /purchase_orders.json
  def create
    @purchase_order = PurchaseOrder.new(purchase_order_params)
    authorize @purchase_order

    respond_to do |format|
      if @purchase_order.save
        format.html { redirect_to @purchase_order, notice: "Purchase order was successfully created." }
        format.json { render :show, status: :created, location: @purchase_order }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @purchase_order.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /purchase_orders/1 or /purchase_orders/1.json
  def update
    authorize @purchase_order

    respond_to do |format|
      if @purchase_order.update(purchase_order_params)
        format.html { redirect_to @purchase_order, notice: "Purchase order was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @purchase_order }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @purchase_order.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /purchase_orders/1 or /purchase_orders/1.json
  def destroy
    authorize @purchase_order
    @purchase_order.destroy!

    respond_to do |format|
      format.html { redirect_to purchase_orders_path, notice: "Purchase order was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_purchase_order
      @purchase_order = PurchaseOrder.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def purchase_order_params
      params.expect(purchase_order: [ :business_id, :reference_number, :created_by_id, :supplier_name, :status, :received_at, :notes,
        purchase_order_items_attributes: [ :id, :product_id, :quantity, :unit_price, :notes, :_destroy ] ])
    end
end

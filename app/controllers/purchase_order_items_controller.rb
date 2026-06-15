class PurchaseOrderItemsController < ApplicationController
  before_action :set_purchase_order_item, only: %i[ show edit update destroy ]

  # GET /purchase_order_items or /purchase_order_items.json
  def index
    @purchase_order_items = PurchaseOrderItem.all
  end

  # GET /purchase_order_items/1 or /purchase_order_items/1.json
  def show
  end

  # GET /purchase_order_items/new
  def new
    @purchase_order_item = PurchaseOrderItem.new
  end

  # GET /purchase_order_items/1/edit
  def edit
  end

  # POST /purchase_order_items or /purchase_order_items.json
  def create
    @purchase_order_item = PurchaseOrderItem.new(purchase_order_item_params)

    respond_to do |format|
      if @purchase_order_item.save
        format.html { redirect_to @purchase_order_item, notice: "Purchase order item was successfully created." }
        format.json { render :show, status: :created, location: @purchase_order_item }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @purchase_order_item.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /purchase_order_items/1 or /purchase_order_items/1.json
  def update
    respond_to do |format|
      if @purchase_order_item.update(purchase_order_item_params)
        format.html { redirect_to @purchase_order_item, notice: "Purchase order item was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @purchase_order_item }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @purchase_order_item.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /purchase_order_items/1 or /purchase_order_items/1.json
  def destroy
    @purchase_order_item.destroy!

    respond_to do |format|
      format.html { redirect_to purchase_order_items_path, notice: "Purchase order item was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_purchase_order_item
      @purchase_order_item = PurchaseOrderItem.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def purchase_order_item_params
      params.expect(purchase_order_item: [ :purchase_order_id, :product_id, :quantity, :unit_price, :subtotal, :notes ])
    end
end

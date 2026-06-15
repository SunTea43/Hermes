class SalesOrderItemsController < ApplicationController
  before_action :set_sales_order_item, only: %i[ show edit update destroy ]

  # GET /sales_order_items or /sales_order_items.json
  def index
    @sales_order_items = policy_scope(SalesOrderItem)
  end

  # GET /sales_order_items/1 or /sales_order_items/1.json
  def show
    authorize @sales_order_item
  end

  # GET /sales_order_items/new
  def new
    @sales_order_item = SalesOrderItem.new
    authorize @sales_order_item
  end

  # GET /sales_order_items/1/edit
  def edit
    authorize @sales_order_item
  end

  # POST /sales_order_items or /sales_order_items.json
  def create
    @sales_order_item = SalesOrderItem.new(sales_order_item_params)
    authorize @sales_order_item

    respond_to do |format|
      if @sales_order_item.save
        format.html { redirect_to @sales_order_item, notice: "Sales order item was successfully created." }
        format.json { render :show, status: :created, location: @sales_order_item }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @sales_order_item.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /sales_order_items/1 or /sales_order_items/1.json
  def update
    authorize @sales_order_item

    respond_to do |format|
      if @sales_order_item.update(sales_order_item_params)
        format.html { redirect_to @sales_order_item, notice: "Sales order item was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @sales_order_item }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @sales_order_item.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /sales_order_items/1 or /sales_order_items/1.json
  def destroy
    authorize @sales_order_item
    @sales_order_item.destroy!

    respond_to do |format|
      format.html { redirect_to sales_order_items_path, notice: "Sales order item was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sales_order_item
      @sales_order_item = SalesOrderItem.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def sales_order_item_params
      params.expect(sales_order_item: [ :sales_order_id, :product_id, :quantity, :unit_price, :discount, :subtotal ])
    end
end

class ProductPricesController < ApplicationController
  before_action :set_product_price, only: %i[ show edit update destroy ]

  # GET /product_prices or /product_prices.json
  def index
    @product_prices = policy_scope(ProductPrice)
  end

  # GET /product_prices/1 or /product_prices/1.json
  def show
    authorize @product_price
  end

  # GET /product_prices/new
  def new
    @product_price = ProductPrice.new
    authorize @product_price
  end

  # GET /product_prices/1/edit
  def edit
    authorize @product_price
  end

  # POST /product_prices or /product_prices.json
  def create
    @product_price = ProductPrice.new(product_price_params)
    authorize @product_price

    respond_to do |format|
      if @product_price.save
        format.html { redirect_to @product_price, notice: "Product price was successfully created." }
        format.json { render :show, status: :created, location: @product_price }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @product_price.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /product_prices/1 or /product_prices/1.json
  def update
    authorize @product_price

    respond_to do |format|
      if @product_price.update(product_price_params)
        format.html { redirect_to @product_price, notice: "Product price was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @product_price }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @product_price.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /product_prices/1 or /product_prices/1.json
  def destroy
    authorize @product_price
    @product_price.destroy!

    respond_to do |format|
      format.html { redirect_to product_prices_path, notice: "Product price was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product_price
      @product_price = ProductPrice.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def product_price_params
      params.expect(product_price: [ :product_id, :unit_price, :price_type, :start_at, :end_at, :note ])
    end
end

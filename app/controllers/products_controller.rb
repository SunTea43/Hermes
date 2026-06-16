class ProductsController < ApplicationController
  before_action :set_product, only: %i[ show edit update destroy ]

  # GET /products or /products.json
  def index
    @products = policy_scope(Product)
  end

  # GET /products/import
  def import_form
    authorize Product.new, :create?
  end

  # POST /products/import
  def import
    authorize Product.new, :create?

    unless params[:file].present?
      redirect_to import_form_products_path, alert: "Debes seleccionar un archivo."
      return
    end

    business = Business.find(params[:business_id])
    result   = Products::ImportService.new(params[:file], business: business, user: current_user).call

    if result.success?
      redirect_to products_path, notice: "#{result.imported} producto(s) importado(s) exitosamente."
    else
      @import_errors = result.errors
      @imported      = result.imported
      render :import_form, status: :unprocessable_content
    end
  end

  # GET /products/template
  def download_template
    authorize Product.new, :create?

    headers["Content-Disposition"] = 'attachment; filename="plantilla_productos.csv"'
    headers["Content-Type"] = "text/csv; charset=utf-8"

    csv = CSV.generate(headers: true) do |csv|
      csv << [ "nombre", "descripcion", "unidad_medida", "precio_venta", "precio_compra", "stock_inicial", "stock_minimo" ]
      csv << [ "Arroz", "Arroz blanco corriente", "kg", 2800, 2200, 100, 20 ]
      csv << [ "Aceite", "Aceite vegetal 1L", "lt", 7500, 6000, 40, 10 ]
    end

    render plain: csv
  end

  # GET /products/1 or /products/1.json
  def show
    authorize @product
  end

  # GET /products/new
  def new
    @product = Product.new
    authorize @product
  end

  # GET /products/1/edit
  def edit
    authorize @product
  end

  # POST /products or /products.json
  def create
    @product = Product.new(product_params)
    authorize @product

    respond_to do |format|
      if @product.save
        format.html { redirect_to @product, notice: "Product was successfully created." }
        format.json { render :show, status: :created, location: @product }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @product.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /products/1 or /products/1.json
  def update
    authorize @product

    respond_to do |format|
      if @product.update(product_params)
        format.html { redirect_to @product, notice: "Product was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @product.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /products/1 or /products/1.json
  def destroy
    authorize @product
    @product.destroy!

    respond_to do |format|
      format.html { redirect_to products_path, notice: "Product was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def product_params
      params.expect(product: [ :business_id, :name, :description, :unit_measure, :status ])
    end
end

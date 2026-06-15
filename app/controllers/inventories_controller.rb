class InventoriesController < ApplicationController
  before_action :set_inventory, only: %i[ show edit update destroy ]

  # GET /inventories or /inventories.json
  def index
    @inventories = policy_scope(Inventory)
  end

  # GET /inventories/1 or /inventories/1.json
  def show
    authorize @inventory
  end

  # GET /inventories/new
  def new
    @inventory = Inventory.new
    authorize @inventory
  end

  # GET /inventories/1/edit
  def edit
    authorize @inventory
  end

  # POST /inventories or /inventories.json
  def create
    @inventory = Inventory.new(inventory_params)
    authorize @inventory

    respond_to do |format|
      if @inventory.save
        format.html { redirect_to @inventory, notice: "Inventory was successfully created." }
        format.json { render :show, status: :created, location: @inventory }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @inventory.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /inventories/1 or /inventories/1.json
  def update
    authorize @inventory

    respond_to do |format|
      if @inventory.update(inventory_params)
        format.html { redirect_to @inventory, notice: "Inventory was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @inventory }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @inventory.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /inventories/1 or /inventories/1.json
  def destroy
    authorize @inventory
    @inventory.destroy!

    respond_to do |format|
      format.html { redirect_to inventories_path, notice: "Inventory was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_inventory
      @inventory = Inventory.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def inventory_params
      params.expect(inventory: [ :business_id, :product_id, :current_quantity, :minimum_alert_quantity, :last_updated_at ])
    end
end

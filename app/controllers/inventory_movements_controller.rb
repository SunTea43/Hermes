class InventoryMovementsController < ApplicationController
  before_action :set_inventory_movement, only: %i[ show edit update destroy ]

  # GET /inventory_movements or /inventory_movements.json
  def index
    @inventory_movements = InventoryMovement.all
  end

  # GET /inventory_movements/1 or /inventory_movements/1.json
  def show
  end

  # GET /inventory_movements/new
  def new
    @inventory_movement = InventoryMovement.new
  end

  # GET /inventory_movements/1/edit
  def edit
  end

  # POST /inventory_movements or /inventory_movements.json
  def create
    @inventory_movement = InventoryMovement.new(inventory_movement_params)

    respond_to do |format|
      if @inventory_movement.save
        format.html { redirect_to @inventory_movement, notice: "Inventory movement was successfully created." }
        format.json { render :show, status: :created, location: @inventory_movement }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @inventory_movement.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /inventory_movements/1 or /inventory_movements/1.json
  def update
    respond_to do |format|
      if @inventory_movement.update(inventory_movement_params)
        format.html { redirect_to @inventory_movement, notice: "Inventory movement was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @inventory_movement }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @inventory_movement.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /inventory_movements/1 or /inventory_movements/1.json
  def destroy
    @inventory_movement.destroy!

    respond_to do |format|
      format.html { redirect_to inventory_movements_path, notice: "Inventory movement was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_inventory_movement
      @inventory_movement = InventoryMovement.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def inventory_movement_params
      params.expect(inventory_movement: [ :inventory_id, :previous_quantity, :new_quantity, :movement_type, :reference_type, :reference_id, :user_id, :moved_at, :notes ])
    end
end

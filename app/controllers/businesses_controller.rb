class BusinessesController < ApplicationController
  before_action :set_business, only: %i[ show edit update destroy ]

  # GET /businesses or /businesses.json
  def index
    @businesses = policy_scope(Business)
  end

  # GET /businesses/1 or /businesses/1.json
  def show
    authorize @business
  end

  # GET /businesses/new
  def new
    @business = Business.new
    authorize @business
  end

  # GET /businesses/1/edit
  def edit
    authorize @business
  end

  # POST /businesses or /businesses.json
  def create
    @business = Business.new(business_params)
    authorize @business

    respond_to do |format|
      if @business.save
        format.html { redirect_to @business, notice: "Business was successfully created." }
        format.json { render :show, status: :created, location: @business }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @business.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /businesses/1 or /businesses/1.json
  def update
    authorize @business

    respond_to do |format|
      if @business.update(business_params)
        format.html { redirect_to @business, notice: "Business was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @business }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @business.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /businesses/1 or /businesses/1.json
  def destroy
    authorize @business
    @business.destroy!

    respond_to do |format|
      format.html { redirect_to businesses_path, notice: "Business was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_business
      @business = Business.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def business_params
      params.expect(business: [ :name, :description, :currency, :owner_id, :whatsapp_enabled ])
    end
end

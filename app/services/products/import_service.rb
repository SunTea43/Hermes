require "roo"

module Products
  class ImportService < ApplicationService
    EXPECTED_HEADERS = %w[nombre descripcion unidad_medida precio_venta precio_compra stock_inicial stock_minimo].freeze

    Result = Struct.new(:imported, :errors, keyword_init: true) do
      def success? = errors.empty?
    end

    def initialize(file, business:, user:)
      @file     = file
      @business = business
      @user     = user
    end

    def call
      imported = 0
      errors   = []

      spreadsheet = open_spreadsheet
      headers     = spreadsheet.row(1).map { |h| h.to_s.strip.downcase.tr(" ", "_") }

      unless valid_headers?(headers)
        return Result.new(imported: 0, errors: [ "Encabezados inválidos. Se esperan: #{EXPECTED_HEADERS.join(', ')}" ])
      end

      (2..spreadsheet.last_row).each do |i|
        row = Hash[headers.zip(spreadsheet.row(i).map(&:to_s))]
        row_errors = import_row(row, row_number: i)

        if row_errors.empty?
          imported += 1
        else
          errors.concat(row_errors)
        end
      end

      Result.new(imported: imported, errors: errors)
    rescue Roo::HeaderRowNotFoundError, StandardError => e
      Result.new(imported: 0, errors: [ "Error al leer el archivo: #{e.message}" ])
    end

    private

    def open_spreadsheet
      path = @file.respond_to?(:path) ? @file.path : @file.to_s
      Roo::Spreadsheet.open(path)
    end

    def valid_headers?(headers)
      EXPECTED_HEADERS.all? { |h| headers.include?(h) }
    end

    def import_row(row, row_number:)
      errors = []
      name   = row["nombre"].to_s.strip

      if name.blank?
        errors << "Fila #{row_number}: el nombre es obligatorio"
        return errors
      end

      sale_price     = row["precio_venta"].to_s.gsub(/[^0-9.]/, "").to_f
      purchase_price = row["precio_compra"].to_s.gsub(/[^0-9.]/, "").to_f
      initial_stock  = row["stock_inicial"].to_s.to_f
      min_stock      = row["stock_minimo"].to_s.to_f

      ActiveRecord::Base.transaction do
        product = @business.products.find_or_initialize_by(name: name)
        product.assign_attributes(
          description:  row["descripcion"],
          unit_measure: row["unidad_medida"].presence || "und",
          status: "active"
        )

        unless product.save
          errors << "Fila #{row_number} (#{name}): #{product.errors.full_messages.join(', ')}"
          raise ActiveRecord::Rollback
        end

        if sale_price > 0
          product.product_prices.where(price_type: "sale", end_at: nil).update_all(end_at: Date.today - 1)
          product.product_prices.create!(price_type: "sale", unit_price: sale_price, start_at: Date.today)
        end

        if purchase_price > 0
          product.product_prices.where(price_type: "purchase", end_at: nil).update_all(end_at: Date.today - 1)
          product.product_prices.create!(price_type: "purchase", unit_price: purchase_price, start_at: Date.today)
        end

        inventory = Inventory.find_or_initialize_by(business: @business, product: product)
        inventory.assign_attributes(
          current_quantity: initial_stock,
          minimum_alert_quantity: min_stock,
          last_updated_at: Time.current
        )
        inventory.save!
      end

      errors
    rescue ActiveRecord::RecordInvalid => e
      [ "Fila #{row_number}: #{e.message}" ]
    end
  end
end

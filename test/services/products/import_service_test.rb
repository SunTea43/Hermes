require "test_helper"
require "tempfile"
require "csv"

class Products::ImportServiceTest < ActiveSupport::TestCase
  setup do
    @business = businesses(:one)
    @user     = users(:one)
  end

  test "imports products from valid CSV" do
    csv_file = build_csv([
      ["nombre", "descripcion", "unidad_medida", "precio_venta", "precio_compra", "stock_inicial", "stock_minimo"],
      ["Panela", "Panela redonda", "und", "3500", "2800", "30", "10"]
    ])

    assert_difference "Product.count" do
      result = Products::ImportService.new(csv_file, business: @business, user: @user).call
      assert result.success?, result.errors.inspect
      assert_equal 1, result.imported
    end
  ensure
    csv_file.close!
  end

  test "creates sale and purchase prices" do
    csv_file = build_csv([
      ["nombre", "descripcion", "unidad_medida", "precio_venta", "precio_compra", "stock_inicial", "stock_minimo"],
      ["Frijol", "Frijol rojo", "kg", "4000", "3200", "20", "5"]
    ])

    Products::ImportService.new(csv_file, business: @business, user: @user).call

    product = @business.products.find_by!(name: "Frijol")
    assert product.product_prices.where(price_type: "sale").exists?
    assert product.product_prices.where(price_type: "purchase").exists?
  ensure
    csv_file.close!
  end

  test "creates inventory with stock" do
    csv_file = build_csv([
      ["nombre", "descripcion", "unidad_medida", "precio_venta", "precio_compra", "stock_inicial", "stock_minimo"],
      ["Lentejas", "Lentejas verdes", "kg", "3000", "2400", "15", "5"]
    ])

    Products::ImportService.new(csv_file, business: @business, user: @user).call

    product = @business.products.find_by!(name: "Lentejas")
    assert_equal 15.0, product.inventory.current_quantity.to_f
    assert_equal 5.0,  product.inventory.minimum_alert_quantity.to_f
  ensure
    csv_file.close!
  end

  test "returns error for missing headers" do
    csv_file = build_csv([
      ["nombre", "descripcion"],
      ["Test", "desc"]
    ])

    result = Products::ImportService.new(csv_file, business: @business, user: @user).call
    assert_not result.success?
    assert result.errors.first.include?("Encabezados inválidos")
  ensure
    csv_file.close!
  end

  test "skips rows with blank name and reports error" do
    csv_file = build_csv([
      ["nombre", "descripcion", "unidad_medida", "precio_venta", "precio_compra", "stock_inicial", "stock_minimo"],
      ["", "sin nombre", "kg", "1000", "800", "10", "2"]
    ])

    result = Products::ImportService.new(csv_file, business: @business, user: @user).call
    assert result.errors.any?
    assert_equal 0, result.imported
  ensure
    csv_file.close!
  end

  private

  def build_csv(rows)
    file = Tempfile.new(["import_test", ".csv"])
    CSV.open(file.path, "w") { |csv| rows.each { |row| csv << row } }
    file
  end
end

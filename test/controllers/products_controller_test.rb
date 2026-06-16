require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @product = products(:one)
  end

  test "GET index returns success" do
    get products_url
    assert_response :success
  end

  test "GET show returns success" do
    get product_url(@product)
    assert_response :success
  end

  test "GET new returns success" do
    get new_product_url
    assert_response :success
  end

  test "GET edit returns success" do
    get edit_product_url(@product)
    assert_response :success
  end

  test "POST create with valid params creates product" do
    assert_difference "Product.count" do
      post products_url, params: {
        product: { business_id: businesses(:one).id, name: "Nuevo Producto", unit_measure: "kg", status: "active" }
      }
    end
    assert_redirected_to product_url(Product.last)
  end

  test "POST create with missing name renders new" do
    assert_no_difference "Product.count" do
      post products_url, params: {
        product: { business_id: businesses(:one).id, name: "", unit_measure: "kg", status: "active" }
      }
    end
    assert_response :unprocessable_content
  end

  test "PATCH update changes product attributes" do
    patch product_url(@product), params: {
      product: { name: "Arroz Actualizado" }
    }
    assert_redirected_to product_url(@product)
    assert_equal "Arroz Actualizado", @product.reload.name
  end

  test "DELETE destroy removes product" do
    assert_difference "Product.count", -1 do
      delete product_url(@product)
    end
    assert_redirected_to products_url
  end

  test "GET import_form returns success" do
    get import_form_products_url
    assert_response :success
  end

  test "GET download_template returns CSV" do
    get download_template_products_url
    assert_response :success
    assert_includes response.content_type, "text/csv"
  end
end

require "test_helper"

class BusinessesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @business = businesses(:one)
  end

  test "should get index" do
    get businesses_url
    assert_response :success
  end

  test "should get new" do
    get new_business_url
    assert_response :success
  end

  test "should create business" do
    assert_difference("Business.count") do
      post businesses_url, params: { business: { currency: @business.currency, description: @business.description, name: @business.name, owner_id: @business.owner_id } }
    end

    assert_redirected_to business_url(Business.last)
  end

  test "should show business" do
    get business_url(@business)
    assert_response :success
  end

  test "should get edit" do
    get edit_business_url(@business)
    assert_response :success
  end

  test "should update business" do
    patch business_url(@business), params: { business: { currency: @business.currency, description: @business.description, name: @business.name, owner_id: @business.owner_id } }
    assert_redirected_to business_url(@business)
  end

  test "should update whatsapp enabled setting" do
    patch business_url(@business), params: {
      business: {
        currency: @business.currency,
        description: @business.description,
        name: @business.name,
        owner_id: @business.owner_id,
        whatsapp_enabled: false
      }
    }

    assert_redirected_to business_url(@business)
    assert_not @business.reload.whatsapp_enabled?
  end

  test "should destroy business" do
    assert_difference("Business.count", -1) do
      delete business_url(@business)
    end

    assert_redirected_to businesses_url
  end

  test "should not create business with non-existent owner_id" do
    assert_no_difference("Business.count") do
      post businesses_url, params: { business: { name: "Test", currency: "COP", owner_id: 0 } }
    end

    assert_response :unprocessable_content
  end
end

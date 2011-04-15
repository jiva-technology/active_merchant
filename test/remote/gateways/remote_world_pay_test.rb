require File.dirname(__FILE__) + '/../../test_helper'

class RemoteWorldPayTest < Test::Unit::TestCase
  

  def setup
    @gateway = WorldPayGateway.new(fixtures(:world_pay))
    
    @amount = 100

    @threed_credit_card = CreditCard.new(
      :number               => '4484070000000000',
      :month                => 6,
      :year                 => next_year,
      :verification_value   => 123,
      :first_name           => '3D',
      :last_name            => '',
      :type                 => 'visa'
    )
    
    @options = { 
      :billing_address => { 
        :first_name   => 'Sam',
        :last_name    => 'Smith',
        :address1     => 'Flat 10 Lapwing Court',
        :zip          => 'M20 2PS',
        :city         => "Manchester",
        :country      => 'GB',
        :phone        => '01234567890'
      },
      :order_id       => generate_unique_id,
      :description    => 'Store purchase',
      :invoice        => '<p>something awesome</p>',
      :ip             => '86.150.65.37',
      :user_agent     => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.0.4) Gecko/2008102920 Firefox/3.0.4",
      :session_id     => generate_unique_id,
      :email          => 'jamie@kernowsoul.com'
    }
    
    # @declined_options[:billing_address][:name]  = "REFUSED"
    # @referred_options[:billing_address][:name]  = "REFERRED"
    # @fraud_options[:billing_address][:name]     = "FRAUD"
    # @error_options[:billing_address][:name]     = "ERROR"
  end
  
  def test_successful_purchase
    assert response = @gateway.purchase(@amount, @threed_credit_card, @options)
    assert response.success?
    assert_equal 'REPLACE WITH SUCCESS MESSAGE', response.message
  end

  # def test_unsuccessful_purchase
  #   assert response = @gateway.purchase(@amount, @credit_card, @options)
  #   assert_failure response
  #   assert_equal 'REPLACE WITH FAILED PURCHASE MESSAGE', response.message
  # end
  # 
  # def test_invalid_login
  #   gateway = WorldPayGateway.new(
  #               :login => '',
  #               :password => ''
  #             )
  #   assert response = gateway.purchase(@amount, @credit_card, @options)
  #   assert_failure response
  #   assert_equal 'REPLACE WITH FAILURE MESSAGE', response.message
  # end
  
  private

  def next_year
    Date.today.year + 1
  end
end

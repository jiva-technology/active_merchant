require File.dirname(__FILE__) + '/../../test_helper'

class RemoteWorldPayTest < Test::Unit::TestCase
  

  def setup
    @gateway  = WorldPayGateway.new(fixtures(:world_pay))
    @amount   = 100

    @amex_credit_card = CreditCard.new(
      :number               => '370000200000000',
      :month                => 6,
      :year                 => next_year,
      :verification_value   => 123,
      :first_name           => 'Sam',
      :last_name            => 'Smith',
      :type                 => 'american_express'
    )
    
    @refused_credit_card = CreditCard.new(
      :number               => '370000200000000',
      :month                => 6,
      :year                 => next_year,
      :verification_value   => 123,
      :first_name           => 'REFUSED',
      :last_name            => '',
      :type                 => 'american_express'
    )
    
    @referred_credit_card = CreditCard.new(
      :number               => '370000200000000',
      :month                => 6,
      :year                 => next_year,
      :verification_value   => 123,
      :first_name           => 'REFERRED',
      :last_name            => '',
      :type                 => 'american_express'
    )
    
    @fraud_credit_card = CreditCard.new(
      :number               => '370000200000000',
      :month                => 6,
      :year                 => next_year,
      :verification_value   => 123,
      :first_name           => 'FRAUD',
      :last_name            => '',
      :type                 => 'american_express'
    )
    
    @error_credit_card = CreditCard.new(
      :number               => '370000200000000',
      :month                => 6,
      :year                 => next_year,
      :verification_value   => 123,
      :first_name           => 'ERROR',
      :last_name            => '',
      :type                 => 'american_express'
    )

    @three_d_credit_card = CreditCard.new(
      :number               => '4484070000000000',
      :month                => 6,
      :year                 => next_year,
      :verification_value   => 123,
      :first_name           => '3D',
      :last_name            => '',
      :type                 => 'visa'
    )
    
    @invalid_credit_card = CreditCard.new(
      :number               => '4484070000000000',
      :month                => 6,
      :year                 => 1940,
      :verification_value   => 123,
      :first_name           => 'Sam',
      :last_name            => 'Smith',
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
      :email          => 'jamie@test.local'
    }
    
    @error_options = @options.merge({ :order_id => '<>' })
  end
  
  def test_successful_purchase
    assert response = @gateway.purchase(@amount, @amex_credit_card, @options)
    assert response.success?
    assert !response.three_d_secure?
    assert_equal 'AUTHORISED', response.message
  end
  
  def test_refused_purchase
    assert response = @gateway.purchase(@amount, @refused_credit_card, @options)
    assert !response.success?
    assert_equal 'REFUSED', response.message
  end
  
  def test_refferred_purchase
    assert response = @gateway.purchase(@amount, @referred_credit_card, @options)
    assert !response.success?
    assert_equal 'REFERRED', response.message
  end
  
  def test_fraud_purchase
    assert response = @gateway.purchase(@amount, @fraud_credit_card, @options)
    assert !response.success?
    assert_equal 'FRAUD SUSPICION', response.message
  end
  
  def test_error_purchase
    assert response = @gateway.purchase(@amount, @error_credit_card, @options)
    assert !response.success?
    assert_equal 'Gateway error', response.message
  end
  
  def test_successful_three_d_secure_purchase
    assert response = @gateway.purchase(@amount, @three_d_credit_card, @options)
    assert !response.success?
    assert response.three_d_secure?
    assert three_d_response = @gateway.three_d_complete(@amount, @three_d_credit_card, @options.merge({ :pa_res => 'IDENTIFIED', :md => response.md }))
    assert three_d_response.success?
    assert_equal 'AUTHORISED', three_d_response.message
  end
  
  def test_not_identified_three_d_secure_purchase
    assert response = @gateway.purchase(@amount, @three_d_credit_card, @options)
    assert !response.success?
    assert response.three_d_secure?
    assert three_d_response = @gateway.three_d_complete(@amount, @three_d_credit_card, @options.merge({ :pa_res => 'NOT_IDENTIFIED', :md => response.md }))
    assert three_d_response.success?
    assert_equal 'AUTHORISED', three_d_response.message
  end
  
  def test_unknown_identified_three_d_secure_purchase
    assert response = @gateway.purchase(@amount, @three_d_credit_card, @options)
    assert !response.success?
    assert response.three_d_secure?
    assert three_d_response = @gateway.three_d_complete(@amount, @three_d_credit_card, @options.merge({ :pa_res => 'UNKNOWN_IDENTITY', :md => response.md }))
    assert !three_d_response.success?
    assert_equal 'FRAUD SUSPICION', three_d_response.message
  end
  
  def test_gateway_error
    assert response = @gateway.purchase(@amount, @invalid_credit_card, @error_options)
    assert !response.success?
    assert_equal 'OrderCode contains illegal characters or is longer than 64 characters', response.message
  end
  
  def test_invalid_login
    gateway = WorldPayGateway.new(fixtures(:world_pay).merge(
      :login => '',
      :password => ''
    ))
    assert response = gateway.purchase(@amount, @amex_credit_card, @options)
    assert !response.success?
    assert_equal 'Failed with 401 Authorization Required', response.message
  end
  
  private

  def next_year
    Date.today.year + 1
  end
end

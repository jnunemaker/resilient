module CircuitBreakerInterfaceTest
  def test_responds_to_allow_request
    assert_respond_to @object, :allow_request?
  end

  def test_responds_to_mark_success
    assert_respond_to @object, :mark_success
  end

  def test_responds_to_mark_failure
    assert_respond_to @object, :mark_failure
  end

  def test_responds_to_reset
    assert_respond_to @object, :reset
  end
end

module RollingMetricsInterfaceTest
  def test_responds_to_mark_success
    assert_respond_to @object, :mark_success
  end

  def test_mark_success_returns_nothing
    assert_nil @object.mark_success
  end

  def test_responds_to_mark_failure
    assert_respond_to @object, :mark_failure
  end

  def test_mark_failure_returns_nothing
    assert_nil @object.mark_failure
  end

  def test_responds_to_successes
    assert_respond_to @object, :successes
  end

  def test_responds_to_failures
    assert_respond_to @object, :failures
  end

  def test_responds_to_requests
    assert_respond_to @object, :requests
  end

  def test_responds_to_error_percentage
    assert_respond_to @object, :error_percentage
  end

  def test_responds_to_reset
    assert_respond_to @object, :reset
  end

  def test_reset_returns_nothing
    assert_nil @object.reset
  end
end

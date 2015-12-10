module MetricsStorageInterfaceTest
  def test_responds_to_increment
    assert_respond_to @object, :increment
  end

  def test_responds_to_get
    assert_respond_to @object, :get
  end

  def test_responds_to_prune
    assert_respond_to @object, :prune
  end

  def test_responds_to_reset
    assert_respond_to @object, :reset
  end

  def test_increment
    buckets = [
      Resilient::CircuitBreaker::Metrics::Bucket.new(1, 5),
      Resilient::CircuitBreaker::Metrics::Bucket.new(6, 10),
    ]
    keys = [
      :success,
      :failure,
    ]
    @object.increment(buckets, keys)
    assert_equal 1, @object.source[buckets[0]][:success]
    assert_equal 1, @object.source[buckets[0]][:failure]
    assert_equal 1, @object.source[buckets[1]][:success]
    assert_equal 1, @object.source[buckets[1]][:failure]
  end

  def test_get_defaults
    buckets = [
      Resilient::CircuitBreaker::Metrics::Bucket.new(1, 5),
      Resilient::CircuitBreaker::Metrics::Bucket.new(6, 10),
    ]
    keys = [
      :success,
      :failure,
    ]
    result = @object.get(buckets, keys)
    assert_equal 0, result[buckets[0]][:success]
    assert_equal 0, result[buckets[0]][:failure]
    assert_equal 0, result[buckets[1]][:success]
    assert_equal 0, result[buckets[1]][:failure]
  end

  def test_get_with_values
    buckets = [
      Resilient::CircuitBreaker::Metrics::Bucket.new(1, 5),
      Resilient::CircuitBreaker::Metrics::Bucket.new(6, 10),
    ]
    keys = [
      :success,
      :failure,
    ]
    @object.increment(buckets, keys)
    @object.increment(buckets, keys)
    @object.increment(buckets[0], keys)
    result = @object.get(buckets, keys)
    assert_equal 3, result[buckets[0]][:success]
    assert_equal 3, result[buckets[0]][:failure]
    assert_equal 2, result[buckets[1]][:success]
    assert_equal 2, result[buckets[1]][:failure]
  end

  def test_reset
    buckets = [
      Resilient::CircuitBreaker::Metrics::Bucket.new(1, 5),
      Resilient::CircuitBreaker::Metrics::Bucket.new(6, 10),
    ]
    keys = [
      :success,
      :failure,
    ]
    @object.increment(buckets, keys)
    @object.increment(buckets, keys)
    @object.increment(buckets[0], keys)
    @object.reset(buckets, keys)
    result = @object.get(buckets, keys)
    assert_equal 0, result[buckets[0]][:success]
    assert_equal 0, result[buckets[0]][:failure]
    assert_equal 0, result[buckets[1]][:success]
    assert_equal 0, result[buckets[1]][:failure]
  end

  def test_prune
    buckets = [
      Resilient::CircuitBreaker::Metrics::Bucket.new(1, 5),
      Resilient::CircuitBreaker::Metrics::Bucket.new(6, 10),
    ]
    keys = [
      :success,
      :failure,
    ]
    @object.increment(buckets, keys)
    @object.increment(buckets, keys)
    @object.increment(buckets[0], keys)
    @object.prune(buckets, keys)
    result = @object.get(buckets, keys)
    assert_equal 0, result[buckets[0]][:success]
    assert_equal 0, result[buckets[0]][:failure]
    assert_equal 0, result[buckets[1]][:success]
    assert_equal 0, result[buckets[1]][:failure]
  end
end

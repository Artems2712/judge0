# config/initializers/redis.rb

redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379')
Redis.current = Redis.new(url: redis_url

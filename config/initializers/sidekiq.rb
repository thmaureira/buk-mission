redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

Sidekiq.configure_server do |config|
  config.redis = redis
  schedule = Rails.root.join("config/schedule.yml")
  config.on(:startup) { Sidekiq::Cron::Job.load_from_hash(YAML.load_file(schedule)) } if schedule.exist?
end

Sidekiq.configure_client { |config| config.redis = redis }

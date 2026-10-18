remote_state {
  backend = "s3"
  config = {
    bucket = "x"
    skip_credentials_validation = true
    skip_bucket_versioning      = true
  }
}
retryable_errors = [".*timeout.*"]
retry_max_attempts = 3
retry_sleep_interval_sec = 5

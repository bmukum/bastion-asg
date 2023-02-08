output "webserver_url" {
  description = "URL of the mwaa environment"
  value       = aws_mwaa_environment.airflow.webserver_url
}

output "webserver_arn" {
  description = "ARN of the mwaa environment"
  value       = aws_mwaa_environment.airflow.arn
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.airflow[0].arn
}

output "role_arn" {
  description = "The execution role ARN of the mwaa environment"
  value       = aws_iam_role.airflow[0].arn
}
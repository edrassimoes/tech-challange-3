output "queue_arn" {
  value = aws_sqs_queue.events.arn
}

output "queue_url" {
  value = aws_sqs_queue.events.url
}

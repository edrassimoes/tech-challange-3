resource "aws_sqs_queue" "events" {
  name = "toggle-evaluation-events"
}

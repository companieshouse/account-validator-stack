output "account-validation-web-lb-listener-arn" {
  value = aws_lb_listener.account-validation-web-lb-listener.arn
}

output "account-validation-web-lb-arn" {
  value = aws_lb.account-validation-web-lb.arn
}
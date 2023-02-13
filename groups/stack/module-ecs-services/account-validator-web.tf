locals {
  service_name = "account-validator-web"
  account_validator_web_proxy_port = 11000 # local port number defined for proxy target of account validation service
}

resource "aws_ecs_service" "account-validator-web-ecs-service" {
  name            = "${var.environment}-${local.service_name}"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.account-validator-web-td.arn
  desired_count   = 1
  depends_on      = [var.account-validator-web-lb-arn]
  load_balancer {
    target_group_arn = aws_lb_target_group.account-validator-web-tg.arn
    container_port   = var.account_validator_web_application_port
    container_name   = "eric" # [ALB -> target group -> eric -> account validator web] so eric container named here
  }
}

locals {
  definition = merge(
    {
      service_name               : local.service_name
      environment                : var.environment
      name_prefix                : var.name_prefix
      aws_region                 : var.aws_region
      external_top_level_domain  : var.external_top_level_domain
      account_subdomain_prefix   : var.account_subdomain_prefix
      log_level                  : var.log_level
      docker_registry            : var.docker_registry
      cookie_domain              : var.cookie_domain
      cookie_name                : var.cookie_name

      # api configs      
      internal_api_url                   : var.internal_api_url
      api_url                            : var.api_url

      # account validator web specific configs
      account_validator_web_release_version            : var.account_validator_web_release_version
      account_validator_web_proxy_port                 : local.account_validator_web_proxy_port
      account_validator_web_oauth2_redirect_uri        : var.account_validator_web_oauth2_redirect_uri
      account_validator_web_oauth2_token_uri           : var.account_validator_web_oauth2_token_uri
      account_validator_web_cdn_host                   : var.account_validator_web_cdn_host
      account_validator_web_chs_url                    : var.account_validator_web_chs_url
      account_validator_web_account_url                : var.account_validator_web_account_url
      account_validator_web_monitor_url                : var.account_validator_web_monitor_url
      account_validator_web_cache_pool_size            : var.account_validator_web_cache_pool_size
      account_validator_web_cache_server               : var.account_validator_web_cache_server
      account_validator_web_default_session_expiration : var.account_validator_web_default_session_expiration
    },
      var.secrets_arn_map
  )
}

resource "aws_ecs_task_definition" "account-validation-web-td" {
  family                = "${var.environment}-${local.service_name}"
  execution_role_arn    = var.task_execution_role_arn
  container_definitions = templatefile(
    "${path.module}/${local.service_name}-task-definition.tmpl", local.definition
  )
}

resource "aws_lb_target_group" "account-validation-web-tg" {
  name     = "${var.environment}-${local.service_name}"
  port     = var.account_validator_web_application_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener_rule" "account-validation-web" {
  listener_arn = account-validation-web-lb-listener-arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.account-validation-web-tg.arn
  }
  condition {
    field  = "path-pattern"
    values = ["*"]
  }
}
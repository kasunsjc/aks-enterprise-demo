variable "environment" {
  description = "Environment name (dev, stage, prod)."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "app_name" {
  description = "Short application name."
  type        = string
}

variable "service_plan_sku" {
  description = "App Service plan SKU (e.g., B1, P1v3)."
  type        = string
}

variable "worker_count" {
  description = "Number of workers / app service instances."
  type        = number
  default     = 1

  validation {
    condition     = var.worker_count >= 1 && var.worker_count <= 30
    error_message = "worker_count must be between 1 and 30."
  }
}

variable "https_only" {
  description = "Enforce HTTPS on the web app."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags."
  type        = map(string)
  default     = {}
}

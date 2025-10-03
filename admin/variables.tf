variable "worker_pool_config" {
  description = "Configuration for the worker pool"
  type        = string
}

variable "worker_pool_private_key" {
  description = "Private key for the worker pool"
  type        = string
}

variable "worker_pool_id" {
  description = "ID of the worker pool"
  type        = string
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet"
}


variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "owner" {
  type    = string
  default = "Preethi"
}

# ---------- Things that already exist (values come from the current AWS setup) ----------
variable "vpc_id" {
  description = "The VPC the servers live in"
  type        = string
  default     = "vpc-0a022e9a4a57d7180"
}

variable "ami_id" {
  description = "Same Ubuntu image the existing servers use"
  type        = string
  default     = "ami-0c7632fb77f35db43"
}

variable "key_name" {
  type    = string
  default = "food-key"
}

variable "app_instance_id" {
  description = "food-app: holds MongoDB, the admin panel and the uploaded images"
  type        = string
  default     = "i-09a752b2d82dcf145"
}

variable "app_security_group_id" {
  description = "Security group of food-app (we add one rule to it)"
  type        = string
  default     = "sg-0c60d2b720227c4b2"
}

variable "alerts_topic_arn" {
  description = "SNS topic that emails the team"
  type        = string
  default     = "arn:aws:sns:ap-south-1:895579567065:food-alerts"
}

# ---------- Web tier settings ----------
variable "web_instance_type" {
  type    = string
  default = "t3.small"
}

variable "web_min_size" {
  description = "Start with 1 for the first test, then change to 2"
  type        = number
  default     = 1
}

variable "web_desired_capacity" {
  description = "Only used when the group is first created. Raise web_min_size to add servers later."
  type        = number
  default     = 1
}

variable "web_max_size" {
  type    = number
  default = 4
}

variable "cpu_target" {
  description = "Add servers when average CPU stays above this percent"
  type        = number
  default     = 50
}

# ---------- Optional: scale to zero at night (saves credits) ----------
variable "enable_schedules" {
  description = "true = scale to 0 at 11 PM and back up at 9 AM (India time)"
  type        = bool
  default     = false
}

variable "web_day_size" {
  description = "Number of web servers in the morning when schedules are on"
  type        = number
  default     = 2
}

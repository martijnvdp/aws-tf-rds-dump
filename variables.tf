variable "bucket" {
  type        = string
  description = "target s3 bucket"
}

variable "container_image" {
  type = object({
    command = optional(list, [
      "/bin/bash",
      "-c",
      "/backuper/s3_backup_script.sh && /bin/bash -c /backuper/postgre_backup_script.sh"
    ])
    image = "ghcr.io/martijnvdp/rdsdump"

  })
  default = {}
}

variable "iam_role_arn" {
  type        = string
  description = "IAM role for the AWS batch job"
  default     = "arn:aws:iam::123456789012:role/AWSBatchS3ReadOnly"
}

variable "name" {
  type    = string
  default = "aws-rds-dump"
}

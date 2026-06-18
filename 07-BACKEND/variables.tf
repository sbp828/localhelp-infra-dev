variable "project_name"{
    default = "localhelp"
}

variable "environment"{
    default = "dev"
}

variable "common_tags"{
    default = {
        Project = "localhelp"
        Environment = "dev"
        Terraform = "true"
        Component = "backend"
    }
}


variable "git_commit" {
  type        = string
  description = "Git commit hash to force redeploy"
}


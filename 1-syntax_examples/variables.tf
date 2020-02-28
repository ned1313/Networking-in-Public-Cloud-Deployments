# Define a simple variable

variable "prefix" {}

# Define a variable with a type and default value

variable "location" {
    type = string
    default = "eastus"
}

# Define a complex variable with a default value

variable "subnet_cidrs" {
    type = map(list)

    default = {
        dev = ["10.0.0.0/24","10.0.1.0/24"]
        stage = ["10.1.0.0/24","10.1.1.0/24"]
        prod = ["10.2.0.0/24","10.2.1.0/24"]
    }

}

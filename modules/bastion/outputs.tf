output "ip" {
  description = "Public ip of bastion."
  value       = var.spot == null ? aws_instance.bastion[0].public_ip : aws_spot_instance_request.bastion[0].public_ip
}

output "ec2" {
  description = "Created instance."
  value       = var.spot == null ? aws_instance.bastion[0] : aws_spot_instance_request.bastion[0]
}

output "sg" {
  description = "Sg on bastion ec2."
  value       = module.sg.sg
}

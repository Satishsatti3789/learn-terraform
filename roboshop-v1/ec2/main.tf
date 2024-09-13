resource "aws_instance" "web" {
  ami                    = data.aws_ami.centos.id
  count     = length(var.values)
  instance_type          = var.values[count.index].instance_type
  vpc_security_group_ids = [aws_security_group.sg.id]

  tags = {
    Name = var.values[count.index].name
  }

}

resource "null_resource" "ansible" {
  depends_on = [aws_instance.web, aws_route53_record.roboshop]
  provisioner "remote-exec" {

    connection {
      type     = "ssh"
      user     = "centos"
      password = "DevOps321"
      host     = aws_instance.web.public_ip
    }

    inline = [
      "sudo labauto ansible",
      "ansible-pull -i localhost, -U https://github.com/satishsatti3789/ansible-v1 main.yml -e env=dev -e role_name=${var.values[count.index].name}"
    ]
  }
}

resource "aws_route53_record" "roboshop" {
  zone_id = "Z014790038ULCSA62ANIV"
  name    = "${var.values[count.index].name}-dev"
  type    = "A"
  ttl     = 30
  records = [aws_instance.web.private_ip]
}

data "aws_ami" "centos" {
  owners      = ["973714476881"]
  most_recent = true
  name_regex  = "Centos-8-DevOps-Practice"
}


resource "aws_security_group" "sg" {
  name        = var.values[count.index].name
  description = "Allow TLS inbound traffic"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.values[count.index].name
  }
}


variable "values" {
  default = [
    { name = "frontend", instance_type = "t3.small" },
    { name = "catalogue", instance_type = "t2.micro" },
    { name = "cart", instance_type = "t2.micro" },
    { name = "user", instance_type = "t2.micro" },
    { name = "redis", instance_type = "t2.micro" },
    { name = "rabbitmq", instance_type = "t2.micro" },
    { name = "mysql", instance_type = "t2.micro" },
    { name = "mongodb", instance_type = "t2.micro" },
    { name = "dispatch", instance_type = "t2.micro" },
    { name = "payment", instance_type = "t3.small" },
    { name = "shipping", instance_type = "t3.small" },
  ]
}

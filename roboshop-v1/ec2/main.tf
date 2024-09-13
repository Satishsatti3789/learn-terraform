resource "aws_instance" "web" {
  ami                    = data.aws_ami.example.id
  instance_type          = "t3.small"
  vpc_security_group_ids = [aws_security_group.sg.id]


  tags = {
    Name = var.name
  }

}

resource "null_resource" "ansible" {
  depends_on = [aws_instance.web, aws_route53_record.www]
  provisioner "remote-exec" {

    connection {
      type     = "ssh"
      user     = "centos"
      password = "DevOps321"
      host     = aws_instance.web.public_ip
    }

    inline = [
      "sudo labauto ansible",
      "ansible-pull -i localhost, -U https://github.com/satishsatti3789/ansible main.yml -e env=dev -e role_name=${var.name}"
    ]
  }
}

resource "aws_route53_record" "www" {
  zone_id = "Z014790038ULCSA62ANIV"
  name    = "${var.name}-dev"
  type    = "A"
  ttl     = 30
  records = [aws_instance.web.private_ip]
}

data "aws_ami" "example" {
  owners      = ["973714476881"]
  most_recent = true
  name_regex  = "Centos-8-DevOps-Practice"
}


resource "aws_security_group" "sg" {
  name        = var.name
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
    Name = var.name
  }
}

resource "aws_iam_policy" "policy" {
  name        = "${var.name}-${var.env}-ssm-pm-policy"
  path        = "/"
  description = "${var.name}-${var.env}-ssm-pm-policy"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid       = "VisualEditor0",
        Effect    = "Allow",
        Action    = [
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter",
          "kms:Decrypt"
        ],
        Resource  = [
          "arn:aws:ssm:us-east-1:533267281718:parameter/roboshop.${var.env}.${var.name}.*"
        ]
      }
    ]
  })
}


## Iam Role

resource "aws_iam_role" "role" {
  name = "${var.name}-${var.env}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.name}-${var.env}-ec2-role"
  role = aws_iam_role.role.name
}

resource "aws_iam_role_policy_attachment" "policy-attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

variable "name" {}
variable "env" {
  default = dev
}


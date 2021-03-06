# Gather Ubuntu 18.04 Latest AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Create Deepfence Management Console Server
resource "aws_instance" "deep-lab-ap01" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.large"
  subnet_id                   = aws_subnet.deepfence-lab-subnet-public.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.deepfence-lab-sg.id]

  tags = {
    Name = "deep-lab-ap01"
  }

  root_block_device {
    volume_size = "60"
  }

  provisioner "file"{
    source      = "setup.yml"
    destination = "/home/ubuntu/setup.yml"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_key)
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install software-properties-common -y",
      "sudo apt-add-repository --yes --update ppa:ansible/ansible",
      "sudo apt install ansible -y",
      "sudo apt install python-pip -y",
      "ansible-playbook setup.yml -b",
    ]

      connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_key)
      host        = self.public_ip
    }
  }

  key_name = var.ssh_key_name
}
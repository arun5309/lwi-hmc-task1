provider "aws" {
	region = "ap-south-1"
	profile = "profile_task1"
}

resource "aws_security_group" "task1_security_group" {
	name = "task1_security_group"
	description = "Allow http traffic on port 80 and ssh on port 22."

	ingress { // Check
		description = "http on port 80."
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress { // Check
		description = "ssh on port 22."
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}

	lifecycle {
		create_before_destroy = true
	}

	tags = {
		Name = "task1_security_group"
	}
}

resource "aws_key_pair" "task1_keypair" {
	key_name = "task1_keypair"
	public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDQ1/ByaFIMiudU9BqE/ARjYVUqcqdwsoK8ptwCfsBTQ0vVW68BHcl+LvvBDqmkorEf2RVI5Mk6wllcH3nC5ZWMzWCUsR+/9p2P2MLQiUFCDxqmcnR9ycHgqAY1WpfC61nTU659IZnMCTebv3gyDAzfGaMEk/pAs1c8kWIAl92hzNjmLKvDasVhAcSe+9AzvRXJ8B9a38M9ylAJOjKH1YCehG3xpWp2Lr5PI83UgJh7/TC2r4DNsTlY6+GsbavFus7jMHVRJPrh8MH++hO+8KqfTJIKuH5egtOEQf66TSDTfgwdhVOP0uPhBW6h9gGBqgsrT9m6QjngHpgy/Sk2hW2CJeRP/HEgpxCTsYP8bK4TDXm/nj8p62Tj6vo2icBtIzDtwrJnzmCChGcRJMXS/dMMECIQ7iQzpbw9eT6xF7n8f7m9tTrkEbm0tIkvtDQVyWxyza0mFb/TXIZI5pmkbge7pYVQaBby4B/4MUBVbqSHtfY8xgt9neYtyCfhzQ21b4U958z1F8gFcAe37XFn3C8z1hRzO7tACKH2oKuOChm5Lxe/GnD3J6aweHxxgU+6WwNEBYFUoH1k8ei50vxlNBVufrg5VXTHSXJJ3VZ6UKB3jW7HrRJwBcykUhf4CGgd3U/76jMBxLeMx6SpMl4d9TnqA4l4MJChWKIlCnCNb/TtmQ== arunachalaeshwaran@tutanota.com"
}

resource "aws_ebs_volume" "task1_html_volume" {
	availability_zone = "ap-south-1a" // must be same as aws_instance.task1_main_instance.availability_zone
	size = 100
	tags = {
		Name = "task1_html_volume"
	}
}

resource "aws_volume_attachment" "task1_attachment" {
	device_name = "/dev/sdh"
	volume_id = aws_ebs_volume.task1_html_volume.id
	instance_id = aws_instance.task1_main_instance.id
}

resource "aws_instance" "task1_main_instance" {
	ami = "ami-0447a12f28fddb066" // amazon linux 2 amd64
	instance_type = "t2.micro"
	availability_zone = "ap-south-1a"
	key_name = "task1_keypair"
	associate_public_ip_address = true
	security_groups = ["${aws_security_group.task1_security_group.tags.Name}"]
	tags = {
		Name = "task1_main_instance"
	}

	connection {
		type = "ssh"
		//host = self.ho 
		user = "ec2-user"
		password = file("~/.ssh/id_rsa")
	}

	provisioner "remote-exec" {
		inline = [
			"sudo yum install httpd git -y",
			"sudo mkfs.ext4 /dev/xvdh",
			"sudo mount /dev/xvdh /var/www/html",
			"git clone https://github.com/arun5309/lwi-hmc-task1.git",
			"sudo cp -r lwi-hmc-task1/html /var/www/",
			"sudo systemctl --now enable httpd"
		]
	}
}

resource "aws_s3_bucket" "task1-image-bucket" {
	bucket = "task1-image-bucket"
	acl = "public-read"
	tags = {
		Name = "task1-image-bucket"
	}
}

locals {
	s3_origin_id = "s3-origin"
}

resource "aws_cloudfront_distribution" "task1-s3-distribution" {
	enabled = true
	is_ipv6_enabled = true
	
	origin {
		domain_name = aws_s3_bucket.task1-image-bucket.bucket_regional_domain_name
		origin_id = local.s3_origin_id
	}

	restrictions {
		geo_restriction {
			restriction_type = "none"
		}
	}

	default_cache_behavior {
		target_origin_id = local.s3_origin_id
		allowed_methods = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    	cached_methods  = ["HEAD", "GET", "OPTIONS"]

    	forwarded_values {
      		query_string = false
      		cookies {
        		forward = "none"
      		}
		}

		viewer_protocol_policy = "redirect-to-https"
    	min_ttl                = 0
    	default_ttl            = 720
    	max_ttl                = 86400
	}

	viewer_certificate {
    	cloudfront_default_certificate = true
  	}
}

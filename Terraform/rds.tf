provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_security_group" "my_security_group" {
  name        = "tf-security-group"
  description = "ASG security group"

  ingress {
    description      = "allow http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "allow ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "my_security_group_db" {
  name        = "tf-security-group-db"
  description = "DB security group"

  ingress {
    description      = "allow mysql"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [aws_security_group.my_security_group.id]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "my_db" {
  allocated_storage       = 20
  engine                  = "mariadb"
  engine_version          = "10.4.13"
  instance_class          = "db.t2.micro"
  name                    = "TFmydb"
  identifier              = "tf-mydb-idf" 
  username                = "admin"
  password                = "adminadmin"
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.my_security_group_db.id]
  backup_retention_period = 1
}

resource "aws_db_instance" "my_db_replica" {
   identifier             = "tf-mydb-idf-replica"
   replicate_source_db    = aws_db_instance.my_db.identifier
   instance_class         = "db.t2.micro"
   apply_immediately      = true
   skip_final_snapshot    = true
   vpc_security_group_ids = [aws_security_group.my_security_group_db.id]
}
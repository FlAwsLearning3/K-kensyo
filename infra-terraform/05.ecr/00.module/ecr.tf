resource "aws_ecr_repository" "ecr-01" {
  name = "ecr-${var.envname}-${var.systemid}-01"
  #リポジトリのタグ可変性を指定（IMMUTABLE(有効)、MUTABLE(無効)）
  image_tag_mutability = "MUTABLE" #"IMMUTABLE"
  #リポジトリのイメージスキャン構成を定義するブロック
  image_scanning_configuration {
    #リポジトリにプッシュされた後にImageをスキャンするか否かを指定（true/false）
    scan_on_push = true
  }
  #リポジトリの暗号化についての設定
  encryption_configuration {
    #リポジトリに使用する暗号化タイプを指定（AES256、KMS）
    encryption_type = "KMS" #"AES256"
    #KMSキーを指定（指定しない場合はAWSデフォルトのKMSキーが適用される）
  }
  tags = {
    Name               = "ecr-${var.envname}-${var.systemid}-01"
    IaC                = "Terraform"
    Terraform_Module_Name = var.module_name
  }
}

resource "aws_ecr_repository_policy" "ecr-01" {
  repository = aws_ecr_repository.ecr-al2023-01.name

  policy = <<EOF
  {
    "Version": "2008-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      }
    ]
  }
EOF
}
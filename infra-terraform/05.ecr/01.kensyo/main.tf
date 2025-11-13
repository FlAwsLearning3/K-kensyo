provider "aws" {
    region = "ap-northeast-1"
}

terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "5.72.1"
        }
    }

    backend "s3" {
        bucket = "dhc-infra-terraform-381492012185"
        region = "ap-northeast-1"
        #tfstateファイル名を指定
        key = "05.ecr/prd-dlpf-ecr.tfstate"
    }
}

module "prd_dlpf_ecr" {
    #モジュールファイルが格納されている階層を指定
    source = "../kky-kensyo/00.module"

    #モジュール共通の環境変数
    envname = "prd"
    systemid = "dlpf"
    module_name = "/05.ecr/00.module"
    account_id = "381492012185"
    region = "ap-northeast-1"
}
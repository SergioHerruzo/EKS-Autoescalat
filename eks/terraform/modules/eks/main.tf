# --- ACADEMY FIX DEFINITIVO ---
# El módulo oficial 'terraform-aws-modules/eks/aws' siempre ejecuta 'data.aws_iam_session_context' internamente,
# lo que desencadena un error inevitable de 'iam:GetRole' en AWS Academy.
# La solución comprobada es usar recursos nativos de Terraform (`aws_eks_cluster` y `aws_eks_node_group`).

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.lab_role_arn
  version  = "1.30"

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  access_config {
    authentication_mode = "API"
    # IMPORTANTE: Desactivar esto para evitar que EKS haga llamadas GetRole internamente durante el clúster creation.
    bootstrap_cluster_creator_admin_permissions = false
  }
}

# --- ACCESO MANUAL CON ACCESS ENTRIES ---
# Otorgamos permisos de Administrador del Clúster al LabRole de Academy explícitamente.
resource "aws_eks_access_entry" "lab_role" {
  cluster_name      = aws_eks_cluster.this.name
  principal_arn     = var.lab_role_arn
  type              = "EC2_LINUX"
}

# Otorgamos permisos de Administrador a 'voclabs' para que Terraform y Helm puedan autenticarse
resource "aws_eks_access_entry" "voclabs_role" {
  cluster_name      = aws_eks_cluster.this.name
  principal_arn     = var.voclabs_role_arn
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "voclabs_role_admin" {
  cluster_name  = aws_eks_cluster.this.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.voclabs_role.principal_arn

  access_scope {
    type = "cluster"
  }
}

# --- NODO GESTIONADO POR EKS ---
resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "system-node-group"
  node_role_arn   = var.lab_role_arn
  subnet_ids      = var.subnet_ids

  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  # Esperamos a que los permisos de admin estén listos antes de lanzar nodos
  depends_on = [
    aws_eks_access_entry.lab_role,
    aws_eks_access_entry.voclabs_role,
    aws_eks_access_policy_association.voclabs_role_admin
  ]
}

# --- TAGS DE DESCUBRIMIENTO PARA KARPENTER ---
resource "aws_ec2_tag" "cluster_sg_discovery" {
  resource_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

# --- OUTPUTS ---
output "cluster_name" { 
  value = aws_eks_cluster.this.name 
}

output "cluster_endpoint" { 
  value = aws_eks_cluster.this.endpoint 
}

output "cluster_certificate_authority_data" { 
  value = aws_eks_cluster.this.certificate_authority[0].data 
}
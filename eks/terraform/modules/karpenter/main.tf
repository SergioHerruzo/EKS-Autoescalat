resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "0.36.0"

  timeout          = 1200
  wait             = false 
  wait_for_jobs    = false

  # Usamos la sintaxis de asignación (=) con una lista de objetos
  set = [
    {
      name  = "settings.clusterName"
      value = var.cluster_name
    },
    {
      name  = "settings.interruptionQueue"
      value = "" 
    },

    {
      name  = "settings.aws.defaultInstanceProfile"
      value = "LabInstanceProfile"
    },
    {
      name  = "crds.install"
      value = "true"
    }
  ]
}

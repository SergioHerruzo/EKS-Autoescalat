# EKS amb Karpenter a AWS Academy

Aquest projecte proporciona una infraestructura modular de Terraform per desplegar un clúster d'Amazon Elastic Kubernetes Service (EKS) amb autoscaling intel·ligent gestionat per **Karpenter**. Està dissenyat específicament per funcionar dins les restriccions dels laboratoris de **AWS Academy**.

## Arquitectura

El projecte està organitzat en mòduls locals per a una millor mantenibilitat:

- **VPC**: Una xarxa personalitzada amb subxarxes públiques i privades configurades per a EKS.
- **EKS**: Clúster Kubernetes versió 1.30 utilitzant el mòdul oficial de la comunitat (v20+).
- **Karpenter**: Instal·lació mitjançant Helm per a l'autoscaling de nodes segons la demanda.

## Estructura del Projecte

```text
├── terraform/
│   ├── main.tf              # Orquestrador de mòduls
│   ├── providers.tf         # Configuració de providers (AWS, Helm, Kubernetes)
│   ├── variables.tf         # Variables globals i dades del compte
│   └── modules/             # Mòduls locals
│       ├── vpc/             # Configuració de xarxa
│       ├── eks/             # Clúster i grups de nodes gestionats (v20)
│       └── karpenter/       # Release de Helm per a Karpenter
└── kubernetes/              # Manifestos per provar l'autoscaling (NodePool, etc.)
```

## Adaptacions per a AWS Academy

Aquest projecte inclou correccions crítiques per superar les restriccions d'IAM i de temps de l'entorn de l'Academy:

- **LabRole**: S'utilitza el rol preexistent `LabRole` per a totes les operacions (clúster i nodes), ja que no es poden crear rols nous.
- **KMS**: S'ha desactivat la creació de claus KMS personalitzades per evitar errors de permisos.
- **Access Entries**: S'utilitza el sistema de permisos d'EKS v20 per garantir l'accés d'administrador a l'usuari del laboratori.
- **Karpenter Helm Release**: 
  - S'ha configurat amb `wait = false` i un `timeout = 1200`. Això és vital per evitar l'error `context deadline exceeded` que sol ocórrer quan el controlador triga a estabilitzar-se en entorns compartits.
  - S'utilitza `LabInstanceProfile` per als nodes creats per Karpenter.

## Com Començar

1. **Inicialitzar Terraform**:
   ```bash
   cd terraform
   terraform init
   ```

2. **Aplicar la configuració**:
   ```bash
   terraform apply
   ```

3. **Configurar el context de kubectl**:
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name karpenter-challenge-35
   ```

## Proves d'Autoscaling amb Karpenter

Un cop el clúster estigui llest, pots analitzar com reacciona Karpenter davant l'augment o disminució de demanda de recursos:

1. **Desplegar els recursos inicials**:
   Aplica el manifest `nodepool.yaml` (la configuració de Karpenter sobre com crear nodes) i l'aplicació de prova `test-app.yaml`.
   ```bash
   kubectl apply -f ../kubernetes/nodepool.yaml
   kubectl apply -f ../kubernetes/test-app.yaml
   ```

2. **Proves d'Autoscaling amb Karpenter**:
   - Escala el "load-generator" per forçar la creació de nodes:
     ```bash
     kubectl scale deployment load-generator --replicas=15
     ```
   - Vigila la creació de nous nodes EC2:
     ```bash
     kubectl get nodes -w
     ```
   - Revisa els logs de Karpenter per veure les decisions d'aprovisionament:
     ```bash
     kubectl logs -f -n karpenter -l app.kubernetes.io/name=karpenter
     ```

3. **Prova de Consolidació (Scale-Down)**:
   Redueix les rèpliques per veure com Karpenter elimina nodes infrautilitzats:
   ```bash
   kubectl scale deployment load-generator --replicas=1
   ```

## Solució de Problemes Comuns

### Error `context deadline exceeded` durant `terraform apply`
Aquest error sol ocórrer en l'etapa de Helm per a Karpenter. Hem mitigat això amb `wait = false`. Si el recurs apareix com a "failed" a Terraform però el pod de Karpenter s'acaba aixecant correctament, pots tornar a executar `terraform apply` per sincronitzar l'estat.

### Error `AccessDenied` en IAM
Recorda que a AWS Academy no pots crear rols ni polítiques. El projecte està configurat per utilitzar `LabRole`. Si veus errors de permisos, assegura't que el fitxer `variables.tf` té l'ID del compte correcte o que el `LabRole` està disponible.

---
*Creat com a part del repte d'infraestructura cloud per a AWS Academy.*

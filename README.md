# EKS amb Karpenter a AWS Academy

Aquest projecte proporciona una infraestructura modular de Terraform per desplegar un clúster d'Amazon Elastic Kubernetes Service (EKS) amb autoscaling intel·ligent gestionat per **Karpenter**. Està dissenyat específicament per funcionar dins les restriccions dels laboratoris de **AWS Academy**.

## Arquitectura

El projecte està organitzat en mòduls locals per a una millor mantenibilitat:

- **VPC**: Una xarxa personalitzada amb subxarxes públiques i privades configurades per a EKS.
- **EKS**: Clúster Kubernetes versió 1.30 utilitzant el mòdul oficial de la comunitat (v20+).
- **Karpenter**: Instal·lació mitjançant Helm per a l'autoscaling de nodes segons la demanda.

## Estructura del Projecte

```text
eks/
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

Aquest projecte inclou correccions crítiques per superar les restriccions d'IAM de l'entorn de l'Academy:

- **LabRole**: S'utilitza el rol preexistent `LabRole` per a totes les operacions (clúster i nodes), ja que no es poden crear rols nous.
- **KMS**: S'ha desactivat la creació de claus KMS personalitzades.
- **Access Entries**: S'utilitza el nou sistema de permisos d'EKS v20 per garantir l'accés admin a l'usuari del laboratori.

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

## Verificació de Karpenter

Un cop el clúster estigui llest, pots desplegar l'aplicació de prova i el `NodePool` per veure com Karpenter llança nous nodes automàticament:

```bash
kubectl apply -f ../kubernetes/nodepool.yaml
kubectl apply -f ../kubernetes/test-app.yaml
```

---
*Creat com a part del repte d'infraestructura cloud.*

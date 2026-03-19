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

## Proves d'Autoscaling amb Karpenter

Un cop el clúster estigui llest, pots analitzar com reacciona Karpenter davant l'augment o disminució de demanda de recursos:

1. **Desplegar els recursos inicials**:
   Aplica el manifest `nodepool.yaml` (la configuració de Karpenter sobre com crear nodes) i l'aplicació de prova `test-app.yaml`.
   ```bash
   kubectl apply -f ../kubernetes/nodepool.yaml
   kubectl apply -f ../kubernetes/test-app.yaml
   ```

2. **Prova de Càrrega Automàtica (Scale-Up)**:
   Pots utilitzar l'script de bash inclòs per desencadenar un esdeveniment d'escala automàtic i observar com reacciona Karpenter ràpidament. L'script configurarà 15 rèpliques i començarà a observar els canvis:
   ```bash
   cd ..
   chmod +x load-test.sh
   ./load-test.sh
   ```

3. **Prova Manual Pas a Pas (Opcional)**:
   Si vols dur a terme la prova manual per poder veure millor la reacció:
   
   - Escala un "load-generator" perquè hi hagi "pods pending" a l'espera de mes CPU i RAM:
     ```bash
     kubectl scale deployment load-generator --replicas=15
     ```
   
   - Vigila la creació de nous nodes de EC2 per part de Karpenter:
     ```bash
     kubectl get nodes -w
     ```
   
   - Analitza els logs del controlador de Karpenter per revisar les seves decisions d'aprovisionament:
     ```bash
     kubectl logs -f -n karpenter -l app.kubernetes.io/name=karpenter
     ```

4. **Prova de Consolidació (Scale-Down)**:
   Per verificar que Karpenter elimina els nodes innecessaris per estalviar costos, redueix les rèpliques a 1:
   ```bash
   kubectl scale deployment load-generator --replicas=1
   ```
   *Karpenter detectarà que els nodes estan infrautilitzats (consolidació), mourà els pods si cal, i terminarà les instàncies EC2 buides automàticament.*

---
*Creat com a part del repte d'infraestructura cloud per a AWS Academy.*

# Helm Chart do Archivematica para OpenShift

Este Helm chart facilita a implantação do Archivematica (~1.13.2) em clusters OpenShift, incluindo todos os componentes essenciais e dependências.

## Visão Geral

O Archivematica é um sistema de preservação digital open source, automatizando processos para garantir autenticidade, confiabilidade e acessibilidade de conteúdo digital a longo prazo.

### Componentes Implantados
- **Archivematica Dashboard**: Interface web de gerenciamento
- **Archivematica Storage Service**: Gerenciamento de armazenamento
- **Archivematica MCP Server**: Servidor de processamento principal
- **Archivematica MCP Client**: Workers de processamento
- **MySQL**: Banco de dados relacional
- **Elasticsearch**: Busca e indexação (7.x)
- **Redis**: Armazenamento em memória
- **Gearman**: Sistema de filas
- **ClamAV**: Antivírus
- **FITS**: Identificação e validação de formatos de arquivo

## Pré-requisitos
- OpenShift 4.x
- Helm 3
- Permissões para criar Deployments, StatefulSets, Services, Routes, PVCs, ServiceAccounts e SCCs
- StorageClass padrão ou específicos para cada tipo de persistência
- Acesso a um registro de imagens (Docker Hub ou personalizado)

## Estrutura do Chart
- `Chart.yaml`: Metadados
- `values.yaml`: Configurações padrão
- `templates/`: Templates Kubernetes
  - `_helpers.tpl`: Funções auxiliares
  - `serviceaccount.yaml`: ServiceAccount
  - `scc.yaml`: SCC personalizada (opcional)
  - `configmap.yaml`: ConfigMaps
  - `secret.yaml`: Secrets
  - `deployments/`: Deployments dos componentes
  - `statefulsets/`: StatefulSets dos componentes
  - `pvc.yaml`: PVCs compartilhados
  - `route.yaml`: Routes OpenShift

## Instalação

1. **Adicionar Repositório (opcional):**
   ```bash
   helm repo add <repo-name> <repo-url>
   helm repo update
   ```
2. **Criar Namespace:**
   ```bash
   oc new-project archivematica
   ```
3. **Personalizar Valores:**
   Crie um `my-values.yaml` para sobrescrever valores do `values.yaml`. Recomendações:
   - `general.user_uid`: Verifique o intervalo de UID permitido (`oc describe project <seu-projeto>`)
   - `route.hostname` e `route.ss_hostname`: Hostnames para Dashboard e Storage Service
   - `mysql.db.rootPassword` e `mysql.db.password`: Senhas seguras
   - StorageClasses para PVCs, se necessário
   - `security.scc.use`: Escolha a SCC adequada (`restricted`, `nonroot`, `anyuid`, `custom`)
4. **Instalar o Chart:**
   ```bash
   helm install archivematica . -n archivematica -f my-values.yaml
   # Ou, se estiver usando um repositório:
   # helm install archivematica <repo-name>/archivematica -n archivematica -f my-values.yaml
   ```

## Configuração

As principais opções estão em `values.yaml`. Destaques:
- `general.user_uid`: UID dos containers (compatibilidade SCC)
- `security.serviceAccount.create` / `security.serviceAccount.name`: Criação e nome do ServiceAccount
- `security.scc.use`: SCC a ser usada (`restricted`, `nonroot`, `anyuid`, `custom`)
- `route.enabled`: Criação de Routes OpenShift
- `route.hostname` / `route.ss_hostname`: Hostnames das Routes
- `route.tls`: TLS nas Routes (edge termination)
- `persistence.storageClass`: StorageClass para cada PVC
- `shared_volumes.*.accessMode`: `ReadWriteMany` para volumes compartilhados (NFS, CephFS, GlusterFS)

## Considerações sobre OpenShift

- **SCCs:** O chart define `securityContext` nos pods e permite uso de SCCs existentes ou personalizada. `anyuid` pode ser necessário para imagens/processos com UID fixo, mas requer privilégios. Teste no seu ambiente.
- **UIDs:** `general.user_uid` define `runAsUser`, `runAsGroup` e `fsGroup`. O UID deve estar no intervalo permitido para o ServiceAccount do namespace.
- **Permissões ArgoCD:** A ServiceAccount `argocd-argocd-application-controller` precisa de permissão para criar RBAC no cluster.
- **Routes:** Se `route.enabled` for `true`, o chart cria Routes para Dashboard e Storage Service.
- **Persistência:** Certifique-se de que StorageClasses e AccessModes dos PVCs são suportados pelo cluster e infraestrutura de armazenamento.
- **Elasticsearch `vm.max_map_count`:** O Elasticsearch exige `vm.max_map_count` elevado. O chart inclui um `initContainer` privilegiado para isso. Se não for permitido, configure no nó via MachineConfig.

## Exemplos de Comandos Úteis

- **Verificar UID permitido:**
  ```bash
  oc describe project <seu-projeto> | grep -i uid
  ```
- **Verificar StorageClasses disponíveis:**
  ```bash
  oc get storageclass
  ```
- **Verificar SCCs disponíveis:**
  ```bash
  oc get scc
  ```

## Desinstalação

Para desinstalar o chart:
```bash
helm uninstall archivematica -n archivematica
```

**Importante:** A desinstalação remove recursos criados pelo Helm, mas **não** remove os PVCs por padrão (para evitar perda de dados). Para remover PVCs e dados associados:
```bash
oc delete pvc -l app.kubernetes.io/instance=archivematica -n archivematica
oc delete pvc -l app.kubernetes.io/component=mysql,app.kubernetes.io/instance=archivematica -n archivematica
oc delete pvc -l app.kubernetes.io/component=elasticsearch,app.kubernetes.io/instance=archivematica -n archivematica
oc delete pvc -l app.kubernetes.io/component=redis,app.kubernetes.io/instance=archivematica -n archivematica
oc delete pvc -l app.kubernetes.io/component=clamav,app.kubernetes.io/instance=archivematica -n archivematica
```

## Estrutura dos Recursos no Cluster (Pós-Implantação)

Após a instalação deste chart, os seguintes recursos padrão serão criados no seu cluster OpenShift (nomes podem variar conforme valores definidos):

- **Namespace:**
  - `archivematica` (ou o namespace escolhido)

- **ServiceAccounts:**
  - `archivematica` (ou nome customizado via `security.serviceAccount.name`)

- **Deployments:**
  - `archivematica-am-dashboard`
  - `archivematica-am-storage-service`
  - `archivematica-mcp-server`
  - `archivematica-mcp-client`
  - `archivematica-gearmand`
  - `archivematica-clamav`
  - `archivematica-fits`

- **StatefulSets:**
  - `archivematica-mysql`
  - `archivematica-elasticsearch`
  - `archivematica-redis`

- **Services:**
  - Um Service para cada componente acima, geralmente com o mesmo nome do Deployment/StatefulSet

- **PersistentVolumeClaims (PVCs):**
  - PVCs para MySQL, Elasticsearch, Redis, ClamAV DB e volumes compartilhados (nomes como `archivematica-mysql`, `archivematica-elasticsearch`, etc.)

- **ConfigMaps e Secrets:**
  - ConfigMaps para configurações não sensíveis
  - Secrets para senhas e chaves de API

- **Routes (se `route.enabled: true`):**
  - `archivematica-dashboard` (expondo o Dashboard)
  - `archivematica-storage-service` (expondo o Storage Service)

- **SecurityContextConstraints (SCCs):**
  - Se `security.scc.use: custom`, uma SCC personalizada vinculada ao ServiceAccount

### Exemplo de Estrutura no OpenShift

```bash
oc get all -n archivematica
oc get pvc -n archivematica
oc get route -n archivematica
oc get sa -n archivematica
oc get scc | grep archivematica
```

Esses comandos mostrarão todos os recursos criados e seus nomes reais no cluster.

---

Para dúvidas ou contribuições, abra uma issue ou pull request neste repositório.


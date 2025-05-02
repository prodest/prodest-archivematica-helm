# Helm Chart do Archivematica para OpenShift

Este Helm chart foi criado para facilitar a implantação do Archivematica (versão ~1.13.2) em um cluster OpenShift.

## Visão Geral

O Archivematica é um sistema de preservação digital de código aberto que automatiza processos para garantir a autenticidade, confiabilidade e acessibilidade a longo prazo do conteúdo digital.

Este chart implanta os seguintes componentes principais do Archivematica e suas dependências:

*   **Archivematica Dashboard:** Interface web para gerenciamento.
*   **Archivematica Storage Service:** Serviço para gerenciamento de armazenamento.
*   **Archivematica MCP Server:** Servidor de processamento principal.
*   **Archivematica MCP Client:** Workers que executam tarefas de processamento.
*   **MySQL:** Banco de dados relacional (usado pelo Dashboard e Storage Service).
*   **Elasticsearch:** Mecanismo de busca e indexação (versão 7.x).
*   **Redis:** Armazenamento de dados em memória (usado pelo Gearman).
*   **Gearman:** Sistema de filas de trabalho.
*   **ClamAV:** Antivírus para verificação de arquivos.
*   **FITS (File Information Tool Set):** Ferramenta para identificação e validação de formatos de arquivo.

## Pré-requisitos

*   Cluster OpenShift (versão 4.x recomendada).
*   Helm 3 instalado.
*   Permissões adequadas no cluster OpenShift para criar recursos como Deployments, StatefulSets, Services, Routes, PersistentVolumeClaims, ServiceAccounts e SecurityContextConstraints (SCCs).
*   Um StorageClass padrão configurado no cluster ou StorageClasses específicas para os diferentes tipos de persistência (MySQL, Elasticsearch, Redis, ClamAV DB, Volumes Compartilhados).
*   Acesso a um registro de imagens (as imagens padrão são do Docker Hub/repositórios oficiais, mas podem ser personalizadas).

## Estrutura do Chart

O chart está organizado da seguinte forma:

*   `Chart.yaml`: Metadados do chart.
*   `values.yaml`: Valores de configuração padrão.
*   `templates/`: Diretório contendo os templates Kubernetes.
    *   `_helpers.tpl`: Funções auxiliares de template.
    *   `serviceaccount.yaml`: Define o ServiceAccount para os pods.
    *   `scc.yaml`: Define uma SecurityContextConstraint personalizada (opcional, se `security.scc.use` for "custom").
    *   `configmap.yaml`: Define ConfigMaps para configurações não sensíveis.
    *   `secret.yaml`: Define Secrets para senhas e chaves de API (geradas aleatoriamente por padrão).
    *   `mysql.yaml`: Template para o StatefulSet e Service do MySQL.
    *   `elasticsearch.yaml`: Template para o StatefulSet e Service do Elasticsearch.
    *   `redis.yaml`: Template para o StatefulSet e Service do Redis.
    *   `gearmand.yaml`: Template para o Deployment e Service do Gearman.
    *   `clamav.yaml`: Template para o Deployment, Service e PVC do ClamAV.
    *   `fits.yaml`: Template para o Deployment e Service do FITS.
    *   `mcp-server.yaml`: Template para o Deployment e Service do MCP Server.
    *   `mcp-client.yaml`: Template para o Deployment do MCP Client.
    *   `dashboard.yaml`: Template para o Deployment e Service do Dashboard.
    *   `storage-service.yaml`: Template para o Deployment e Service do Storage Service.
    *   `pvc.yaml`: Define os PersistentVolumeClaims para os volumes compartilhados.
    *   `route.yaml`: Define as Routes do OpenShift para expor o Dashboard e o Storage Service.

## Instalação

1.  **Adicionar Repositório (se aplicável):** Se o chart for hospedado em um repositório Helm, adicione-o:
    ```bash
    helm repo add <repo-name> <repo-url>
    helm repo update
    ```
2.  **Criar Namespace:**
    ```bash
    oc new-project archivematica
    ```
3.  **Personalizar Valores:** Crie um arquivo `my-values.yaml` para substituir os valores padrão em `values.yaml`. No mínimo, você provavelmente precisará configurar:
    *   `general.user_uid`: Verifique o intervalo de UID permitido no seu projeto OpenShift (`oc describe project <seu-projeto>`).
    *   `route.hostname` e `route.ss_hostname`: Defina os hostnames desejados para acessar o Dashboard e o Storage Service.
    *   `mysql.db.rootPassword` e `mysql.db.password`: Defina senhas seguras.
    *   Configurações de `storageClass` para os PVCs, se necessário.
    *   `security.scc.use`: Escolha a SCC apropriada. `anyuid` pode funcionar em muitos casos, mas verifique as políticas do seu cluster. Se usar `custom`, certifique-se de que a SCC definida em `scc.yaml` seja criada ou que você tenha permissão para criá-la.
4.  **Instalar o Chart:**
    ```bash
    helm install archivematica . -n archivematica -f my-values.yaml
    # Ou, se estiver usando um repositório:
    # helm install archivematica <repo-name>/archivematica -n archivematica -f my-values.yaml
    ```

## Configuração

As principais opções de configuração estão disponíveis no arquivo `values.yaml`. Algumas configurações importantes específicas do OpenShift:

*   **`general.user_uid`**: Define o UID sob o qual os contêineres serão executados. Isso é crucial para compatibilidade com as SCCs do OpenShift.
*   **`security.serviceAccount.create` / `security.serviceAccount.name`**: Controla a criação e o nome do ServiceAccount.
*   **`security.scc.use`**: Define qual SCC usar (`restricted`, `nonroot`, `anyuid`, `custom`). `anyuid` é frequentemente necessário devido aos UIDs fixos em algumas imagens ou processos, mas requer permissões elevadas. Se `custom` for escolhido, o template `scc.yaml` tentará criar uma SCC personalizada vinculada ao ServiceAccount do chart.
*   **`route.enabled`**: Habilita a criação de Routes do OpenShift para expor o Dashboard e o Storage Service.
*   **`route.hostname` / `route.ss_hostname`**: Hostnames para as Routes.
*   **`route.tls`**: Habilita TLS (terminação edge) nas Routes.
*   **Persistência (`persistence.storageClass`)**: Especifique um StorageClass válido no seu cluster OpenShift para cada PVC, se o padrão não for adequado.
*   **Volumes Compartilhados (`shared_volumes.*.accessMode`)**: `ReadWriteMany` é necessário para volumes compartilhados entre múltiplos pods (MCP Client, Dashboard, etc.). Certifique-se de que seu StorageClass suporte `ReadWriteMany` (por exemplo, NFS, CephFS, GlusterFS).

## Considerações sobre OpenShift

*   **Security Context Constraints (SCCs):** OpenShift usa SCCs para controlar permissões de pods. Este chart tenta ser compatível definindo `securityContext` nos pods e oferecendo a opção de usar SCCs existentes ou uma personalizada. A SCC `anyuid` pode ser necessária, mas requer privilégios. Teste cuidadosamente no seu ambiente.
*   **UIDs:** O `general.user_uid` é usado para definir `runAsUser`, `runAsGroup` e `fsGroup`. Certifique-se de que este UID esteja dentro do intervalo permitido para o ServiceAccount no seu namespace OpenShift.
*   **Routes:** O chart cria Routes do OpenShift para expor os serviços web (Dashboard, Storage Service) se `route.enabled` for `true`.
*   **Persistência:** Certifique-se de que os StorageClasses e AccessModes definidos para os PVCs sejam suportados pelo seu cluster OpenShift e pela infraestrutura de armazenamento subjacente.
*   **Elasticsearch `vm.max_map_count`:** Elasticsearch requer um valor alto para `vm.max_map_count`. O chart inclui um `initContainer` privilegiado para tentar definir isso. Se `initContainers` privilegiados não forem permitidos pela sua SCC, você precisará configurar `vm.max_map_count` no nível do nó do OpenShift (por exemplo, usando MachineConfig).

## Desinstalação

Para desinstalar o chart:

```bash
helm uninstall archivematica -n archivematica
```

**Importante:** A desinstalação removerá todos os recursos criados pelo Helm, mas **não** removerá os PersistentVolumeClaims (PVCs) por padrão. Isso é para evitar a perda acidental de dados. Se você deseja remover os PVCs e os dados associados, você precisa excluí-los manualmente:

```bash
oc delete pvc -l app.kubernetes.io/instance=archivematica -n archivematica
oc delete pvc -l app.kubernetes.io/component=mysql,app.kubernetes.io/instance=archivematica -n archivematica
oc delete pvc -l app.kubernetes.io/component=elasticsearch,app.kubernetes.io/instance=archivematica -n archivematica
oc delete pvc -l app.kubernetes.io/component=redis,app.kubernetes.io/instance=archivematica -n archivematica
oc delete pvc -l app.kubernetes.io/component=clamav,app.kubernetes.io/instance=archivematica -n archivematica
```


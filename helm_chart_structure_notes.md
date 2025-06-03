# Estrutura de Helm Charts para Archivematica no OpenShift

## Estrutura Básica de um Helm Chart

Um Helm chart é organizado como uma coleção de arquivos dentro de um diretório. A estrutura básica é a seguinte:

```
archivematica/
  Chart.yaml          # Arquivo YAML com informações sobre o chart
  LICENSE             # OPCIONAL: Arquivo de texto com a licença do chart
  README.md           # OPCIONAL: Arquivo README legível por humanos
  values.yaml         # Valores de configuração padrão para este chart
  values.schema.json  # OPCIONAL: Schema JSON para impor estrutura no arquivo values.yaml
  charts/             # Diretório contendo charts dos quais este chart depende
  crds/               # Custom Resource Definitions
  templates/          # Diretório de templates que, quando combinados com values,
                      # gerarão arquivos de manifesto Kubernetes válidos
  templates/NOTES.txt # OPCIONAL: Arquivo de texto com notas de uso breves
```

## Arquivo Chart.yaml

O arquivo `Chart.yaml` é obrigatório e contém os seguintes campos principais:

```yaml
apiVersion: v2                 # Versão da API do chart (obrigatório)
name: archivematica            # Nome do chart (obrigatório)
version: 0.1.0                 # Versão SemVer 2 (obrigatório)
kubeVersion: ">=1.18.0"        # Intervalo SemVer de versões Kubernetes compatíveis (opcional)
description: Helm chart para implantar Archivematica no OpenShift
type: application              # Tipo do chart (opcional)
keywords:                      # Lista de palavras-chave sobre este projeto (opcional)
  - archivematica
  - preservação digital
  - openshift
home: https://www.archivematica.org  # URL da página inicial deste projeto (opcional)
sources:                       # Lista de URLs para o código-fonte deste projeto (opcional)
  - https://github.com/artefactual/archivematica
dependencies:                  # Lista de requisitos do chart (opcional)
  - name: mysql
    version: "8.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: mysql.enabled
  - name: elasticsearch
    version: "7.x.x"
    repository: "https://helm.elastic.co"
    condition: elasticsearch.enabled
maintainers:                   # (opcional)
  - name: Nome do Mantenedor
    email: email@exemplo.com
appVersion: "1.13.2"           # Versão do app que este chart contém (opcional)
```

## Requisitos Específicos para OpenShift

Para que o Helm chart funcione corretamente no OpenShift, é necessário considerar:

1. **Security Context Constraints (SCCs)**: OpenShift tem restrições de segurança mais rígidas que o Kubernetes padrão.
   - Evitar `privileged: true` nos contêineres
   - Configurar `securityContext` com UIDs/GIDs não-root
   - Possivelmente criar uma SCC personalizada ou usar `anyuid`/`nonroot`

2. **Routes vs Ingress**: OpenShift usa Routes em vez de Ingress para expor serviços.
   - Incluir templates para Routes do OpenShift

3. **ImageStreams**: Considerar o uso de ImageStreams do OpenShift para gerenciar imagens.

4. **DeploymentConfigs vs Deployments**: OpenShift tradicionalmente usa DeploymentConfigs, mas Deployments padrão do Kubernetes também funcionam.

## Componentes do Archivematica

Baseado na pesquisa, o Archivematica é composto pelos seguintes componentes principais que precisarão ser incluídos no Helm chart:

1. **Dashboard**: Interface web para usuários processarem, monitorarem e controlarem os processos do Archivematica
2. **Storage Service**: Serviço para configurar espaços de armazenamento
3. **MCP Server**: Servidor de processamento de microserviços
4. **MCP Client**: Cliente para executar tarefas de processamento
5. **Gearman**: Servidor de filas de trabalho
6. **MySQL**: Banco de dados para metadados
7. **Elasticsearch**: Para indexação e busca
8. **Redis**: Para cache e filas
9. **ClamAV**: Para verificação de vírus
10. **Fits**: Para identificação e validação de formatos

## Estrutura de Diretórios para o Helm Chart do Archivematica

```
archivematica-helm-chart/
  Chart.yaml
  values.yaml
  templates/
    deployments/
        am-dashboard.yaml       # Deployment para o Dashboard
        am-storage-service.yaml # Deployment para o Storage Service
        mcp-server.yaml         # Deployment para o MCP Server
        mcp-client.yaml         # Deployment para o MCP Client
        gearmand.yaml           # Deployment para o Gearman
        clamav.yaml             # Deployment para o ClamAV
        fits.yaml               # Deployment para o Fits
    statefulsets/
        mysql.yaml              # Statefulset para mysql
        redis.yaml              # Statefulset para redis
        elasticsearch.yaml      # Statefulset para elasticsearch
    _helpers.tpl                    # Helpers para templates
    configmap.yaml                  # ConfigMaps para configuração
    pvc.yaml                        # PersistentVolumeClaims para armazenamento
    route.yaml                      # Route para o Dashboard e Storage Service (específico do OpenShift)
    secret.yaml                     # Secrets para senhas e chaves
    serviceaccount.yaml             # ServiceAccount para os pods
    scc.yaml                        # SecurityContextConstraints (específico do OpenShift)    
  charts/                           # Subcharts (se não usar dependências externas)
```

## Considerações para o arquivo values.yaml

O arquivo `values.yaml` deve incluir configurações para:

1. **Imagens e tags**: URLs e tags das imagens dos contêineres
2. **Recursos**: Limites e solicitações de CPU e memória
3. **Persistência**: Configurações para volumes persistentes
4. **Segurança**: UIDs, GIDs, contextos de segurança
5. **Rede**: Configurações de host, portas, etc.
6. **Configurações específicas do Archivematica**: Chaves de API, configurações de processamento, etc.
7. **Configurações específicas do OpenShift**: Namespace, rotas, etc.


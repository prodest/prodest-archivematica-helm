# Anotações

## Passo a passo

* Foi criado um conjunto de templates para atender a publicação do Archivematica
* Após testar os templates foi necessário ajuste para criação de uma conta de serviço "anyuid" para atender os deployments que necessidade de permissão especial para subir, até o momento: archivematica-gearmand
* Ajustado o Clamav, necessario a criação de um init container
* Foi feito a criação do banco, análise do Makefile
* Ajustando as variáveis de ambiente





08/06
TO DO: Colocar secrets fixos

ref.:
https://gitlab.cern.ch/digitalmemory/archivematica-helm





Traceback (most recent call last):
  File "/src/src/MCPServer/lib/archivematicaMCP.py", line 2, in <module>
    from server.mcp import main
  File "/src/src/MCPServer/lib/server/mcp.py", line 33, in <module>
    django.setup()
  File "/pyenv/data/versions/3.9.22/lib/python3.9/site-packages/django/__init__.py", line 19, in setup
    configure_logging(settings.LOGGING_CONFIG, settings.LOGGING)
  File "/pyenv/data/versions/3.9.22/lib/python3.9/site-packages/django/conf/__init__.py", line 102, in __getattr__
    self._setup(name)
  File "/pyenv/data/versions/3.9.22/lib/python3.9/site-packages/django/conf/__init__.py", line 89, in _setup
    self._wrapped = Settings(settings_module)
  File "/pyenv/data/versions/3.9.22/lib/python3.9/site-packages/django/conf/__init__.py", line 217, in __init__
    mod = importlib.import_module(self.SETTINGS_MODULE)
  File "/pyenv/data/versions/3.9.22/lib/python3.9/importlib/__init__.py", line 127, in import_module
    return _bootstrap._gcd_import(name[level:], package, level)
ModuleNotFoundError: No module named 'archivematica'


W0609 10:25:56.084465   26084 warnings.go:70] unknown field "spec.template.spec.containers[0].securityContext.envFrom"
Error: INSTALLATION FAILED: 3 errors occurred:
        * PersistentVolumeClaim "archivematica-clamav-db" is invalid: spec.accessModes: Unsupported value: "ReadWriteOnce# Valores padrão para o Helm chart do Archivematica para OpenShift": supported values: "ReadOnlyMany", "ReadWriteMany", "ReadWriteOnce", "ReadWriteOncePod"
        * Deployment in version "v1" cannot be handled as a Deployment: json: cannot unmarshal number into Go struct field EnvVar.spec.template.spec.containers.env.value of type string
        * Deployment.apps "archivematica-dashboard" is invalid: spec.template.spec.containers[0].imagePullPolicy: Unsupported value: "IfNotPresent# Configurações de imagem e persistência para o Storage Service": supported values: "Always", "IfNotPresent", "Never"


{APIGroups:["security.openshift.io"], Resources:["securitycontextconstraints"], ResourceNames:["anyuid"], Verbs:["use"]}

## Sobre o clamav


ref : 
https://docs.clamav.net/manual/Installing/Docker.html
https://www.archivematica.org/en/docs/archivematica-1.17/admin-manual/installation-setup/customization/antivirus-admin/

requerimentos mínimos:
Minimum: 3 GiB
Preferred: 4 GiB

Não baixar a versão do artefectual/clamav... pois está a 7 anos sem atualização!

{{/*
Helpers comuns para o Helm chart do Archivematica.
*/}}

{{/*
Expandir o nome do chart.
*/}}
{{- define "archivematica.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Criar um nome completo padrão para o chart.
*/}}
{{- define "archivematica.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Nome do chart e versão.
*/}}
{{- define "archivematica.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Labels comuns
*/}}
{{- define "archivematica.labels" -}}
helm.sh/chart: {{ include "archivematica.chart" . }}
{{ include "archivematica.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Labels do seletor
*/}}
{{- define "archivematica.selectorLabels" -}}
app.kubernetes.io/name: {{ include "archivematica.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Nome do Service Account a ser usado
*/}}
{{- define "archivematica.serviceAccountName" -}}
{{- if .Values.security.serviceAccount.create -}}
    {{ default (include "archivematica.fullname" .) .Values.security.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.security.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Nome do componente (usado para nomear recursos)
*/}}
{{- define "archivematica.component.fullname" -}}
{{- $componentName := index . 1 -}}
{{- printf "%s-%s" (include "archivematica.fullname" (index . 0)) $componentName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Labels do seletor para um componente específico
*/}}
{{- define "archivematica.component.selectorLabels" -}}
{{ include "archivematica.selectorLabels" (index . 0) }}
app.kubernetes.io/component: {{ index . 1 }}
{{- end -}}

{{/*
Labels para um componente específico
*/}}
{{- define "archivematica.component.labels" -}}
{{ include "archivematica.labels" (index . 0) }}
app.kubernetes.io/component: {{ index . 1 }}
{{- end -}}


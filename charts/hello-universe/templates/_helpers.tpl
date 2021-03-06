{{/* vim: set filetype=mustache: */}}

{{/*
Renders nodeAffinity block in the manifests
*/}}

{{/*
Renders nodeSelector block in the manifests
*/}}

{{- define "app.nodeLabels" }}
{{- if . }}
nodeSelector:
  {{ toYaml . }}
{{- end -}}
{{- end -}}

{{- define "app.affinity" }}
affinity:
  {{- if .nodeAffinityLabels }}
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            {{- range $index, $label := .nodeAffinityLabels }}
            - key: {{ $label.name }}
              operator: In
              values:
                - {{ $label.value }}
            {{- end }}
  {{- end }}
  {{- if .podAntiAffinity }}
  podAntiAffinity:
  {{- if eq .podAntiAffinity.type "required" }}
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            {{- range $index, $label := .podAntiAffinity.labels }}
            - key: {{ $label.name }}
              operator: In
              values:
                - {{ $label.value }}
            {{- end }}
        topologyKey: kubernetes.io/hostname
    {{- end }}
    {{- if eq .podAntiAffinity.type "preferred" }}
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              {{- range $index, $label := .podAntiAffinity.labels }}
              - key: {{ $label.name }}
                operator: In
                values:
                  - {{ $label.value }}
              {{- end }}
          topologyKey: kubernetes.io/hostname
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "app.configmap" }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .configMap.name }}
  namespace: {{ .namespace }}
data:
{{- if .configMap.data -}}
{{- toYaml .configMap.data | nindent 2 }}
{{- else if .configMap.file }}
  {{- (.root.Files.Glob (printf "%s" .configMap.file)).AsConfig | nindent 2 }}
{{- end -}}
{{- end }}

{{/*
Renders secret based on the secrets.yaml
*/}}
{{- define "app.secret" -}}
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: {{ .secret.name }}
  namespace: {{ .namespace }}
data:
{{- if .secret.data -}}
{{- toYaml .secret.data | nindent 2 }}
{{- else if .secret.file }}
  {{- (.root.Files.Glob (printf "%s" .secret.file)).AsSecrets | nindent 2 }}
{{- end -}}
{{- end }}

{{/*
Renders VolumeMounts for the Container in a Pod
*/}}
{{- define "app.containerVolumeMounts" -}}
{{- range $index, $volumeMountData := . -}}
{{- if and ($volumeMountData.file) ($volumeMountData.mountPath) }}
- mountPath: {{ $volumeMountData.mountPath }}
  subPath: {{ $volumeMountData.file }}
  name: {{ $volumeMountData.name }}
  readOnly: true
{{- end }}
{{- end }}
{{- end -}}

{{/*
Renders VolumeMounts for the Pod
*/}}
{{- define "app.podVolumes" -}}
{{- if eq .type "secrets" }}
{{- range .secrets -}}
- secret:
    secretName: {{ .name }}
  name: {{ .name }}
{{ end }}
{{- else -}}
{{- range .configMaps -}}
- configMap:
    name: {{ .name }}
  name: {{ .name }}
{{ end }}
{{- end -}}
{{- end -}}

{{/*
Renders Pod Annotations. Handy to roll the Pod as and when a configmap/secret changes.
*/}}
{{- define "app.podAnnotations" -}}
{{- $root := . }}
{{- $namespace := .Values.namespace }}
annotations:
  checksum/infra-secrets: {{ include (print $.Template.BasePath "/infra-secrets.yaml") . | sha256sum }}
  checksum/configmap: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
  checksum/secrets: {{ include (print $.Template.BasePath "/secreds.yaml") . | sha256sum }}
{{- end }}

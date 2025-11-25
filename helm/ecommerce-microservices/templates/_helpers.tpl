{{/*
Expand the name of the chart.
*/}}
{{- define "ecommerce-microservices.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "ecommerce-microservices.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ecommerce-microservices.labels" -}}
helm.sh/chart: {{ include "ecommerce-microservices.chart" . }}
{{ include "ecommerce-microservices.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ecommerce-microservices.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ecommerce-microservices.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Chart name and version
*/}}
{{- define "ecommerce-microservices.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Microservice deployment template
*/}}
{{- define "microservice.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .name }}
  namespace: {{ $.Values.global.namespace }}
  labels:
    app: {{ .name }}
    version: v1
spec:
  replicas: {{ .replicas | default 1 }}
  selector:
    matchLabels:
      app: {{ .name }}
  template:
    metadata:
      labels:
        app: {{ .name }}
        version: v1
    spec:
      containers:
      - name: {{ .name }}
        image: "{{ $.Values.global.registry }}/{{ .name }}:{{ $.Values.global.imageTag }}"
        imagePullPolicy: {{ $.Values.global.imagePullPolicy }}
        ports:
        - containerPort: {{ .port }}
        envFrom:
        - configMapRef:
            name: micro-config
        resources:
          {{- toYaml (.resources | default $.Values.global.resources) | nindent 10 }}
        readinessProbe:
          httpGet:
            path: {{ .healthCheck.path }}
            port: {{ .port }}
          initialDelaySeconds: {{ (.healthCheck.readiness.initialDelaySeconds | default $.Values.global.healthCheck.readiness.initialDelaySeconds) }}
          periodSeconds: {{ (.healthCheck.readiness.periodSeconds | default $.Values.global.healthCheck.readiness.periodSeconds) }}
          timeoutSeconds: {{ (.healthCheck.readiness.timeoutSeconds | default $.Values.global.healthCheck.readiness.timeoutSeconds) }}
          failureThreshold: {{ (.healthCheck.readiness.failureThreshold | default $.Values.global.healthCheck.readiness.failureThreshold) }}
        livenessProbe:
          httpGet:
            path: {{ .healthCheck.path }}
            port: {{ .port }}
          initialDelaySeconds: {{ (.healthCheck.liveness.initialDelaySeconds | default $.Values.global.healthCheck.liveness.initialDelaySeconds) }}
          periodSeconds: {{ (.healthCheck.liveness.periodSeconds | default $.Values.global.healthCheck.liveness.periodSeconds) }}
          timeoutSeconds: {{ (.healthCheck.liveness.timeoutSeconds | default $.Values.global.healthCheck.liveness.timeoutSeconds) }}
          failureThreshold: {{ (.healthCheck.liveness.failureThreshold | default $.Values.global.healthCheck.liveness.failureThreshold) }}
{{- end }}

{{/*
Microservice service template
*/}}
{{- define "microservice.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .name }}
  namespace: {{ $.Values.global.namespace }}
  labels:
    app: {{ .name }}
spec:
  selector:
    app: {{ .name }}
  ports:
  - port: {{ .port }}
    targetPort: {{ .port }}
    {{- if and (eq .serviceType "NodePort") .nodePort }}
    nodePort: {{ .nodePort }}
    {{- end }}
    protocol: TCP
  type: {{ .serviceType | default "ClusterIP" }}
{{- end }}



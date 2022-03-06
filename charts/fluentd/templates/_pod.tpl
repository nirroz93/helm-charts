{{- define "fluentd.pod" -}}
{{- $defaultTag := printf "%s-debian-elasticsearch7-1.0" (.Chart.AppVersion) -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- if .Values.priorityClassName }}
priorityClassName: {{ .Values.priorityClassName }}
{{- end }}
serviceAccountName: {{ include "fluentd.serviceAccountName" . }}
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 2 }}
{{- with .Values.terminationGracePeriodSeconds }}
terminationGracePeriodSeconds: {{ . }}
{{- end }}
containers:
  - name: {{ .Chart.Name }}
    securityContext:
      {{- toYaml .Values.securityContext | nindent 6 }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default $defaultTag }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
  {{- if .Values.plugins }}
    command:
    - "/bin/sh"
    - "-c"
    - |
      {{- range $plugin := .Values.plugins }}
        {{- print "fluent-gem install " $plugin | nindent 6 }}
      {{- end }}
      exec /fluentd/entrypoint.sh
  {{- end }}
  {{- if .Values.env }}
    env:
    {{- toYaml .Values.env | nindent 6 }}
  {{- end }}
  {{- if .Values.envFrom }}
    envFrom:
    {{- toYaml .Values.envFrom | nindent 6 }}
  {{- end }}
    ports:
    - name: metrics
      containerPort: 24231
      protocol: TCP
    {{- range $port := .Values.service.ports }}
    - name: {{ $port.name }}
      containerPort: {{ $port.containerPort }}
      protocol: {{ $port.protocol }}
    {{- end }}
    {{- with .Values.lifecycle }}
    lifecycle:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    livenessProbe:
      {{- toYaml .Values.livenessProbe | nindent 6 }}
    readinessProbe:
      {{- toYaml .Values.readinessProbe | nindent 6 }}
    resources:
      {{- toYaml .Values.resources | nindent 8 }}
    volumeMounts:
      {{- toYaml .Values.volumeMounts | nindent 6 }}
      {{ range $key := .Values.configMapConfigs }}
      - name: fluentd-custom-cm-{{ $key }}
        mountPath: /etc/fluent/{{ $key }}.d
      {{ end }}
      - name: main
        mountPath: /etc/fluent/
      - name: config
        mountPath: /etc/fluent/config.d/
      {{ if .Values.persistence.enabled }}
      - mountPath: /var/log/fluent
        name: {{ include "fluentd.fullname" . }}-buffer
      {{- end }}
volumes:
  {{- toYaml .Values.volumes | nindent 2 }}
  {{- range $key := .Values.configMapConfigs }}
  - name: fluentd-custom-cm-{{ $key }}
    configMap:
      name: {{ include "fluentd.fullname" $ }}-{{ . }}
      defaultMode: 0777
  {{- end }}
  - name: main
    configMap:
      name: {{ include "fluentd.fullname" $ }}-main
      defaultMode: 0777
  - name: config
    configMap:
      name: {{ include "fluentd.fullname" $ }}-config
      defaultMode: 0777
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}

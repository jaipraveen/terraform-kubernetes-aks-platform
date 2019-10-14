module "helm_istio" {
  source = "git::https://github.com/statcan/terraform-kubernetes-istio.git"

  chart_version = "1.3.1"
  dependencies = [
    "${module.namespace_istio_system.depended_on}",
  ]

  helm_service_account = "tiller"
  helm_namespace = "istio-system"
  helm_repository = "istio"

  kiali_username = "admin"
  kiali_password = "admin"

  values = <<EOF
# Use a specific image
global:
  # tag: release-1.1-latest-daily

  k8sIngress:
    enabled: true
    enableHttps: true

  controlPlanSecurityEnabled: true
  disablePolicyChecks: false
  policyCheckFailOpen: false
  enableTracing: false

  mtls:
    enabled: true

  outboundTrafficPolicy:
    mode: ALLOW_ANY

sidecarInjectorWebhook:
  enabled: true
  # If true, webhook or istioctl injector will rewrite PodSpec for liveness
  # health check to redirect request to sidecar. This makes liveness check work
  # even when mTLS is enabled.
  rewriteAppHTTPProbe: true

gateways:
  istio-ingressgateway:
    sds:
      enabled: true
    # serviceAnnotations:
    #   service.beta.kubernetes.io/azure-load-balancer-internal: 'true'

kiali:
  enabled: true
  contextPath: /*
  ingress:
    enabled: true
    ## Used to create an Ingress record.
    hosts:
      - istio-kiali.${var.ingress_domain}
    annotations:
      # kubernetes.io/ingress.class: nginx
      # kubernetes.io/tls-acme: "true"
      kubernetes.io/ingress.class: "istio"
    tls:
      # Secrets must be manually created in the namespace.
      # - secretName: kiali-tls
      #   hosts:
      #     - kiali.local

  dashboard:
    grafanaURL: https://istio-grafana.${var.ingress_domain}

grafana:
  enabled: true
  contextPath: /*
  ingress:
    enabled: true
    ## Used to create an Ingress record.
    hosts:
      - istio-grafana.${var.ingress_domain}
    annotations:
      # kubernetes.io/ingress.class: nginx
      # kubernetes.io/tls-acme: "true"
      kubernetes.io/ingress.class: "istio"
    tls:
      # Secrets must be manually created in the namespace.
      # - secretName: grafana-tls
      #   hosts:
      #     - grafana.local

prometheus:
  enabled: true
EOF
}

resource "null_resource" "add_https_to_ingress_gateway" {
  provisioner "local-exec" {
    command = "kubectl -n istio-system patch gateway istio-autogenerated-k8s-ingress --type=json -p='[{\"op\": \"replace\", \"path\": \"/spec/servers/1/tls\", \"value\": {\"credentialName\": \"wildcard-tls\", \"mode\": \"SIMPLE\", \"privateKey\": \"sds\", \"serverCertificate\": \"sds\"}}]'"
  }

  provisioner "local-exec" {
    command = "kubectl -n istio-system patch gateway istio-autogenerated-k8s-ingress --type=json -p='[{\"op\": \"replace\", \"path\": \"/spec/servers/0/tls\", \"value\": {\"httpsRedirect\": true}}]'"
  }

  depends_on = [
    "module.helm_istio"
  ]
}

#!/usr/bin/env bash
# =============================================================================
# generar-kubeconfig.sh
# Laboratorio 016 — GCP Fundamentos
# Repositorio: https://github.com/jeschb/gcp-labs-gke
#
# Propósito: Generar un archivo kubeconfig con token estático para conectarse
#            al clúster GKE desde una laptop sin gcloud instalado.
#
# Ejecutar desde Cloud Shell una vez que el clúster esté activo y el
# namespace gcplab-gke exista.
#
# Uso: bash devops/generar-kubeconfig.sh
# =============================================================================

set -euo pipefail

NAMESPACE="gcplab-gke"
SA_NAME="lab-admin"
SECRET_NAME="lab-admin-token"
CLUSTER_NAME="gke-lab-cluster"
OUTPUT_FILE="kubeconfig-lab016.yaml"

echo "============================================="
echo " Generador de kubeconfig — Lab 016 GKE"
echo "============================================="

# ── 1. Verificar que kubectl tiene contexto activo ─────────────────────────
echo ""
echo "[1/6] Verificando conexión al clúster..."
kubectl cluster-info --request-timeout=10s > /dev/null
echo "      ✔ Conexión OK: $(kubectl config current-context)"

# ── 2. Crear ServiceAccount ────────────────────────────────────────────────
echo ""
echo "[2/6] Creando ServiceAccount '${SA_NAME}' en namespace '${NAMESPACE}'..."
if kubectl get serviceaccount "${SA_NAME}" -n "${NAMESPACE}" &>/dev/null; then
  echo "      ℹ  ServiceAccount ya existe, se omite creación."
else
  kubectl create serviceaccount "${SA_NAME}" -n "${NAMESPACE}"
  echo "      ✔ ServiceAccount creado."
fi

# ── 3. Crear ClusterRoleBinding ────────────────────────────────────────────
echo ""
echo "[3/6] Asignando ClusterRoleBinding cluster-admin..."
if kubectl get clusterrolebinding lab-admin-binding &>/dev/null; then
  echo "      ℹ  ClusterRoleBinding ya existe, se omite creación."
else
  kubectl create clusterrolebinding lab-admin-binding \
    --clusterrole=cluster-admin \
    --serviceaccount="${NAMESPACE}:${SA_NAME}"
  echo "      ✔ ClusterRoleBinding creado."
fi

# ── 4. Crear Secret con token permanente (K8s ≥ 1.24) ──────────────────────
echo ""
echo "[4/6] Creando Secret de token para el ServiceAccount..."
if kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" &>/dev/null; then
  echo "      ℹ  Secret ya existe, se omite creación."
else
  kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
  namespace: ${NAMESPACE}
  annotations:
    kubernetes.io/service-account.name: ${SA_NAME}
type: kubernetes.io/service-account-token
EOF
  echo "      ✔ Secret creado. Esperando propagación del token..."
  sleep 8
fi

# ── 5. Extraer valores del kubeconfig ──────────────────────────────────────
echo ""
echo "[5/6] Extrayendo credenciales del clúster..."

TOKEN=$(kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" \
  -o jsonpath='{.data.token}' | base64 -d)

CA_CERT=$(kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" \
  -o jsonpath='{.data.ca\.crt}')

SERVER=$(kubectl config view --minify \
  -o jsonpath='{.clusters[0].cluster.server}')

if [[ -z "${TOKEN}" || -z "${CA_CERT}" || -z "${SERVER}" ]]; then
  echo "      ✖ Error: no se pudieron extraer todos los valores. Verifica el Secret."
  exit 1
fi
echo "      ✔ Servidor  : ${SERVER}"
echo "      ✔ Token     : ${TOKEN:0:20}... (truncado por seguridad)"
echo "      ✔ CA Cert   : OK"

# ── 6. Generar archivo kubeconfig ─────────────────────────────────────────
echo ""
echo "[6/6] Generando archivo '${OUTPUT_FILE}'..."

cat > "${OUTPUT_FILE}" <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${CA_CERT}
    server: ${SERVER}
  name: ${CLUSTER_NAME}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    namespace: ${NAMESPACE}
    user: ${SA_NAME}
  name: lab016-context
current-context: lab016-context
users:
- name: ${SA_NAME}
  user:
    token: ${TOKEN}
EOF

echo "      ✔ Archivo generado: ${OUTPUT_FILE}"

# ── Resumen final ──────────────────────────────────────────────────────────
echo ""
echo "============================================="
echo " ¡Kubeconfig generado exitosamente!"
echo "============================================="
echo ""
echo " Próximos pasos:"
echo "   1. Descarga el archivo desde Cloud Shell:"
echo "      Menú ⋮ → Descargar archivo → ${OUTPUT_FILE}"
echo ""
echo "   2. En tu laptop (Windows PowerShell):"
echo "      \$env:KUBECONFIG = 'C:\\Users\\TU_USUARIO\\.kube\\kubeconfig-lab016.yaml'"
echo "      kubectl get pods -n ${NAMESPACE}"
echo ""
echo "   2. En tu laptop (Linux / Mac):"
echo "      export KUBECONFIG=~/kubeconfig-lab016.yaml"
echo "      kubectl get pods -n ${NAMESPACE}"
echo ""

# Laboratorio: Despliegue de una app Node.js en GKE con Helm

Este laboratorio guía al estudiante para construir, contenerizar y desplegar una aplicación web sencilla en **Google Kubernetes Engine (GKE)** usando **Helm**.

La idea es aprender el flujo completo:

1. Crear una app Node.js con una landing page atractiva.
2. Construir una imagen Docker.
3. Publicarla en un registry de GCP.
4. Desplegarla en Kubernetes con un Helm chart parametrizable.

Autor del material:

- **Ing. Jesús Antonio Chávez Becerra**
- **Correo:** jeschb@gmail.com
- **Centro de trabajo:** devsecops.pe

---

## Estructura del repositorio

```text
.
├── app/
│   ├── Dockerfile
│   ├── package.json
│   ├── server.js
│   └── public/
│       ├── index.html
│       └── styles.css
├── devops/
│   └── helm-chart/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── _helpers.tpl
│           ├── configmap.yaml
│           ├── deployment.yaml
│           ├── secret.yaml
│           ├── service.yaml
│           └── ingress.yaml
└── README.md
```

---

## Objetivo del laboratorio

Al finalizar, el estudiante podrá:

- construir una imagen Docker de una aplicación Node.js;
- subir la imagen a un registry de GCP;
- instalar Helm y usar un chart propio;
- personalizar el despliegue desde `values.yaml`;
- exponer la app mediante un `Service` y, opcionalmente, `Ingress`.

---

## Requisitos previos

Antes de empezar, asegúrate de contar con:

- una cuenta de Google Cloud;
- un proyecto de GCP activo;
- `gcloud` instalado y autenticado;
- acceso a un clúster GKE;
- `docker` instalado;
- `helm` instalado;
- `kubectl` instalado.

### Verificación rápida

```bash
gcloud version
docker --version
helm version
kubectl version --client
```

---

## 1. La aplicación

La aplicación está ubicada en la carpeta [`app`](./app).

Es una landing page simple hecha con Node.js y Express. Su propósito es mostrar una página atractiva que hable de GKE en GCP, con estilo visual basado en los colores de Google Cloud.

### Qué incluye

- página principal con mensaje de bienvenida;
- sección de beneficios de GKE;
- panel de credenciales visibles en la interfaz;
- estilos modernos con gradientes, tarjetas y tipografía limpia;
- servidor preparado para ejecutarse en local o dentro de un contenedor.

### Créditos visibles

La página incluye en todo momento:

- **Ing. Jesús Antonio Chávez Becerra**
- **jeschb@gmail.com**
- **devsecops.pe**

---

## 2. Ejecutar la app en local

Entra a la carpeta de la aplicación:

```bash
cd app
```

Instala dependencias:

```bash
npm install
```

Arranca la aplicación:

```bash
npm start
```

Abre en tu navegador:

```text
http://localhost:3000
```

---

## 3. Construir la imagen Docker

Desde la carpeta `app`:

```bash
docker build -t gke-lab-app:1.0.0 .
```

Probar localmente:

```bash
docker run --rm -p 8080:8080 gke-lab-app:1.0.0
```

Luego abre:

```text
http://localhost:8080
```

---

## 4. Subir la imagen a un registry de GCP

Aquí debes reemplazar el valor del registry por el que uses en tu práctica.

### Placeholder para el registry

Usa un nombre como este:

```text
REGISTRY_GCP_AQUI
```

### Ejemplo de tag

```bash
docker tag gke-lab-app:1.0.0 REGISTRY_GCP_AQUI/gke-lab-app:1.0.0
docker push REGISTRY_GCP_AQUI/gke-lab-app:1.0.0
```

Si usas Artifact Registry, tu ruta se parecerá a algo como esto:

```text
REGION-docker.pkg.dev/PROYECTO/REPOSITORIO/gke-lab-app:1.0.0
```

Importante:

- deja el espacio del registry editable para el estudiante;
- no asumas un nombre fijo de proyecto;
- usa el valor real cuando vayas a desplegar.

---

## 5. Helm chart

El chart está en [`devops/helm-chart`](./devops/helm-chart).

Este chart está pensado para que el estudiante pueda modificar fácilmente:

- nombre de la aplicación;
- nombre de la imagen;
- tag de la imagen;
- número de réplicas;
- `ConfigMap` y `Secret` opaco;
- puerto de servicio;
- configuración de Ingress.

### Archivos principales

- `Chart.yaml`: metadatos del chart.
- `values.yaml`: variables editables.
- `templates/deployment.yaml`: despliegue de Kubernetes.
- `templates/service.yaml`: servicio interno/expuesto.
- `templates/ingress.yaml`: exposición HTTP opcional.

---

## 6. Desplegar con Helm

Primero revisa `values.yaml` y coloca tus datos.

### Campos que debes ajustar

```yaml
image:
  repository: "REGISTRY_GCP_AQUI/REPOSITORIO/gke-lab-app"
  tag: "1.0.0"
```

Si tu registry es distinto, reemplaza ese valor.

### Instalar el chart

Desde la raíz del repositorio:

```bash
helm install gke-lab ./devops/helm-chart
```

### Actualizar el despliegue

Si cambiaste imagen o valores:

```bash
helm upgrade gke-lab ./devops/helm-chart
```

### Ver el estado

```bash
helm list
kubectl get pods
kubectl get svc
kubectl get ingress
```

---

## 7. Exposición de la aplicación

Para una práctica simple y directa en GKE, la opción más fácil es:

- `Service type: LoadBalancer`

Con eso, GKE te crea una **IP externa** para el servicio. No es una URL bonita por sí sola, pero sí te deja publicar la aplicación hacia internet sin agregar Ingress en esta primera versión del laboratorio.

### Qué usar en GKE

Si quieres una solución rápida para aprender, mi recomendación aquí es:

1. dejar el `Service` como `LoadBalancer`;
2. desplegar el chart;
3. revisar `kubectl get svc`;
4. tomar la IP que aparezca en `EXTERNAL-IP`.

Si más adelante quieres una exposición más profesional con dominio, TLS y rutas, ahí sí conviene evolucionar a `Ingress`.

```yaml
service:
  type: LoadBalancer
```

Eso te devolverá una IP externa cuando el servicio quede listo.

### ConfigMap y Secret

Este chart también crea:

- un `ConfigMap` con variables no sensibles;
- un `Secret` opaco para datos que quieras tratar como sensibles, ingresados en Base64;
- inyección automática de ambos en el contenedor mediante `envFrom`.

Puedes editar sus valores en `values.yaml`.

### Formato del Secret

En este laboratorio, los valores del `Secret` deben estar en **Base64** porque el manifiesto usa el bloque `data` de Kubernetes.

Ejemplo:

```bash
echo -n "Ing. Jesús Antonio Chávez Becerra" | base64
echo -n "jeschb@gmail.com" | base64
echo -n "devsecops.pe" | base64
```

Si quieres crear tus propios valores, reemplaza el contenido de `secret.data` con el resultado codificado.

### Acceso local con port-forward

```bash
kubectl port-forward svc/gke-lab 8080:80
```

Abre:

```text
http://localhost:8080
```

### Exposición externa con LoadBalancer

Con este laboratorio, `service.type` ya queda en `LoadBalancer` por defecto, así que al instalar el chart Kubernetes/GKE pedirá una IP pública para el servicio.

Luego revisa:

```bash
kubectl get svc
```

Cuando `EXTERNAL-IP` deje de estar en `<pending>`, podrás abrir la app desde esa dirección.

---

## 8. Personalización del estudiante

Se recomienda que el estudiante cambie:

- el nombre de la imagen;
- el tag;
- el nombre del release de Helm;
- los valores de Ingress;
- el contenido visual de la landing page.

Esto ayuda a practicar el flujo completo de entrega a GKE.

---

## 9. Qué aprenderás con este laboratorio

- estructura base de una app web simple;
- Dockerfile para producción;
- publicación de imágenes;
- parametrización con Helm;
- despliegue a Kubernetes;
- buenas prácticas de organización de un laboratorio.

---

## 10. Créditos

Material preparado para práctica académica y técnica.

- **Ing. Jesús Antonio Chávez Becerra**
- **jeschb@gmail.com**
- **devsecops.pe**

---

## 11. Notas para el docente

Si quieres ajustar el laboratorio para tu clase, puedes cambiar:

- nombres de release;
- puertos;
- cantidad de réplicas;
- recursos CPU/memoria;
- reglas de Ingress;
- textos de la landing page.

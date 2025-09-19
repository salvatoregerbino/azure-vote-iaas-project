Questo file, `azure-vote-all-in-one-redis.yaml`, è il cuore dell'implementazione su Kubernetes. A differenza del `docker-compose.yml` che orchestra i container a livello locale, questo file definisce le risorse necessarie per far funzionare l'applicazione in un ambiente di produzione come Azure Kubernetes Service (AKS).

Il file contiene quattro oggetti Kubernetes distinti, separati da `---`. Analizziamoli uno per uno.

### 1. Deployment del Backend (Redis)
Questo blocco definisce come l'istanza di Redis verrà gestita all'interno del cluster Kubernetes.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: azure-vote-back
spec:
  replicas: 1
  selector:
    matchLabels:
      app: azure-vote-back
  template:
    metadata:
      labels:
        app: azure-vote-back
    spec:
      containers:
      - name: azure-vote-back
        image: [mcr.microsoft.com/oss/bitnami/redis:6.0.8](https://mcr.microsoft.com/oss/bitnami/redis:6.0.8)
        env:
        - name: ALLOW_EMPTY_PASSWORD
          value: "yes"
        ports:
        - containerPort: 6379```

* **`kind: Deployment`**: Indica a Kubernetes di creare un Deployment, che è una risorsa di alto livello che gestisce i pod e ne assicura lo stato desiderato.

* **`replicas: 1`**: Specifica che vogliamo una sola copia del container Redis in esecuzione.

* **`selector`** e **`template`**: Questi due campi sono fondamentali. Il `selector` dice al Deployment di gestire tutti i pod che hanno l'etichetta (`label`) `app: azure-vote-back`. Il `template` definisce la configurazione dei pod che verranno creati.

* **`image`**: L'immagine container è la stessa del `docker-compose.yml`, garantendo coerenza tra ambiente locale e cloud.

* **`env`**: Riproduce la variabile d'ambiente `ALLOW_EMPTY_PASSWORD` per avviare Redis senza password, esattamente come nell'ambiente locale.

* **`ports`**: Espone la porta `6379` all'interno del pod, rendendola accessibile agli altri servizi del cluster.

### 2. Service del Backend (Redis)

Questo Service fornisce un nome di rete e un punto di accesso stabile al Deployment di Redis, a prescindere da quale pod specifico sia in esecuzione.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: azure-vote-back
spec:
  ports:
  - port: 6379
  selector:
    app: azure-vote-back```

* **`kind: Service`**: Indica la creazione di un servizio. Un servizio è il modo in cui i componenti si trovano e comunicano tra loro in Kubernetes.
* **`name`**: Questo nome (`azure-vote-back`) è cruciale. Diventerà il nome DNS del servizio all'interno del cluster.
* **`selector`**: Collega il Service al Deployment corretto, utilizzando la stessa etichetta (`app: azure-vote-back`). Il traffico inviato a questo servizio verrà reindirizzato ai pod con quella stessa etichetta.
* **`port`**: Il servizio esporrà la porta `6379` per gli altri servizi nel cluster.


* ### 3. Deployment del Frontend

Questo blocco gestisce l'applicazione web di voto.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: azure-vote-front
spec:
  replicas: 1
  selector:
    matchLabels:
      app: azure-vote-front
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  template:
    metadata:
      labels:
        app: azure-vote-front
    spec:
      containers:
      - name: azure-vote-front
        image: [mcr.microsoft.com/azuredocs/azure-vote-front:v1](https://mcr.microsoft.com/azuredocs/azure-vote-front:v1)
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 250m
          limits:
            cpu: 500m
        env:
        - name: REDIS
          value: "azure-vote-back"```

* **`replicas: 1`**: Inizia con una sola istanza del frontend.

* **`strategy`**: `rollingUpdate` è una best practice per gli aggiornamenti "zero-downtime". Assicura che, durante un aggiornamento, una nuova istanza venga creata prima di terminare la vecchia, evitando interruzioni del servizio.

* **`resources`**: Definisce i limiti di CPU richiesti (`requests`) e massimi (`limits`) per il container. Questo è fondamentale in un ambiente di produzione per ottimizzare le risorse e prevenire che un container consumi troppa CPU.

* **`env`**: La variabile d'ambiente `REDIS` punta al nome del Service del backend (`azure-vote-back`). Kubernetes si occupa della risoluzione DNS, reindirizzando il traffico alla giusta istanza di Redis, proprio come avviene nella rete interna di `docker-compose`.

### 4. Service del Frontend

Questo Service espone l'applicazione web all'esterno del cluster, rendendola accessibile a tutti.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: azure-vote-front
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: azure-vote-front```


* **`kind: Service`**: Crea un servizio per il frontend.

* **`type: LoadBalancer`**: Questa è l'istruzione più importante per l'accesso esterno. In un ambiente AKS, questo tipo di servizio chiede ad Azure di creare automaticamente un **Azure Load Balancer** che esporrà un IP pubblico per la tua applicazione.

* **`port: 80`**: Espone l'applicazione sulla porta standard del web.

* **`selector`**: Collega il Service al Deployment del frontend (`app: azure-vote-front`), reindirizzando il traffico ai pod corretti.
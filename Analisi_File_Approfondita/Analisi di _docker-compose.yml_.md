
---

### Analisi###

Il file `docker-compose.yml` definisce l'orchestrazione locale e fornisce insight cruciali per il deployment in cloud.

#### Servizio `azure-vote-back` (Redis)

* **`image`**: Immagine Redis (`6.0.8`) da Microsoft Container Registry (MCR).
* **`container_name`**: Nome usato per la comunicazione interna, che su AKS verrà sostituito dal nome del servizio Kubernetes.
* **`environment`**: `ALLOW_EMPTY_PASSWORD: "yes"` è un'impostazione per lo sviluppo **non adatta alla produzione**.
* **`ports`**: Mappa la porta `6379` del container a quella dell'host.

#### Servizio `azure-vote-front` (Frontend)

```yaml
azure-vote-front:
  build: ./azure-vote
  image: [mcr.microsoft.com/azuredocs/azure-vote-front:v1](https://mcr.microsoft.com/azuredocs/azure-vote-front:v1)
  container_name: azure-vote-front
  environment:
    REDIS: azure-vote-back
  ports:
    - "8080:80"```

* **`build`**: Istruisce a costruire l'immagine dal Dockerfile locale.
* **`image`**: Immagine pre-esistente nel registro di Microsoft.
* **`container_name`**: Nome usato per la comunicazione interna.
* **`environment`**: La variabile `REDIS: azure-vote-back` è cruciale, poiché il frontend utilizza questo nome per connettersi al backend.
* **`ports`**: Mappa la porta 80 del container alla porta 8080 dell'host.

---

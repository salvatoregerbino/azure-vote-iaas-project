### Analisi del Dockerfile

Il `Dockerfile` è una ricetta testuale che definisce tutti gli step per creare un'immagine Docker. Per l'applicazione frontend, questo file si occupa di impostare l'ambiente Python e copiare il codice sorgente.

```dockerfile
FROM tiangolo/uwsgi-nginx-flask:python3.6
RUN pip install redis
ADD /azure-vote /app 
```


### Spiegazione Dettagliata

* **`FROM tiangolo/uwsgi-nginx-flask:python3.6`**
  Questo comando definisce l'immagine di base da cui partire. Invece di iniziare da zero con un'immagine vuota (come `ubuntu`), usiamo un'immagine pre-configurata e ottimizzata che include tutto il necessario per far funzionare un'applicazione Flask in produzione: un server web **Nginx**, un server applicativo **uWSGI** e l'interprete **Python 3.6**. Questo approccio riduce il tempo di build e sfrutta le best practice consolidate.

* **`RUN pip install redis`**
  Il comando `RUN` esegue istruzioni direttamente all'interno del container durante il processo di build. Qui viene utilizzato `pip`, il gestore di pacchetti di Python, per installare la libreria `redis`. L'applicazione frontend ha bisogno di questa libreria per poter comunicare con il backend (il servizio Redis) e inviare i dati dei voti.

* **`ADD /azure-vote /app`**
  Questo comando copia i file e le directory dal tuo computer (il file system locale) all'interno dell'immagine del container. Specifica di copiare il contenuto della cartella `azure-vote` (che contiene il codice sorgente dell'applicazione web) e di posizionarlo nella directory `/app` all'interno del container. È in questa posizione che il server `uWSGI` cercherà il codice da eseguire.

---

### Riepilogo 

* **`FROM`**: Definisce l'immagine di base, scegliendo una già pronta e ottimizzata per le applicazioni web Python.
* **`RUN`**: Esegue comandi durante la creazione dell'immagine, in questo caso installa la dipendenza `redis`.
* **`ADD`**: Copia il codice sorgente locale (`/azure-vote`) all'interno dell'immagine del container, nella directory (`/app`) da cui l'applicazione verrà eseguita.

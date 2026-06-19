# Prolog

# Base de Dados com base nos Censos de 2001 

Este projeto implementa uma interface de linguagem natural em Prolog para consultar dados estatísticos do Censos 2001 de Portugal, utilizando um motor de base de dados SQLite em memória para garantir tempos de resposta imediatos.

---

##  Configuração da Base de Dados

Devido ao limite de tamanho de ficheiros do GitHub, a base de dados do projeto (`portugal2001.gpkg`) não está incluída neste repositório e deve ser descarregada manualmente.

### Instruções para Download:

1. Acede ao portal oficial de downloads do INE:  [INE - Download Censos 2001](https://mapas.ine.pt/download/index2001.phtml)
2. Após abrir a página, procura e clica na pasta **"Portugal"** para iniciar o download do pacote.
3. Extrai o ficheiro descarregado e localiza o ficheiro base de dados com o nome:  
   `portugal2001.gpkg`
4. Coloca o ficheiro **`portugal2001.gpkg` na pasta raiz deste projeto** (junto aos ficheiros `.pl` como o `app.pl`, `db.pl`, etc.).

---

### Executar
Para iniciar a interface de linguagem natural no terminal, corre o seguinte comando na pasta do projeto:
```bash
swipl -s app.pl -g "start."

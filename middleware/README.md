[Cliente Externo]  
  ↓ HTTPS  
[Middleware] *(FastAPI + Autenticação básica + DuckDB(mas vai conectar ao pubsub))*  
  ↓ gRPC (`localhost:8001`)
[Triton (em container Docker)]  
  ↓  
(Resposta)



[[]]
A/B Imagem do sistema (preferencia âtomico)

porta - 443 exposta para https e websocket
[[]]

[[]]
-> server com openAI like - Kobold.cpp  ((docker do llm studio//))
-> importante encontrar docker com drivers Nvidia já pronto parau uso

[[]]

## 1. Permissões para Gerenciamento da VM

- ✅ **Permissão para criar e gerenciar VMs**:
  - Criar/editar/ligar/desligar VMs.
  - Escolher tamanho da VM (preferência: GPU-enabled, caso vá usar modelo maior ou Triton com CUDA).
  - Escolher imagem base (Ubuntu Server recomendado).
  
- ✅ **Permissão para configurar regras de rede (NSG)**:
  - Liberação da **porta 443 (HTTPS/WebSocket)**.
  - Liberação de **porta interna 8001** (gRPC do Triton – se comunicação entre containers ou serviços internos).
  - Possível liberação de porta **22 (SSH)** para acesso remoto com chave pública, caso necessário.

- ✅ **Permissão para criar e rodar containers Docker**:
  - Instalar Docker na VM (caso a imagem não venha com).
  - Rodar containers com mapeamento de portas.
  - Usar volume persistente ou bind mounts, se necessário.

## 2. Armazenamento e Persistência

- ✅ **Permissão para usar discos persistentes ou Azure Files**:
  - Para armazenar logs, modelos, ou dados locais da API.
  - Exemplo: montar `/models` ou `/data` como volume persistente.

## 3. Segurança / Acesso

- ✅ **Permissão para configurar certificado TLS**:
  - Usar certificado válido (pode ser interno, corporativo ou Let's Encrypt).
  - Garantir HTTPS real, não apenas self-signed.

- ✅ **Acesso ao Azure Monitor / Logs (opcional)**:
  - Se quiser visualizar uso, erros ou criar alertas automáticos.

## 4. Observabilidade (opcional, mas recomendada)

- ✅ **Liberação para configurar Application Insights / Log Analytics**, caso precise:
  - Monitorar erros na API.
  - Métricas de uso da VM ou carga dos containers.

---

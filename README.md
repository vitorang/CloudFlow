# CloudFlow

Sistema de mensagens em tempo real baseado em arquitetura serverless na AWS (.NET + Flutter).

---

## ⚙️ Configurações da AWS

### 1. IAM
Crie um usuário programático com credenciais de acesso (`AccessKey` e `SecretKey`) e as seguintes permissões:
- `AmazonDynamoDBFullAccess`
- `AmazonAPIGatewayInvokeFullAccess`

---

### 2. DynamoDB
Crie as tabelas no modo **On-Demand**:

- **`CloudFlow_Messages`**
  - Partition key: `Id` (`String`)
  - Streams: `New and old images` *(necessário caso utilize DynamoDB Streams no worker)*

- **`CloudFlow_WebSocketConnections`**
  - Partition key: `ConnectionId` (`String`)

---

### 3. Variáveis de Ambiente
Copie `CloudFlow/.env.example` para `CloudFlow/.env` e preencha as variáveis com a região, credenciais do IAM e endpoints correspondentes.
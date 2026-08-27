# CloudFlow

Sistema de mensagens em tempo real baseado em arquitetura serverless na AWS (.NET + Flutter).

---

## ⚙️ Configurações da AWS

### 1. IAM

#### Usuário Programático (Aplicação / API Local)
Crie um usuário com credenciais (`AccessKey` e `SecretKey`) e as permissões:
- `AmazonDynamoDBFullAccess`
- `AmazonAPIGatewayInvokeFullAccess`
- `AWSLambda_FullAccess`

#### Roles de Execução (Lambdas)
Crie Roles do tipo **AWS Service ➔ Lambda** para cada função:

1. **`CloudFlow_WebSocket`** *(usada por `CloudFlow_WebSocketConnect` e `CloudFlow_WebSocketDisconnect`)*
   - `AWSLambdaBasicExecutionRole`
   - `AmazonDynamoDBFullAccess`

2. **`CloudFlow_DynamoDb`** *(usada por `CloudFlow_DynamoDbMessageStream`)*
   - `AWSLambdaBasicExecutionRole`
   - `AmazonDynamoDBFullAccess`
   - `AmazonAPIGatewayInvokeFullAccess`

---

### 2. DynamoDB
Crie as tabelas no modo **On-Demand**:

- **`CloudFlow_Messages`**
  - Partition key: `Id` (`String`)
  - DynamoDB Streams: **Imagens novas e antigas / New and old images**

- **`CloudFlow_WebSocketConnections`**
  - Partition key: `ConnectionId` (`String`)

---

### 3. API Gateway (WebSocket)
Crie uma API WebSocket:
- **Route selection expression**: `$request.body.action`
- **Rotas**:
  - `$connect` ➔ Integrar com Lambda `WebSocketConnectHandler` (**Obrigatório**: ativar **Integração de proxy do Lambda / Lambda proxy integration**)
  - `$disconnect` ➔ Integrar com Lambda `WebSocketDisconnectHandler` (**Obrigatório**: ativar **Integração de proxy do Lambda / Lambda proxy integration**)
  - `$default` ➔ Mock
- **Stage**: `dev` (sempre clicar em **Implantar API / Deploy API** após alterações)

---

### 4. Deploy das Lambdas (Workers)
Instale a ferramenta global da AWS Lambda (caso ainda não tenha):
```bash
dotnet tool install -g Amazon.Lambda.Tools
```

Execute o script de deploy na pasta `CloudFlow` para compilar e enviar as funções:
```powershell
./deploy-lambda.ps1 CloudFlow_WebSocketConnect
./deploy-lambda.ps1 CloudFlow_WebSocketDisconnect
./deploy-lambda.ps1 CloudFlow_DynamoDbMessageStream
```

Handlers correspondentes:
- **$connect**: `CloudFlow.Workers.Aws::CloudFlow.Workers.Aws.WebSocketApi.WebSocketConnectHandler::Handle`
- **$disconnect**: `CloudFlow.Workers.Aws::CloudFlow.Workers.Aws.WebSocketApi.WebSocketDisconnectHandler::Handle`
- **DynamoDB Streams**: `CloudFlow.Workers.Aws::CloudFlow.Workers.Aws.DynamoDbStreams.MessageStreamHandler::Handle`

#### Configuração Adicional da Lambda `CloudFlow_DynamoDbMessageStream`:
1. **Trigger (Gatilho)**:
   - Adicionar gatilho do tipo **DynamoDB** apontando para a tabela `CloudFlow_Messages`.
   - Starting position: `Latest`.
2. **Variável de Ambiente**:
   - `AWS_WEBSOCKET_SERVICE_URL`: URL de gerenciamento HTTP do API Gateway (`https://{api-id}.execute-api.{region}.amazonaws.com/{stage}`).

---

### 5. Variáveis de Ambiente
Copie `CloudFlow/.env.example` para `CloudFlow/.env` e preencha as variáveis com a região, credenciais do IAM e endpoints correspondentes:
- `AWS_WEBSOCKET_SERVICE_URL`: URL de gerenciamento (`https://{api-id}.execute-api.{region}.amazonaws.com/{stage}`)
- `AWS_WEBSOCKET_PUBLIC_URL`: URL de conexão (`wss://{api-id}.execute-api.{region}.amazonaws.com/{stage}`)
# CloudFlow

CloudFlow é um projeto de estudo de um sistema de mensagens e compartilhamento rápido em tempo real, inspirado no conceito do Opera Flow.

Construído com .NET no backend e Flutter no frontend, o projeto adota uma Arquitetura Orientada a Eventos (EDA) e serverless na AWS, utilizando DynamoDB Streams e API Gateway WebSocket para sincronização instantânea entre múltiplos dispositivos e clientes.


## Tecnologias Utilizadas

- Backend: .NET 10, AWS SDK
- Frontend: Flutter (gerenciamento de estado com Cubit / flutter_bloc)
- Cloud & Serverless (AWS):
  - AWS Lambda
  - Amazon DynamoDB & DynamoDB Streams
  - Amazon API Gateway (WebSocket)
  - AWS IAM


## Como Executar

### 1. Pré-requisitos
- .NET 10 SDK
- Flutter SDK
- Conta na AWS (todos os recursos utilizados são elegíveis ao Free Tier)

### 2. Configurar Variáveis de Ambiente
Renomeie o arquivo `.env.example` para `.env` dentro da pasta `CloudFlow` e preencha com suas credenciais e endpoints:

Edite o arquivo `CloudFlow/.env` informando sua região, credenciais do IAM e URLs do WebSocket da AWS:
- `AWS_WEBSOCKET_SERVICE_URL`: URL de gerenciamento (`https://{api-id}.execute-api.{region}.amazonaws.com/{stage}`)
- `AWS_WEBSOCKET_PUBLIC_URL`: URL de conexão (`wss://{api-id}.execute-api.{region}.amazonaws.com/{stage}`)

### 3. Executar o Backend (API)
```bash
cd CloudFlow
dotnet run --project CloudFlow.Api
```

### 4. Executar o Frontend (App Flutter)
```bash
cd cloud_flow_app
flutter run
```


## Configurações da AWS

### 1. IAM

#### Usuário IAM (API Local / Backend)
Crie um usuário com credenciais (`AccessKey` e `SecretKey`) e as permissões:
- `AmazonDynamoDBFullAccess`
- `AmazonAPIGatewayInvokeFullAccess`
- `AWSLambda_FullAccess`

#### Roles de Execução (Lambdas)
Crie Roles do tipo AWS Service ➔ Lambda com as permissões:

1. `CloudFlow_WebSocket`
   - `AWSLambdaBasicExecutionRole`
   - `AmazonDynamoDBFullAccess`

2. `CloudFlow_DynamoDb`
   - `AWSLambdaBasicExecutionRole`
   - `AmazonDynamoDBFullAccess`
   - `AmazonAPIGatewayInvokeFullAccess`


### 2. DynamoDB
Crie as tabelas no modo On-Demand:

- `CloudFlow_Messages`
  - Partition key: `Id` (String)
  - DynamoDB Streams: Imagens novas e antigas / New and old images

- `CloudFlow_WebSocketConnections`
  - Partition key: `ConnectionId` (String)


### 3. API Gateway (WebSocket)
Crie uma API WebSocket:
- Route selection expression: `$request.body.action`
- Rotas:
  - `$connect` ➔ Integrar com Lambda `WebSocketConnectHandler`
  - `$disconnect` ➔ Integrar com Lambda `WebSocketDisconnectHandler`
  - `$default` ➔ Mock
  - Nota: ative Integração de proxy do Lambda / Lambda proxy para as rotas Lambda
- Stage: `dev` (sempre clicar em Implantar API / Deploy API após alterações)


### 4. Implantação das Lambdas
Instale a ferramenta global da AWS Lambda (caso ainda não tenha):
```bash
dotnet tool install -g Amazon.Lambda.Tools
```

Execute o script de implantação na pasta `CloudFlow` para compilar e enviar as funções:
```powershell
./deploy-lambda.ps1 CloudFlow_WebSocketConnect
./deploy-lambda.ps1 CloudFlow_WebSocketDisconnect
./deploy-lambda.ps1 CloudFlow_DynamoDbMessageStream
```

Handlers correspondentes:
- `$connect`: `CloudFlow.Workers.Aws::CloudFlow.Workers.Aws.WebSocketApi.WebSocketConnectHandler::Handle`
- `$disconnect`: `CloudFlow.Workers.Aws::CloudFlow.Workers.Aws.WebSocketApi.WebSocketDisconnectHandler::Handle`
- DynamoDB Streams: `CloudFlow.Workers.Aws::CloudFlow.Workers.Aws.DynamoDbStreams.MessageStreamHandler::Handle`

#### Configuração Adicional da Lambda `CloudFlow_DynamoDbMessageStream`:
1. Trigger (Gatilho):
   - Adicionar gatilho do tipo DynamoDB apontando para a tabela `CloudFlow_Messages`.
   - Starting position: `Latest`.
2. Variável de Ambiente:
   - `AWS_WEBSOCKET_SERVICE_URL`: URL de gerenciamento HTTP do API Gateway (`https://{api-id}.execute-api.{region}.amazonaws.com/{stage}`).


### 5. Variáveis de Ambiente
Copie `CloudFlow/.env.example` para `CloudFlow/.env` e preencha as variáveis com a região, credenciais do IAM e endpoints correspondentes:
- `AWS_WEBSOCKET_SERVICE_URL`: URL de gerenciamento (`https://{api-id}.execute-api.{region}.amazonaws.com/{stage}`)
- `AWS_WEBSOCKET_PUBLIC_URL`: URL de conexão (`wss://{api-id}.execute-api.{region}.amazonaws.com/{stage}`)


## Próximos Passos

### AWS
- **Monitoramento de Mensagens:** Monitoramento em tempo real do ciclo de vida das mensagens (notificação visual no app dos eventos disparados pelas Lambdas)
- **Armazenamento de Arquivos:** Envio e compartilhamento de arquivos e imagens (AWS S3 com Presigned URLs)
- **Processamento Assíncrono:** Exclusão assíncrona de arquivos anexados via fila (AWS SQS)
- **Mensageria e Notificações:** Publicação e distribuição de eventos de mensagens via mensageria (AWS SNS)
- **Pré-visualização de Conteúdo:** Pré-visualização rica de links compartilhados (Rich Link Previews / OpenGraph)
- **Limpeza Automática:** Expiração e exclusão automática de mensagens antigas (DynamoDB TTL)

### Azure (Planejamento de Equivalência Arquitetural)
- **Comunicação em Tempo Real:** Substituição do API Gateway WebSocket pelo **Azure Web PubSub** gerenciando conexões de clientes
- **Persistência de Dados:** Migração de dados de mensagens e conexões ativas para **Azure Cosmos DB** (API NoSQL)
- **Captura de Eventos de Dados:** Uso do **Cosmos DB Change Feed** (equivalente ao DynamoDB Streams) para reagir à inserção e alteração de mensagens
- **Processamento Serverless:** Implementação de **Azure Functions** com gatilho em Change Feed (equivalente aos handlers de Lambda) para broadcast de mensagens
- **Armazenamento de Arquivos:** Upload com URLs temporárias seguras via **Azure Blob Storage** com SAS Tokens (equivalente a S3 Presigned URLs)
- **Mensageria e Filas:** Integração de **Azure Queue Storage / Service Bus** e **Event Grid** para exclusão assíncrona e publicação de eventos
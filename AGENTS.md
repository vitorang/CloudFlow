# Regras de Desenvolvimento

- **Sem sufixo `Async`**: Nunca usar o sufixo `Async` no nome de métodos (ex: usar `Create`, `GetRecent`, `GetById`).
- **Sem comentários**: Não adicionar comentários no código (sem `//`, `/* */` ou comentários explicativos redundantes). O código deve ser autoexplicativo.
- **CancellationToken**: Todo método assíncrono deve receber `CancellationToken cancellationToken`.
- **IDs**: Usar ULID em formato `string` para identificadores únicos.
- **Configurações sem fallback**: Não usar valores fallback/default para ler configurações. Se faltar configuração, lançar exceção / fail-fast.
- **Fail-fast**: Optar por fail-fast em vez de usar blocos try-catch desnecessários.

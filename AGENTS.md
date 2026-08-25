# Regras de Desenvolvimento

- **Sem sufixo `Async`**: Nunca usar o sufixo `Async` no nome de métodos (ex: usar `Create`, `GetRecent`, `GetById`).
- **Sem comentários**: Não adicionar comentários no código (sem `//`, `/* */` ou comentários explicativos redundantes). O código deve ser autoexplicativo.
- **CancellationToken**: Todo método assíncrono deve receber `CancellationToken cancellationToken`.
- **IDs**: Usar ULID em formato `string` para identificadores únicos.
- **Configurações sem fallback**: Não usar valores fallback/default para ler configurações. Se faltar configuração, lançar exceção / fail-fast.
- **Fail-fast**: Optar por fail-fast em vez de usar blocos try-catch desnecessários.
- **Primary Constructors**: Usar Primary Constructors do C# moderno para injeção de dependências em classes (evitar campos privados com `_` e construtores tradicionais com atribuição manual).
- **Sem abreviações**: Evitar abreviar nomes de variáveis e parâmetros (usar nomes claros e descritivos por extenso), exceto em iteradores e expressões lambda de coleções (como `for`, `foreach`, `.Select(x => ...)`, etc., onde abreviações curtas são permitidas).
- **Formatação de `if` de uma linha**: No C#, usar `if` de uma linha sem chaves, colocando o corpo da instrução na linha de baixo com indentação.

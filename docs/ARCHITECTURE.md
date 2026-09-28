# Arquitetura

## Escopo e isolamento

O projeto usa o application ID `br.com.delivy.lab_facial_delivy`, não possui endpoint, permissão de internet, analytics ou dependência do DELIVERY principal. Todo o estado fica no diretório privado do aplicativo.

## Fluxo de dados

1. O Android abre o aplicativo de câmera do aparelho por `ACTION_IMAGE_CAPTURE`.
2. A imagem devolvida permanece em memória, é recortada no centro e reduzida.
3. O código nativo calcula brilho, contraste, nitidez e uma grade normalizada de 256 valores.
4. A miniatura JPEG retorna ao Flutter apenas para visualização imediata e não entra no estado persistido.
5. No cadastro, apenas a grade da referência e os dados mínimos são cifrados.
6. Na verificação, a grade neutra é comparada à referência; a diferença entre a captura neutra e o desafio alimenta a prova de vida experimental.
7. O histórico recebe apenas estado, métricas, motivo, desafio, ID e horário.

## Decisão

- semelhança: correlação normalizada entre referência e selfie;
- mudança ativa: diferença absoluta média entre selfie neutra e desafio; essa métrica não representa uma probabilidade ou confiança de prova de vida;
- qualidade: composição de exposição, contraste e nitidez;
- aprovado: qualidade e vida adequadas, semelhança a partir de 0,82;
- revisão manual: qualidade/vida inconclusiva ou semelhança entre 0,68 e 0,82;
- não aprovado: semelhança abaixo de 0,68, sempre sem consequência automática.

Os limiares são visíveis na tela Admin e existem para teste funcional. A mudança ativa é aceita somente entre 0,025 e 0,42: valores abaixo indicam pouca alteração e valores acima sugerem capturas incoerentes. Esses limites não foram calibrados para uso real.

## Armazenamento

O arquivo `lab_state.enc` usa AES/GCM com IV aleatório por gravação. A chave AES é criada e mantida pelo Android Keystore sob o alias `lab_facial_delivy_state_v1`. A gravação usa arquivo temporário e renomeação para reduzir risco de corrupção. A exclusão remove o arquivo cifrado; a desinstalação remove o armazenamento privado e a chave.

## Decisões de implementação

O protótipo não usa pacotes de câmera ou banco de dados. A ponte nativa reduz dependências, mantém o processamento no aparelho e deixa explícitas as fronteiras entre interface, heurística e segurança. Para produção, a ponte deve ser substituída por componentes biométricos auditados e um desenho de segurança completo.

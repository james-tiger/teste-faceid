# Privacidade e LGPD — nota de laboratório

Este documento é orientação de engenharia para o protótipo, não parecer jurídico.

## Finalidade e necessidade

A finalidade limitada é testar voluntariamente um fluxo local de verificação 1:1. O LAB não faz identificação em massa, busca 1:N, rastreamento, vigilância ou integração operacional. Nome, ID interno e quatro dígitos do documento existem somente para tornar o roteiro compreensível.

## Dados e minimização

Dados persistidos: cadastro mínimo, vetor numérico reduzido da referência, versão do consentimento e histórico de métricas. Selfies e miniaturas não são persistidas. Não há transmissão, nuvem, publicidade ou analytics.

Dados biométricos podem ser dados pessoais sensíveis. Antes de qualquer uso real, a organização deve documentar controlador e operadores, hipótese legal apropriada, finalidade, necessidade, segurança, retenção, compartilhamentos, direitos do titular e medidas do RIPD. Consentimento no LAB não deve ser reutilizado como justificativa automática para produção.

## Retenção e direitos

O estado permanece somente no aparelho até a ação **Apagar todos os dados locais** ou a desinstalação. Um uso controlado deve oferecer informação clara, confirmação de exclusão, acesso, correção, revogação quando aplicável, oposição e canal do encarregado.

## Decisões automatizadas

As saídas do LAB são sinais técnicos experimentais. É proibido tomar decisão de trabalho exclusivamente automatizada. Deve haver revisão humana com autoridade para alterar o resultado, consideração do contexto, alternativa não biométrica e procedimento de contestação sem retaliação.

## Riscos residuais

- falsa aceitação ou rejeição por pose, iluminação, câmera e aparência;
- desempenho desigual entre grupos e pessoas com deficiência;
- fraude por foto, vídeo, máscara ou câmera virtual;
- coerção ou ausência de alternativa genuína;
- reidentificação ou uso incompatível do vetor;
- comprometimento do aparelho já desbloqueado.

## Controles exigidos antes de produção

- avaliação de impacto e revisão jurídica/DPO;
- modelo 1:1 e PAD avaliados por laboratório independente;
- métricas por grupos relevantes, limites e monitoramento de deriva;
- criptografia, controle de acesso, rotação de chaves e resposta a incidentes;
- retenção curta, exclusão verificável e registros de auditoria;
- transparência, acessibilidade, alternativa e revisão humana efetiva;
- testes de segurança contra replay, injeção, adulteração e dispositivo comprometido.

# Diretiva de Senhas e Credenciais

1. **Solicitação Explícita Obrigatória**:
   - Caso seja necessário digitar ou usar uma senha para qualquer ação ou comando (como `sudo`, chaves protegidas ou elevação de privilégios) e ela não esteja disponível na memória de execução da sessão ativa, o OMP DEVE solicitar a senha diretamente ao usuário.
   - NUNCA assuma, tente adivinhar ou use mecanismos para contornar a solicitação de senha.

2. **Uso Exclusivo na Sessão Ativa**:
   - A senha fornecida pelo usuário só pode ser utilizada temporariamente em memória para a execução da ação/comando durante a sessão ativa corrente.

3. **Proibição Absoluta de Armazenamento**:
   - É terminantemente PROIBIDO gravar, salvar, persistir ou registrar a senha em qualquer arquivo de configuração, scripts, dotfiles, histórico, disco ou arquivos de memória do agente (`memory://`, `MEMORY.md`, `raw_memories.md`, `rollout_summaries/` ou equivalentes).

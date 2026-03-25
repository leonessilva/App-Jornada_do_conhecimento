# 🌱 Jornada do Conhecimento

> Aplicativo mobile de intervenção educativa sobre o uso seguro de agrotóxicos para agricultores ribeirinhos do Nordeste brasileiro.

---

## Sobre o Projeto

O **Jornada do Conhecimento** é uma plataforma desenvolvida para apoiar pesquisas de campo com agricultores ribeirinhos. O app guia o participante por uma jornada educativa completa: questionário inicial → vídeos educativos → questionário final → resultados comparativos.

Desenvolvido com foco em **acessibilidade para baixa escolaridade** e **funcionamento offline** em áreas rurais com conectividade limitada.

---

## Fluxo do Participante

```
Splash → Login → TCLE (Consentimento) → Cadastro
  → Perguntas iniciais → Vídeos educativos
  → Perguntas finais → Resultados + UBS próxima
```

---

## Funcionalidades

### Para o Agricultor
- Login simplificado com dois botões grandes (sem formulário)
- Questionário com linguagem acessível e ícones visuais
- Resultados com cards antes/depois + emoji por faixa de acerto
- Busca da UBS mais próxima por GPS ou CEP
- Funciona 100% offline no campo

### Para o Pesquisador
- Painel admin com login por senha mestre ou CPF + senha
- Solicitação de acesso com aprovação pelo administrador
- Gráficos dumbbell (pontos conectados) para comparação pré × pós
- Filtros por gênero, faixa etária, sexo e município
- Exportação de dados em CSV (resumo e respostas detalhadas)
- Sincronização da nuvem para consolidar dados de múltiplos dispositivos

### Técnicas
- Modo escuro automático (segue o sistema)
- Sincronização offline-first: salva local → sobe ao WiFi
- 76 UBS reais do Nordeste em base offline
- CPF armazenado apenas como hash SHA-256

---

## Tecnologias

| Camada | Tecnologia |
|---|---|
| Framework | Flutter 3.x (Dart) |
| Estado | Provider |
| Banco local | SQLite (sqflite) |
| Nuvem | Firebase Firestore |
| GPS | Geolocator |
| CEP online | ViaCEP API |
| Segurança | SHA-256 (crypto) |

---

## Estrutura do Projeto

```
lib/
├── core/
│   ├── config/         # Configurações (senha admin hash)
│   ├── theme/          # Tema claro e escuro
│   ├── firebase_options.dart
│   ├── sync_service.dart    # Auto-sync offline → Firestore
│   └── utils/
├── data/
│   ├── database/       # SQLite helper
│   ├── models/         # Participant, Question, UBS, etc.
│   ├── repositories/   # CRUD + lógica de negócio
│   └── questions_data.dart  # 20 questões do questionário
├── features/
│   ├── splash/
│   ├── login/
│   ├── consent/
│   ├── registration/
│   ├── questionnaire/
│   ├── videos/
│   ├── results/
│   └── admin/
├── providers/
│   └── app_provider.dart    # Estado global do participante
└── main.dart
assets/
├── images/             # Foto splash (colmeia)
└── data/
    └── ubs_nordeste.json    # 76 UBS reais do Nordeste
```

---

## Como Rodar

### Pré-requisitos
- Flutter SDK ≥ 3.0
- Dart SDK ≥ 3.0
- Chrome (para rodar na web)

### Passos

```bash
# 1. Clonar o repositório
git clone https://github.com/leonessilva/App-Jornada_do_conhecimento.git
cd App-Jornada_do_conhecimento

# 2. Instalar dependências
flutter pub get

# 3. Rodar no Chrome
flutter run -d chrome

# 4. Rodar no Android
flutter run -d android
```

---

## Firebase

O projeto usa **Firebase Firestore** (região: southamerica-east1 — São Paulo) para sincronização de dados entre dispositivos de campo.

As credenciais web estão em `lib/core/firebase_options.dart`. Para configurar um novo projeto Firebase, substitua os valores nesse arquivo.

**Regras de segurança:** escrita pública permitida (app de campo), leitura bloqueada — somente o painel admin acessa via SDK autenticado.

---

## Segurança e LGPD

- **CPF** nunca armazenado em texto puro — apenas hash SHA-256
- **Dados sensíveis** (gestação, gênero) coletados com TCLE assinado digitalmente
- **Senha admin** armazenada como hash — nunca em texto puro no código
- **Firestore** com regras que bloqueiam leitura pública

---

## Acesso Admin

Acesse a área restrita pelo botão oculto na tela de login (toque 5x no logo) ou navegue para `/admin_login`.

- **Senha mestre:** definida em `lib/core/config/app_config.dart` (hash SHA-256)
- **Pesquisador:** solicite acesso pelo formulário dentro da tela admin

---

## Estados (UF) Cobertos — UBS

AL · BA · CE · MA · PB · PE · PI · RN · SE

76 unidades de saúde cadastradas com coordenadas GPS para busca por proximidade offline.

---

## Pendente

- [ ] Tela de vídeos — player com controles (aguardando gravação)

---

## Autor

**Leones Silva**
Projeto de pesquisa — Intervenção educativa com agricultores ribeirinhos

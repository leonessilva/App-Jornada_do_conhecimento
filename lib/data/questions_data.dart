// ============================================================
// PERGUNTAS REAIS — BLOCOs II-V
// Fonte: Protótipo validado do aplicativo Jornada do Conhecimento
// Tema: Percepção de risco sobre agrotóxicos / agricultores ribeirinhos
// Total: 20 perguntas | score:null = descritiva | respostaCorreta = índice 0
// ============================================================

import 'models/question.dart';

const List<Question> kQuestions = [
  // ─── BLOCO II: Práticas de Trabalho ─────────────────────────
  Question(
    id: 'Q01',
    bloco: 'Suas práticas no campo',
    ordem: 1,
    tipo: QuestionType.unica,
    texto: 'Com que frequência você aplica agrotóxicos na sua lavoura?',
    opcoes: [
      'Diariamente',
      'Algumas vezes por semana',
      'Algumas vezes por mês',
      'Raramente',
      'Nunca uso agrotóxicos',
    ],
    // descritiva — sem resposta correta
  ),
  Question(
    id: 'Q02',
    bloco: 'Suas práticas no campo',
    ordem: 2,
    tipo: QuestionType.unica,
    texto: 'Você lê o rótulo do agrotóxico antes de usar?',
    opcoes: [
      'Sempre leio com atenção',
      'Às vezes leio',
      'Raramente leio',
      'Nunca leio',
    ],
    respostaCorreta: 'Sempre leio com atenção',
  ),
  Question(
    id: 'Q03',
    bloco: 'Suas práticas no campo',
    ordem: 3,
    tipo: QuestionType.unica,
    texto: 'Você usa Equipamento de Proteção Individual (EPI) ao aplicar agrotóxicos?',
    opcoes: [
      'Sempre uso o equipamento completo',
      'Uso alguns itens de proteção',
      'Raramente uso',
      'Nunca uso EPI',
    ],
    respostaCorreta: 'Sempre uso o equipamento completo',
  ),
  Question(
    id: 'Q04',
    bloco: 'Suas práticas no campo',
    ordem: 4,
    tipo: QuestionType.unica,
    texto: 'Como você descarta as embalagens vazias de agrotóxico?',
    opcoes: [
      'Devolvo ao ponto de coleta autorizado',
      'Enterro no campo',
      'Queimo as embalagens',
      'Jogo no lixo comum',
      'Deixo na natureza ou no rio',
    ],
    respostaCorreta: 'Devolvo ao ponto de coleta autorizado',
  ),
  Question(
    id: 'Q05',
    bloco: 'Suas práticas no campo',
    ordem: 5,
    tipo: QuestionType.unica,
    texto: 'Você lava a embalagem vazia 3 vezes com água antes de descartar? (chamada tríplice lavagem)',
    opcoes: [
      'Sim, sempre faço',
      'Às vezes faço',
      'Nunca faço',
      'Não sabia que devia fazer isso',
    ],
    respostaCorreta: 'Sim, sempre faço',
  ),
  Question(
    id: 'Q06',
    bloco: 'Suas práticas no campo',
    ordem: 6,
    tipo: QuestionType.unica,
    texto: 'Você mistura diferentes agrotóxicos sem orientação de um técnico?',
    opcoes: [
      'Nunca faço isso',
      'Às vezes misturo',
      'Com frequência misturo',
    ],
    respostaCorreta: 'Nunca faço isso',
  ),
  Question(
    id: 'Q07',
    bloco: 'Suas práticas no campo',
    ordem: 7,
    tipo: QuestionType.unica,
    texto: 'Você respeita o período de carência indicado no rótulo antes de colher?',
    opcoes: [
      'Sempre respeito',
      'Às vezes respeito',
      'Nunca respeito',
      'Não sei o que é período de carência',
    ],
    respostaCorreta: 'Sempre respeito',
  ),

  // ─── BLOCO III: Saúde e Agrotóxicos ─────────────────────────
  Question(
    id: 'Q08',
    bloco: 'Saúde e agrotóxicos',
    ordem: 8,
    tipo: QuestionType.unica,
    texto: 'Você já sentiu mal-estar (enjoo, tontura, dor de cabeça) após usar agrotóxicos?',
    opcoes: [
      'Sim, com frequência',
      'Sim, raramente',
      'Nunca senti',
    ],
    // descritiva — sem resposta correta
  ),
  Question(
    id: 'Q09',
    bloco: 'Saúde e agrotóxicos',
    ordem: 9,
    tipo: QuestionType.unica,
    texto: 'Ao sentir sintomas após usar agrotóxico, o que você costuma fazer?',
    opcoes: [
      'Procuro médico imediatamente',
      'Espero os sintomas passarem',
      'Tomo remédio caseiro por conta',
      'Continuo trabalhando normalmente',
    ],
    respostaCorreta: 'Procuro médico imediatamente',
  ),
  Question(
    id: 'Q10',
    bloco: 'Saúde e agrotóxicos',
    ordem: 10,
    tipo: QuestionType.unica,
    texto: 'Crianças ou mulheres grávidas ficam próximas durante a aplicação de agrotóxicos?',
    opcoes: [
      'Nunca — elas se afastam completamente',
      'Às vezes ficam por perto',
      'Sim, participam da atividade junto',
    ],
    respostaCorreta: 'Nunca — elas se afastam completamente',
  ),
  Question(
    id: 'Q11',
    bloco: 'Saúde e agrotóxicos',
    ordem: 11,
    tipo: QuestionType.unica,
    texto: 'Você conhece os sintomas de uma intoxicação aguda por agrotóxico?',
    opcoes: [
      'Sim, conheço muito bem',
      'Conheço alguns sintomas',
      'Não conheço os sintomas',
    ],
    respostaCorreta: 'Sim, conheço muito bem',
  ),
  Question(
    id: 'Q12',
    bloco: 'Saúde e agrotóxicos',
    ordem: 12,
    tipo: QuestionType.unica,
    texto: 'Você lava separadamente as roupas usadas na aplicação de agrotóxicos?',
    opcoes: [
      'Sempre lavo separado',
      'Às vezes separo',
      'Lavo junto com as outras roupas',
    ],
    respostaCorreta: 'Sempre lavo separado',
  ),
  Question(
    id: 'Q13',
    bloco: 'Saúde e agrotóxicos',
    ordem: 13,
    tipo: QuestionType.unica,
    texto: 'Você já procurou atendimento médico por suspeita de intoxicação por agrotóxico?',
    opcoes: [
      'Sim, já fui ao médico',
      'Não fui, mas já tive sintomas',
      'Não, nunca precisei',
    ],
    // descritiva — sem resposta correta
  ),

  // ─── BLOCO IV: Percepção Ecológica ───────────────────────────
  Question(
    id: 'Q14',
    bloco: 'Meio ambiente',
    ordem: 14,
    tipo: QuestionType.unica,
    texto: 'Os agrotóxicos podem contaminar as águas de rios e lagos próximos?',
    opcoes: [
      'Sim, com certeza podem contaminar',
      'Talvez contaminem',
      'Não contaminam as águas',
      'Não sei',
    ],
    respostaCorreta: 'Sim, com certeza podem contaminar',
  ),
  Question(
    id: 'Q15',
    bloco: 'Meio ambiente',
    ordem: 15,
    tipo: QuestionType.unica,
    texto: 'O uso de agrotóxicos prejudica animais silvestres, insetos e plantas nativas?',
    opcoes: [
      'Sim, com certeza prejudica',
      'Talvez prejudique',
      'Não prejudica',
      'Não sei',
    ],
    respostaCorreta: 'Sim, com certeza prejudica',
  ),
  Question(
    id: 'Q16',
    bloco: 'Meio ambiente',
    ordem: 16,
    tipo: QuestionType.unica,
    texto: 'Você já observou algum impacto ambiental causado por agrotóxico (peixes mortos, etc.)?',
    opcoes: [
      'Sim, já observei',
      'Não, nunca vi',
      'Não sei dizer',
    ],
    // descritiva — sem resposta correta
  ),
  Question(
    id: 'Q17',
    bloco: 'Meio ambiente',
    ordem: 17,
    tipo: QuestionType.unica,
    texto: 'Existem alternativas ao uso de agrotóxicos para controlar pragas na lavoura?',
    opcoes: [
      'Sim, existem várias alternativas',
      'Talvez existam algumas',
      'Não existem alternativas',
      'Não sei',
    ],
    respostaCorreta: 'Sim, existem várias alternativas',
  ),

  // ─── BLOCO V: Percepção de Risco ─────────────────────────────
  Question(
    id: 'Q18',
    bloco: 'Riscos do agrotóxico',
    ordem: 18,
    tipo: QuestionType.unica,
    texto: 'Você considera que o uso de agrotóxicos representa um risco à sua saúde?',
    opcoes: [
      'Sim, representa alto risco',
      'Representa algum risco',
      'Representa pouco risco',
      'Não representa risco algum',
    ],
    respostaCorreta: 'Sim, representa alto risco',
  ),
  Question(
    id: 'Q19',
    bloco: 'Riscos do agrotóxico',
    ordem: 19,
    tipo: QuestionType.unica,
    texto: 'Você já recebeu treinamento sobre uso seguro de agrotóxicos?',
    opcoes: [
      'Sim, treinamento completo',
      'Sim, orientação básica',
      'Nunca recebi nenhum treinamento',
    ],
    respostaCorreta: 'Sim, treinamento completo',
  ),
  Question(
    id: 'Q20',
    bloco: 'Riscos do agrotóxico',
    ordem: 20,
    tipo: QuestionType.unica,
    texto: 'O uso correto do EPI elimina completamente todos os riscos dos agrotóxicos?',
    opcoes: [
      'Não — reduz os riscos, mas não os elimina completamente',
      'Sim, reduz bastante os riscos',
      'Sim, usando EPI corretamente não há risco algum',
    ],
    respostaCorreta: 'Não — reduz os riscos, mas não os elimina completamente',
  ),
];

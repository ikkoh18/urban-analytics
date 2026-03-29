# CLAUDE.md — Urban Analytics System – Los Angeles

> Arquivo de contexto para Claude Code / Claude Cowork.
> Atualizado com a camada de apresentação (Flutter app + dashboard).

---

## Visão Geral

Sistema de **análise urbana orientado a dados**, focado em Los Angeles, que integra três fontes públicas de dados para identificar padrões urbanos e gerar **recomendações para pessoas que visitam ou se mudam para uma cidade desconhecida**.

**Caso de uso principal:** uma pessoa do Brasil viajando para Los Angeles usa o sistema para entender padrões de tráfego, pontos críticos de criminalidade e janelas de risco por horário — sem conhecer a cidade.

O sistema é composto por dois módulos principais:

1. **Pipeline de dados** — ingestão, limpeza, integração e analytics em Python
2. **App mobile Flutter** — mapa interativo + dashboard analítico como camada de apresentação

---

## Fontes de Dados

### Crime
- **Fonte:** LA Open Data API
- **URL:** `https://data.lacity.org/resource/2nrs-mtv8.json`
- **Período:** 2020 → presente
- **Variáveis relevantes:** `date_occ`, `time_occ`, `crm_cd_desc`, `vict_age`, `vict_sex`, `weapon_used_cd`, `lat`, `lon`, `area_name`
- **Ingestão:** `python -m src.ingestion.crime_ingest`

### Tráfego
- **Fonte:** Caltrans PeMS – District 7 (Los Angeles)
- **Tipo:** Station Hour data (arquivos `.txt.gz`)
- **Variáveis:** `timestamp`, `station_id`, `total_flow`, `avg_speed`, `avg_occupancy`
- **Granularidade:** horária
- **Ingestão:** download manual → `data/raw/traffic/`

### Clima
- **Fonte:** Meteostat API
- **Variáveis:** `timestamp`, `temp` (temperatura), `prcp` (precipitação)
- **Granularidade:** horária
- **Ingestão:** `python -m src.ingestion.weather_ingest`

---

## Arquitetura do Sistema

```
Fontes Públicas (Crime API · PeMS · Meteostat)
              ↓
          Camada RAW
    data/raw/crime|traffic|weather
              ↓
      Camada de Processamento
    limpeza · timestamps · merge
              ↓
       Camada de Analytics
    agregações · correlações · métricas
              ↓
         Backend API
    FastAPI ou Firebase (a definir)
              ↓
       App Flutter (mobile)
    Mapa interativo · Dashboard analítico
```

---

## Estrutura do Repositório

```
urban-analytics/
├── data/
│   ├── raw/
│   │   ├── crime/
│   │   ├── traffic/
│   │   └── weather/
│   └── processed/
│       ├── crime/
│       ├── traffic/
│       └── weather/
├── src/
│   ├── ingestion/
│   │   ├── crime_ingest.py
│   │   └── weather_ingest.py
│   ├── processing/
│   │   ├── clean_crime.py
│   │   ├── clean_traffic.py
│   │   ├── clean_weather.py
│   │   ├── merge_traffic.py
│   │   └── integrate_datasets.py
│   ├── analytics/
│   └── config/
│       └── settings.py
├── app/                          # App Flutter (a criar)
│   ├── lib/
│   │   ├── data/                 # Modelos, repositórios, chamadas à API
│   │   ├── domain/               # Casos de uso, score de risco
│   │   └── presentation/         # Widgets, telas, BLoCs
│   └── pubspec.yaml
├── notebooks/
│   └── exploration.ipynb
├── docs/
├── reports/
├── .env
├── requirements.txt
├── README.md
└── CLAUDE.md
```

---

## App Flutter

### Visão Geral
- Framework: **Flutter** (Android + iOS, base de código única)
- Padrão de arquitetura: **BLoC** (Business Logic Component)
- Navegação: bottom navigation bar com duas telas principais

### Telas
| Tela | Descrição |
|---|---|
| Mapa interativo | Dados georeferenciados com 4 camadas e filtros |
| Dashboard analítico | Gráficos de crime, tráfego e correlações |

### Mapa — Camadas disponíveis
- Heatmap de densidade criminal (lat/lon dos registros do LAPD)
- Fluxo de tráfego nas vias (velocidade média por segmento, dados PeMS)
- Alertas de risco por horário (combinação crime + congestionamento)
- Camada de clima/chuva (precipitação e temperatura Meteostat)

Todas as camadas são habilitáveis/desabilitáveis individualmente. Filtros por faixa horária e dia da semana. Ao tocar em uma região: score de risco em 3 níveis (reduzido / moderado / elevado).

### Dashboard — Blocos
- **Crime:** distribuição de ocorrências por hora do dia + tendência semanal
- **Tráfego:** curva de fluxo veicular + velocidade média por faixa horária
- **Correlações:** precipitação vs velocidade média · criminalidade vs tráfego por hora

Seletor de período no topo: dia da semana, mês ou faixa de datas personalizada.

### Recomendações e Predições
Módulo de previsão futura — camada mais avançada do app:

- **Predição de tráfego:** modelos SARIMA ou Prophet treinados sobre séries horárias de fluxo e velocidade, capturando sazonalidade semanal e diária
- **Predição de risco:** regressão ou gradient boosting cruzando horário, dia da semana, temperatura e precipitação para estimar probabilidade de ocorrências por área
- **Recomendações contextuais:** sugestões práticas em linguagem simples — melhor horário para atravessar uma região, rotas alternativas em dias de chuva, alertas de janelas horárias críticas por bairro
- Os modelos são treinados no backend; o app consome apenas as predições finais via API, sem processamento local

### Pacotes Flutter previstos
| Pacote | Uso |
|---|---|
| `flutter_map` | Renderização do mapa com tiles OpenStreetMap |
| `fl_chart` | Gráficos do dashboard |
| `flutter_bloc` | Gerenciamento de estado BLoC |
| `dio` | Chamadas HTTP à API (se FastAPI) |

### Backend (a definir após M4)
Opções em avaliação:
- **FastAPI + PostgreSQL** — API REST centralizada, lógica analítica no servidor
- **Firebase** — sincronização de dados pré-processados, infraestrutura simplificada

A decisão será tomada após conhecer o volume e frequência de atualização do `urban_dataset_2025.csv`.

---

## Setup do Ambiente Python

```bash
git clone <url-do-repositorio>
cd urban-analytics
python -m venv .venv
source .venv/bin/activate        # macOS/Linux
# .venv\Scripts\Activate         # Windows PowerShell
pip install -r requirements.txt

# Arquivo .env na raiz:
CRIME_API_URL=https://data.lacity.org/resource/2nrs-mtv8.json
CRIME_API_LIMIT=50000
```

---

## Status Atual dos Datasets

| Dataset | Status | Arquivo processado |
|---|---|---|
| Tráfego | ✅ Processado | `traffic_2025_core.csv` |
| Crime | ❗ Bruto (2020–presente) | — |
| Clima | ❗ Bruto | — |

---

## Tarefas Pendentes — Pipeline

### Tarefa 1 — Limpeza dos dados de crime
**Script:** `src/processing/clean_crime.py`
**Output:** `data/processed/crime/crime_2020_2025_clean.csv`

```python
df['time_str'] = df['time_occ'].astype(str).str.zfill(4)
df['timestamp'] = pd.to_datetime(
    df['date_occ'] + ' ' + df['time_str'],
    format='%m/%d/%Y %H%M'
)
# Colunas: timestamp, crm_cd_desc, vict_age, vict_sex,
#          weapon_used_cd, lat, lon, area_name
# Remover lat == 0
```

### Tarefa 2 — Limpeza dos dados de clima
**Script:** `src/processing/clean_weather.py`
**Output:** `data/processed/weather/weather_2025_clean.csv`

- `time` → `timestamp`, `temp` → `temperature`, `prcp` → `precipitation`
- Preencher lacunas de precipitação com `0`

### Tarefa 3 — Agregação horária

```python
# Crime
crime_hourly = df.groupby(
    pd.Grouper(key='timestamp', freq='H')
).size().reset_index(name='crime_count')

# Tráfego: total_flow (soma), avg_speed (média) por hora
```

### Tarefa 4 — Integração
**Script:** `src/processing/integrate_datasets.py`
**Output:** `data/processed/urban_dataset_2025.csv`

```
timestamp | crime_count | traffic_flow | avg_speed | temperature | precipitation
```

- Outer join nos três datasets via `timestamp`
- Forward-fill para clima

---

## Roadmap

| Milestone | Entregável | Status |
|---|---|---|
| M1 — Ingestão | Arquivos brutos em `data/raw/` | ✅ Concluído |
| M2 — Tráfego processado | `traffic_2025_core.csv` | ✅ Concluído |
| M3 — Limpeza crime + clima | Dois CSVs processados | 🔄 Em andamento |
| M4 — Integração | `urban_dataset_2025.csv` | ⏳ Pendente |
| M5 — Analytics exploratória | Notebook de correlações | ⏳ Pendente |
| M6 — Indicadores de risco | Regras de recomendação | ⏳ Pendente |
| M7 — App Flutter + backend | Mapa + dashboard mobile | ⏳ Pendente |

---

## Convenções do Projeto

| Item | Padrão |
|---|---|
| Encoding | UTF-8 |
| Timestamps | `datetime64` após limpeza |
| Nomes de colunas | `snake_case` em inglês |
| Separador CSV | vírgula `,` |
| Fuso horário | `America/Los_Angeles` (quando aplicável) |
| Ambiente virtual | `.venv` na raiz |
| Variáveis de ambiente | arquivo `.env` (não versionar) |

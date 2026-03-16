# CLAUDE.md — Urban Analytics System – Los Angeles

> Arquivo de contexto para Claude Code / Claude Cowork.
> Gerado a partir do README oficial + contexto do projeto.

---

## Visão Geral

Sistema de **análise urbana orientado a dados**, focado em Los Angeles, que integra três fontes públicas de dados para identificar padrões urbanos e gerar **recomendações para pessoas que visitam ou se mudam para uma cidade desconhecida**.

**Caso de uso principal:** uma pessoa do Brasil viajando para Los Angeles usa o sistema para entender padrões de tráfego, pontos críticos de criminalidade e janelas de risco por horário — sem conhecer a cidade.

O sistema analisa dados históricos e gera insights sobre:

- quais áreas têm **maior incidência de crimes**
- quais horários concentram **tráfego intenso**
- como o **clima impacta o congestionamento**
- quando evitar certas áreas ou horários de deslocamento

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

## Arquitetura do Pipeline

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
    Insights & Recomendações
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

## Setup do Ambiente

```bash
# 1. Clonar o repositório
git clone <url-do-repositorio>
cd urban-analytics

# 2. Criar e ativar ambiente virtual
python -m venv .venv
source .venv/bin/activate        # macOS/Linux
# .venv\Scripts\Activate         # Windows PowerShell

# 3. Instalar dependências
pip install -r requirements.txt

# 4. Criar arquivo .env na raiz
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

## Tarefas Pendentes

### Tarefa 1 — Limpeza dos dados de crime
**Script:** `src/processing/clean_crime.py`
**Output:** `data/processed/crime/crime_2020_2025_clean.csv`

```python
# Combinar date_occ + time_occ em timestamp
df['time_str'] = df['time_occ'].astype(str).str.zfill(4)
df['timestamp'] = pd.to_datetime(
    df['date_occ'] + ' ' + df['time_str'],
    format='%m/%d/%Y %H%M'
)
# Colunas finais: timestamp, crm_cd_desc, vict_age, vict_sex,
#                 weapon_used_cd, lat, lon, area_name
# Remover linhas com lat == 0 (geocódigos inválidos)
```

---

### Tarefa 2 — Limpeza dos dados de clima
**Script:** `src/processing/clean_weather.py`
**Output:** `data/processed/weather/weather_2025_clean.csv`

- Manter: `time` → `timestamp`, `temp` → `temperature`, `prcp` → `precipitation`
- Preencher lacunas de precipitação com `0`

---

### Tarefa 3 — Agregação horária

**Crime:**
```python
crime_hourly = df.groupby(
    pd.Grouper(key='timestamp', freq='H')
).size().reset_index(name='crime_count')
```

**Tráfego:** agregar todas as estações por hora → `total_flow` (soma), `avg_speed` (média)

---

### Tarefa 4 — Integração dos datasets
**Script:** `src/processing/integrate_datasets.py`
**Output:** `data/processed/urban_dataset_2025.csv`

Estrutura esperada:
```
timestamp | crime_count | traffic_flow | avg_speed | temperature | precipitation
```

- Outer join nos três datasets via `timestamp`
- Forward-fill para clima (muda lentamente)

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
| M7 — Dashboard / visualização | Entregável final | ⏳ Pendente |

---

## Análises Planejadas (pós-integração)

- Horários de pico de tráfego por área
- Correlação entre chuva e congestionamento
- Correlação entre tráfego e criminalidade
- Indicadores de risco urbano por área e horário
- Regras de recomendação baseadas em evidências
- Dashboard interativo de visualização

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

---

## Objetivo Final

Este projeto demonstra um pipeline de engenharia de dados profissional com:

- design de pipeline multicamada (RAW → Processing → Analytics)
- integração de múltiplas fontes públicas
- análise temporal e espacial
- suporte a decisões baseadas em evidências urbanas

É um sistema de inteligência urbana — não apenas um dashboard.
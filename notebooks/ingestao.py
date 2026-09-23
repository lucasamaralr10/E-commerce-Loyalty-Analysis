#%%
from pathlib import Path
import pandas as pd
import sqlite3
import os
import json

# Define a estrutura de pastas usando o caminho do script
PASTA_SCRIPT = Path(os.getcwd()) if 'os' in locals() else Path(".").resolve()
RAIZ_PROJETO = PASTA_SCRIPT.parent if PASTA_SCRIPT.name == "scripts" else PASTA_SCRIPT

csv_path = RAIZ_PROJETO / "data" / "Transacao_de_vendas.csv"
db_path = RAIZ_PROJETO / "queries" / "database.db"
relatorio_path = RAIZ_PROJETO / "data" / "relatorio_qualidade.json"

db_path.parent.mkdir(parents=True, exist_ok=True)
print("📂 Pastas e caminhos estruturados com sucesso!")


#%%
print("🔄 Carregando o arquivo CSV... (Aguarde alguns segundos)")

try:
    df = pd.read_csv(csv_path, low_memory=False, encoding='utf-8')
except UnicodeDecodeError:
    df = pd.read_csv(csv_path, low_memory=False, encoding='latin1')

total_linhas_originais = df.shape[0]

# Renomeia todas as colunas originais em inglês para português
colunas_traduzidas = {
    'TransactionNo': 'id_transacao',
    'Date': 'data_transacao',
    'ProductNo': 'id_produto',
    'ProductName': 'nome_produto',
    'Price': 'preco_unitario',
    'Quantity': 'quantidade',
    'CustomerNo': 'id_cliente',
    'Country': 'pais_cliente'
}
df.rename(columns=colunas_traduzidas, inplace=True)

print(f"✅ Carregado! {total_linhas_originais:,} linhas brutas.")
df.head(3)


#%%
# Tratamento da Data: formato M/D/AAAA -> AAAA-MM-DD
df['data_transacao'] = pd.to_datetime(
    df['data_transacao'], format='%m/%d/%Y', errors='coerce'
).dt.strftime('%Y-%m-%d')

print("📅 Datas padronizadas para AAAA-MM-DD.")


#%%
# Dicionário completo de tradução de países
dicionario_paises = {
    'United Kingdom': 'Reino Unido', 'France': 'França', 'Germany': 'Alemanha',
    'EIRE': 'Irlanda', 'Netherlands': 'Holanda', 'Australia': 'Austrália',
    'Portugal': 'Portugal', 'Switzerland': 'Suíça', 'Spain': 'Espanha',
    'Sweden': 'Suécia', 'Belgium': 'Bélgica', 'Norway': 'Noruega',
    'Italy': 'Itália', 'Cyprus': 'Chipre', 'Japan': 'Japão',
    'Israel': 'Israel', 'Poland': 'Polônia', 'Denmark': 'Dinamarca',
    'Austria': 'Áustria', 'Singapore': 'Cingapura', 'Finland': 'Finlândia',
    'Greece': 'Grécia', 'Iceland': 'Islândia', 'Malta': 'Malta',
    'RSA': 'África do Sul', 'USA': 'Estados Unidos', 'Lebanon': 'Líbano',
    'Lithuania': 'Lituânia', 'Brazil': 'Brasil', 'Bahrain': 'Bahrein',
    'Saudi Arabia': 'Arábia Saudita', 'United Arab Emirates': 'Emirados Árabes',
    'European Community': 'Comunidade Europeia',
    'Unspecified': 'Não Especificado',
    'Channel Islands': 'Ilhas do Canal',
    'Czech Republic': 'República Tcheca'
}

df['pais_cliente'] = df['pais_cliente'].map(dicionario_paises).fillna(df['pais_cliente'])
print("🌍 Países traduzidos (com fallback para valores não mapeados).")


#%%
# Tratamento de tipos financeiros
df['preco_unitario'] = pd.to_numeric(df['preco_unitario'], errors='coerce').round(2)
df['quantidade'] = pd.to_numeric(df['quantidade'], errors='coerce')

# Remove (não zera) linhas com quantidade inválida/ausente
qtd_invalida_removida = df['quantidade'].isna().sum()
df = df[df['quantidade'].notna()].copy()
df['quantidade'] = df['quantidade'].astype(int)

print(f"⚠️ {qtd_invalida_removida} linhas com quantidade inválida removidas.")


#%%
# Tratamento do id_cliente (crítico: sem isso ele vira REAL no banco e quebra os JOINs)
qtd_nulos_cliente = df['id_cliente'].isna().sum()
df = df[df['id_cliente'].notna()].copy()
df['id_cliente'] = df['id_cliente'].astype('int64')

print(f"⚠️ Removidos {qtd_nulos_cliente} registros sem id_cliente "
      f"({qtd_nulos_cliente/total_linhas_originais:.2%} da base).")


#%%
# Deduplicação
duplicatas_removidas = df.duplicated().sum()
df = df.drop_duplicates()

print(f"🧹 Removidas {duplicatas_removidas} linhas 100% duplicadas.")


#%%
# Flag de cancelamento: cruzando dois sinais (prefixo 'C' em id_transacao x quantidade negativa)
df['flag_cancelado_por_prefixo'] = df['id_transacao'].astype(str).str.startswith('C')
df['flag_cancelado_por_quantidade'] = df['quantidade'] < 0

divergencia_cancelamento = (
    df['flag_cancelado_por_prefixo'] != df['flag_cancelado_por_quantidade']
).sum()

# Regra de negócio adotada: prefixo 'C' é o critério oficial de cancelamento
# (é o identificador original do sistema de vendas, mais confiável que o sinal da quantidade)
df['flag_cancelado'] = df['flag_cancelado_por_prefixo'].astype(int)

print(f"🔍 {divergencia_cancelamento} linhas onde prefixo 'C' e quantidade negativa DIVERGEM.")
print(f"📌 flag_cancelado criada com base no prefixo 'C' (critério oficial).")


#%%
# Flag de outlier de quantidade (IQR calculado só sobre vendas válidas, não canceladas)
vendas_validas = df[df['flag_cancelado'] == 0]

Q1 = vendas_validas['quantidade'].quantile(0.25)
Q3 = vendas_validas['quantidade'].quantile(0.75)
IQR = Q3 - Q1
limite_inf, limite_sup = Q1 - 1.5 * IQR, Q3 + 1.5 * IQR

# Aplica a flag em todo o df, mas os limites vieram só das vendas válidas
df['flag_outlier_quantidade'] = (df['flag_cancelado'] == 0) & (
    ~df['quantidade'].between(limite_inf, limite_sup)
)

print(f"📌 {df['flag_outlier_quantidade'].sum()} transações de venda sinalizadas como outlier.")
print(f"   (limites considerados normais: {limite_inf:.1f} a {limite_sup:.1f})")

#%%
# Relatório consolidado de qualidade de dados
relatorio_qualidade = {
    "total_linhas_originais": int(total_linhas_originais),
    "quantidade_invalida_removida": int(qtd_invalida_removida),
    "nulos_id_cliente_removidos": int(qtd_nulos_cliente),
    "duplicatas_removidas": int(duplicatas_removidas),
    "divergencia_flag_cancelamento": int(divergencia_cancelamento),
    "outliers_quantidade_sinalizados": int(df['flag_outlier_quantidade'].sum()),
    "total_linhas_finais": int(df.shape[0]),
}

with open(relatorio_path, "w", encoding="utf-8") as f:
    json.dump(relatorio_qualidade, f, ensure_ascii=False, indent=2)

print("📊 Relatório de qualidade salvo em:", relatorio_path)
print(json.dumps(relatorio_qualidade, ensure_ascii=False, indent=2))


#%%
# Gravação final no banco
print("🗄️ Gravando os dados tratados na tabela 'tb_raw_vendas'...")

conn = sqlite3.connect(db_path)
df.to_sql("tb_raw_vendas", conn, if_exists="replace", index=False)
conn.close()

print(f"🎉 Banco de dados recriado em: {db_path}")
df.head(3)
# %%

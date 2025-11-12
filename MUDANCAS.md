# Mudanças Implementadas - psycopg2 Layer

## Arquivos Criados/Modificados

### 1. Nova Estrutura de Diretórios
```
src/lambda/layers/psycopg2/
└── requirements.txt
```

### 2. Arquivos Terraform Atualizados

**lambda.tf**
- Substituído data sources por módulo `terraform-aws-modules/lambda`
- Lambda Layer psycopg2 com build automático
- Python Lambda usando o módulo com layer anexada

**api-gateway.tf**
- Atualizado referências de `aws_lambda_function.python_lambda.*` para `module.python_lambda.*`

### 3. Pipeline CI/CD Atualizado

**pipeline-cicd.yaml**
- Removido build manual de Lambda Python
- Adicionado setup do Python 3.11
- Módulo Terraform gerencia build automaticamente

### 4. Código Python Atualizado

**lambda_function.py**
- Exemplo funcional usando psycopg2
- Conexão com PostgreSQL RDS
- Error handling

## Como Funciona

1. O módulo `terraform-aws-modules/lambda` detecta `requirements.txt`
2. Durante `terraform plan/apply`, executa `pip install` automaticamente
3. Cria layer com estrutura correta (`python/` prefix)
4. Lambda Python recebe a layer via `layers = [module.psycopg2_layer.lambda_layer_arn]`

## Vantagens

- Build automático da layer
- Não precisa Docker local
- requirements.txt versionado
- Biblioteca compilada não fica no Git
- Compatível com runtime Lambda automaticamente

## Deploy

```bash
cd src/terraform
terraform init
terraform plan -var-file=tfvars/development.tfvars
terraform apply -var-file=tfvars/development.tfvars -auto-approve
```

## Testando

```bash
# Obter URL da API
terraform output api_gateway_url

# Testar endpoint Python
curl https://[API_URL]/python

# Resposta esperada:
{
  "message": "Conexao com PostgreSQL estabelecida!",
  "database_version": "PostgreSQL 17.4...",
  "environment": "development"
}
```

## Adicionando Novas Bibliotecas

Edite `src/lambda/layers/psycopg2/requirements.txt`:
```txt
psycopg2-binary==2.9.9
requests==2.31.0
boto3==1.34.0
```

Execute `terraform apply` - o módulo rebuilda automaticamente.

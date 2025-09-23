#!/bin/bash

echo "🧪 Testando Website da Padaria Online"
echo "======================================"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para testar URL
test_url() {
    local url=$1
    local description=$2
    
    echo -n "Testando $description... "
    
    status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    
    if [ "$status_code" = "200" ]; then
        echo -e "${GREEN}✅ OK (Status: $status_code)${NC}"
        return 0
    else
        echo -e "${RED}❌ ERRO (Status: $status_code)${NC}"
        return 1
    fi
}

# Navega para o diretório terraform
cd src/terraform

# Verifica se terraform está inicializado
if [ ! -d ".terraform" ]; then
    echo -e "${YELLOW}⚠️ Terraform não está inicializado. Execute 'terraform init' primeiro.${NC}"
    exit 1
fi

# Obtém as URLs do terraform output
echo "📡 Obtendo URLs do deployment..."

HTTP_URL=$(terraform output -raw website_endpoint 2>/dev/null)
HTTPS_URL=$(terraform output -raw https_website_url 2>/dev/null)

if [ -z "$HTTP_URL" ] || [ -z "$HTTPS_URL" ]; then
    echo -e "${RED}❌ Não foi possível obter as URLs. Execute 'terraform apply' primeiro.${NC}"
    exit 1
fi

echo ""
echo "🌐 URLs encontradas:"
echo "HTTP:  http://$HTTP_URL"
echo "HTTPS: $HTTPS_URL"
echo ""

# Testa URLs
echo "🔍 Executando testes..."
echo ""

# Testa página inicial HTTPS
test_url "$HTTPS_URL" "Página inicial (HTTPS)"

# Testa página sobre HTTPS
test_url "$HTTPS_URL/sobre.html" "Página Sobre (HTTPS)"

# Testa arquivos estáticos HTTPS
test_url "$HTTPS_URL/styles.css" "CSS (HTTPS)"
test_url "$HTTPS_URL/script.js" "JavaScript (HTTPS)"

# Testa página 404 HTTPS
echo -n "Testando página 404 (HTTPS)... "
status_code=$(curl -s -o /dev/null -w "%{http_code}" "$HTTPS_URL/pagina-inexistente")
if [ "$status_code" = "404" ]; then
    echo -e "${GREEN}✅ OK (Status: $status_code)${NC}"
else
    echo -e "${YELLOW}⚠️ Inesperado (Status: $status_code)${NC}"
fi

echo ""

# Testa página inicial HTTP (comparação)
echo "📊 Comparando com HTTP:"
test_url "http://$HTTP_URL" "Página inicial (HTTP)"

echo ""
echo "🏁 Testes concluídos!"
echo ""
echo -e "${GREEN}💡 Use a URL HTTPS para produção:${NC}"
echo -e "${GREEN}   $HTTPS_URL${NC}"
echo ""
echo -e "${YELLOW}📝 Notas:${NC}"
echo "   • A URL HTTPS é servida via API Gateway com SSL/TLS"
echo "   • A URL HTTP é servida diretamente do S3 (sem SSL)"
echo "   • Ambas servem o mesmo conteúdo"
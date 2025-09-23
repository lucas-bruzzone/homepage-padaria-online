const AWS = require('aws-sdk');
const s3 = new AWS.S3();

const BUCKET_NAME = process.env.BUCKET_NAME;

// Mapeamento de tipos de arquivo
const contentTypes = {
    '.html': 'text/html; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.js': 'application/javascript; charset=utf-8',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
    '.txt': 'text/plain; charset=utf-8'
};

function getContentType(path) {
    const ext = path.toLowerCase().substring(path.lastIndexOf('.'));
    return contentTypes[ext] || 'text/plain; charset=utf-8';
}

async function getFileFromS3(key) {
    try {
        const params = {
            Bucket: BUCKET_NAME,
            Key: key
        };
        
        console.log(`Tentando buscar arquivo: ${key} no bucket: ${BUCKET_NAME}`);
        const data = await s3.getObject(params).promise();
        
        return {
            body: data.Body.toString('utf-8'),
            contentType: getContentType(key),
            found: true
        };
    } catch (error) {
        console.log(`Arquivo não encontrado: ${key}`, error.code);
        return { found: false };
    }
}

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    let path = event.rawPath || event.pathParameters?.proxy || event.path || '/';
    
    // Remove barra inicial se existir
    if (path.startsWith('/')) {
        path = path.substring(1);
    }
    
    // Se for raiz ou vazio, serve index.html
    if (!path || path === '' || path === '/') {
        path = 'index.html';
    }
    
    console.log(`Processando requisição para: ${path}`);
    
    try {
        // Tenta buscar o arquivo no S3
        const file = await getFileFromS3(path);
        
        if (file.found) {
            console.log(`Arquivo encontrado: ${path}`);
            return {
                statusCode: 200,
                headers: {
                    'Content-Type': file.contentType,
                    'Cache-Control': 'public, max-age=300',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type'
                },
                body: file.body
            };
        }
        
        // Se não encontrou e não é index.html, tenta index.html (para SPAs)
        if (path !== 'index.html') {
            console.log(`Arquivo ${path} não encontrado, tentando index.html`);
            const indexFile = await getFileFromS3('index.html');
            if (indexFile.found) {
                return {
                    statusCode: 200,
                    headers: {
                        'Content-Type': 'text/html; charset=utf-8',
                        'Cache-Control': 'public, max-age=300',
                        'Access-Control-Allow-Origin': '*'
                    },
                    body: indexFile.body
                };
            }
        }
        
        // Arquivo não encontrado - retorna 404 customizado
        console.log(`Arquivo não encontrado: ${path}`);
        return {
            statusCode: 404,
            headers: {
                'Content-Type': 'text/html; charset=utf-8',
                'Access-Control-Allow-Origin': '*'
            },
            body: `
                <!DOCTYPE html>
                <html lang="pt-BR">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>404 - Página não encontrada</title>
                    <style>
                        body { 
                            font-family: Arial, sans-serif; 
                            text-align: center; 
                            padding: 50px;
                            background-color: #f9f9f9;
                        }
                        h1 { color: #8B4513; margin-bottom: 20px; }
                        p { color: #666; margin-bottom: 30px; }
                        a { 
                            color: #8B4513; 
                            text-decoration: none; 
                            padding: 10px 20px;
                            border: 2px solid #8B4513;
                            border-radius: 5px;
                            transition: all 0.3s;
                        }
                        a:hover { 
                            background-color: #8B4513; 
                            color: white; 
                        }
                        .logo { font-size: 2em; margin-bottom: 20px; }
                    </style>
                </head>
                <body>
                    <div class="logo">🥖</div>
                    <h1>404 - Página não encontrada</h1>
                    <p>O arquivo "<strong>${path}</strong>" não foi encontrado na Padaria Online.</p>
                    <a href="/">🏠 Voltar ao início</a>
                </body>
                </html>
            `
        };
        
    } catch (error) {
        console.error('Erro interno:', error);
        
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                error: 'Erro interno do servidor',
                message: 'Ocorreu um erro ao processar sua solicitação.',
                timestamp: new Date().toISOString()
            }, null, 2)
        };
    }
};
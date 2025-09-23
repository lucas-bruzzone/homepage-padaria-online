const AWS = require('aws-sdk');
const s3 = new AWS.S3();

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    const bucketName = process.env.BUCKET_NAME;
    let path = event.rawPath || '/';
    
    console.log('Original path:', path);
    
    // Se for root, serve index.html
    if (path === '/') {
        path = '/index.html';
    }
    
    // Remove leading slash para o S3 key
    const key = path.startsWith('/') ? path.substring(1) : path;
    
    console.log('S3 Key:', key);
    console.log('Bucket:', bucketName);
    
    try {
        // Busca o arquivo no S3
        const params = {
            Bucket: bucketName,
            Key: key
        };
        
        console.log('Fetching from S3:', params);
        const data = await s3.getObject(params).promise();
        
        // Função melhorada para determinar content type
        const getContentType = (filename) => {
            const ext = filename.toLowerCase().split('.').pop();
            const types = {
                'html': 'text/html; charset=utf-8',
                'htm': 'text/html; charset=utf-8',
                'css': 'text/css; charset=utf-8',
                'js': 'application/javascript; charset=utf-8',
                'mjs': 'application/javascript; charset=utf-8',
                'json': 'application/json; charset=utf-8',
                'xml': 'application/xml; charset=utf-8',
                'txt': 'text/plain; charset=utf-8',
                
                // Imagens
                'png': 'image/png',
                'jpg': 'image/jpeg',
                'jpeg': 'image/jpeg',
                'gif': 'image/gif',
                'webp': 'image/webp',
                'svg': 'image/svg+xml',
                'ico': 'image/x-icon',
                'bmp': 'image/bmp',
                
                // Fontes
                'woff': 'font/woff',
                'woff2': 'font/woff2',
                'ttf': 'font/ttf',
                'otf': 'font/otf',
                'eot': 'application/vnd.ms-fontobject',
                
                // Outros
                'pdf': 'application/pdf',
                'zip': 'application/zip',
                'mp4': 'video/mp4',
                'mp3': 'audio/mpeg'
            };
            
            const contentType = types[ext] || 'application/octet-stream';
            console.log(`File: ${filename}, Extension: ${ext}, Content-Type: ${contentType}`);
            return contentType;
        };
        
        const contentType = getContentType(key);
        
        // Determina se precisa de base64 encoding
        const needsBase64 = 
            contentType.startsWith('image/') || 
            contentType.startsWith('font/') ||
            contentType.startsWith('video/') ||
            contentType.startsWith('audio/') ||
            contentType === 'application/pdf' ||
            contentType === 'application/zip' ||
            contentType === 'application/octet-stream';
        
        console.log('Content-Type:', contentType);
        console.log('Needs Base64:', needsBase64);
        
        // Headers otimizados
        const headers = {
            'Content-Type': contentType,
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization'
        };
        
        // Cache strategy
        if (contentType.startsWith('text/html')) {
            headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';
            headers['Pragma'] = 'no-cache';
            headers['Expires'] = '0';
        } else {
            // Cache assets por 1 ano
            headers['Cache-Control'] = 'public, max-age=31536000, immutable';
        }
        
        const response = {
            statusCode: 200,
            headers: headers,
            body: needsBase64 ? data.Body.toString('base64') : data.Body.toString('utf-8'),
            isBase64Encoded: needsBase64
        };
        
        console.log('Success - Response headers:', response.headers);
        console.log('Body length:', response.body.length);
        
        return response;
        
    } catch (error) {
        console.error('Error details:', {
            code: error.code,
            message: error.message,
            key: key,
            bucket: bucketName
        });
        
        // Se não encontrar o arquivo e não for uma API route, serve index.html (SPA fallback)
        if (error.code === 'NoSuchKey' && !path.startsWith('/api/')) {
            console.log('File not found, trying fallback to index.html');
            try {
                const indexParams = {
                    Bucket: bucketName,
                    Key: 'index.html'
                };
                
                console.log('Fetching fallback:', indexParams);
                const indexData = await s3.getObject(indexParams).promise();
                
                return {
                    statusCode: 200,
                    headers: {
                        'Content-Type': 'text/html; charset=utf-8',
                        'Cache-Control': 'no-cache, no-store, must-revalidate',
                        'Access-Control-Allow-Origin': '*'
                    },
                    body: indexData.Body.toString('utf-8')
                };
                
            } catch (indexError) {
                console.error('Error loading index.html:', indexError);
            }
        }
        
        return {
            statusCode: 404,
            headers: {
                'Content-Type': 'application/json; charset=utf-8',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                error: 'File not found',
                path: path,
                key: key,
                bucket: bucketName,
                message: error.message,
                timestamp: new Date().toISOString()
            }, null, 2)
        };
    }
};
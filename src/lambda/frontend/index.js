const AWS = require('aws-sdk');
const s3 = new AWS.S3();

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    const bucketName = process.env.BUCKET_NAME;
    let path = event.rawPath || '/';
    
    // Se for root, serve index.html
    if (path === '/') {
        path = '/index.html';
    }
    
    // Remove leading slash
    const key = path.startsWith('/') ? path.substring(1) : path;
    
    try {
        // Busca o arquivo no S3
        const params = {
            Bucket: bucketName,
            Key: key
        };
        
        const data = await s3.getObject(params).promise();
        
        // Determina o content type baseado na extensão
        const getContentType = (filename) => {
            const ext = filename.toLowerCase().split('.').pop();
            const types = {
                'html': 'text/html',
                'css': 'text/css',
                'js': 'application/javascript',
                'json': 'application/json',
                'png': 'image/png',
                'jpg': 'image/jpeg',
                'jpeg': 'image/jpeg',
                'gif': 'image/gif',
                'svg': 'image/svg+xml',
                'ico': 'image/x-icon',
                'woff': 'font/woff',
                'woff2': 'font/woff2',
                'ttf': 'font/ttf',
                'eot': 'application/vnd.ms-fontobject'
            };
            return types[ext] || 'text/plain';
        };
        
        const contentType = getContentType(key);
        const isBase64 = contentType.startsWith('image/') || contentType.startsWith('font/');
        
        return {
            statusCode: 200,
            headers: {
                'Content-Type': contentType,
                'Cache-Control': contentType.startsWith('text/html') ? 'no-cache' : 'max-age=31536000'
            },
            body: isBase64 ? data.Body.toString('base64') : data.Body.toString(),
            isBase64Encoded: isBase64
        };
        
    } catch (error) {
        console.error('Error:', error);
        
        // Se não encontrar o arquivo e não for uma API route, serve index.html (SPA fallback)
        if (error.code === 'NoSuchKey' && !path.startsWith('/api/')) {
            try {
                const indexParams = {
                    Bucket: bucketName,
                    Key: 'index.html'
                };
                
                const indexData = await s3.getObject(indexParams).promise();
                
                return {
                    statusCode: 200,
                    headers: {
                        'Content-Type': 'text/html',
                        'Cache-Control': 'no-cache'
                    },
                    body: indexData.Body.toString()
                };
                
            } catch (indexError) {
                console.error('Error loading index.html:', indexError);
            }
        }
        
        return {
            statusCode: 404,
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                message: 'File not found',
                path: path
            })
        };
    }
};
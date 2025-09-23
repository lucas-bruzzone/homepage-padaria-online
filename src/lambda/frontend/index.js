const AWS = require('aws-sdk');
const s3 = new AWS.S3();

exports.handler = async (event) => {
    console.log('Frontend Lambda - Request:', event.rawPath);
    
    const bucketName = process.env.BUCKET_NAME;
    let path = event.rawPath || '/';
    
    // Se for root, serve index.html
    if (path === '/') {
        path = '/index.html';
    }
    
    // Remove leading slash para o S3 key
    const key = path.startsWith('/') ? path.substring(1) : path;
    
    console.log(`Requesting file: ${key} from bucket: ${bucketName}`);
    
    try {
        // Busca o arquivo no S3
        const params = {
            Bucket: bucketName,
            Key: key
        };
        
        const data = await s3.getObject(params).promise();
        console.log(`Successfully fetched: ${key}`);
        
        // Determina o content type baseado na extensão
        const getContentType = (filename) => {
            const ext = filename.toLowerCase().split('.').pop();
            
            switch (ext) {
                case 'html':
                case 'htm':
                    return 'text/html; charset=utf-8';
                case 'css':
                    return 'text/css; charset=utf-8';
                case 'js':
                case 'mjs':
                    return 'application/javascript; charset=utf-8';
                case 'json':
                    return 'application/json; charset=utf-8';
                case 'png':
                    return 'image/png';
                case 'jpg':
                case 'jpeg':
                    return 'image/jpeg';
                case 'gif':
                    return 'image/gif';
                case 'svg':
                    return 'image/svg+xml';
                case 'ico':
                    return 'image/x-icon';
                case 'woff':
                    return 'font/woff';
                case 'woff2':
                    return 'font/woff2';
                case 'ttf':
                    return 'font/ttf';
                case 'eot':
                    return 'application/vnd.ms-fontobject';
                default:
                    return 'application/octet-stream';
            }
        };
        
        const contentType = getContentType(key);
        const isTextFile = contentType.startsWith('text/') || 
                          contentType.includes('javascript') || 
                          contentType.includes('json');
        
        console.log(`Content-Type: ${contentType}, IsText: ${isTextFile}`);
        
        const response = {
            statusCode: 200,
            headers: {
                'Content-Type': contentType,
                'Cache-Control': contentType.startsWith('text/html') 
                    ? 'no-cache, no-store, must-revalidate' 
                    : 'public, max-age=31536000',
                'Access-Control-Allow-Origin': '*'
            },
            body: isTextFile ? data.Body.toString('utf-8') : data.Body.toString('base64'),
            isBase64Encoded: !isTextFile
        };
        
        return response;
        
    } catch (error) {
        console.error(`Error fetching ${key}:`, error.code, error.message);
        
        // Se não encontrar o arquivo e não for uma API route, serve index.html (SPA fallback)
        if (error.code === 'NoSuchKey' && !path.startsWith('/api/')) {
            console.log('File not found, serving index.html as fallback');
            
            try {
                const indexParams = {
                    Bucket: bucketName,
                    Key: 'index.html'
                };
                
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
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                error: 'File not found',
                path: path,
                key: key,
                message: error.message
            })
        };
    }
};
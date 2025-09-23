const AWS = require('aws-sdk');
const s3 = new AWS.S3();

exports.handler = async (event) => {
    console.log('=== LAMBDA FRONTEND DEBUG ===');
    console.log('Full Event:', JSON.stringify(event, null, 2));
    
    const bucketName = process.env.BUCKET_NAME;
    let path = event.rawPath || '/';
    
    console.log('🔍 Original path:', path);
    console.log('🪣 Bucket name:', bucketName);
    
    // Se for root, serve index.html
    if (path === '/') {
        path = '/index.html';
        console.log('📝 Root path detected, redirecting to /index.html');
    }
    
    // Remove leading slash para o S3 key
    const key = path.startsWith('/') ? path.substring(1) : path;
    
    console.log('🔑 S3 Key will be:', key);
    
    // PRIMEIRO: Vamos listar o que realmente existe no bucket
    try {
        console.log('📋 Listing S3 bucket contents...');
        const listParams = {
            Bucket: bucketName,
            MaxKeys: 20
        };
        const listResult = await s3.listObjectsV2(listParams).promise();
        console.log('📁 Files in bucket:');
        listResult.Contents.forEach(obj => {
            console.log(`  - ${obj.Key} (${obj.Size} bytes)`);
        });
    } catch (listError) {
        console.error('❌ Error listing bucket:', listError);
    }
    
    try {
        // Busca o arquivo no S3
        const params = {
            Bucket: bucketName,
            Key: key
        };
        
        console.log('🔍 Attempting to fetch from S3:', JSON.stringify(params, null, 2));
        const data = await s3.getObject(params).promise();
        console.log('✅ Successfully fetched file from S3');
        console.log('📊 File size:', data.Body.length, 'bytes');
        console.log('📋 S3 Metadata:', data.Metadata);
        console.log('🏷️ S3 ContentType:', data.ContentType);
        
        // Função para determinar content type
        const getContentType = (filename) => {
            const ext = filename.toLowerCase().split('.').pop();
            const types = {
                'html': 'text/html; charset=utf-8',
                'htm': 'text/html; charset=utf-8',
                'css': 'text/css; charset=utf-8',
                'js': 'application/javascript; charset=utf-8',
                'json': 'application/json; charset=utf-8',
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
            
            const contentType = types[ext] || 'application/octet-stream';
            console.log(`🎯 File: ${filename}, Extension: ${ext}, Determined Content-Type: ${contentType}`);
            return contentType;
        };
        
        const contentType = getContentType(key);
        const needsBase64 = contentType.startsWith('image/') || contentType.startsWith('font/');
        
        console.log('📦 Final Content-Type:', contentType);
        console.log('🔐 Needs Base64:', needsBase64);
        
        const headers = {
            'Content-Type': contentType,
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        };
        
        // Cache strategy
        if (contentType.startsWith('text/html')) {
            headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';
        } else {
            headers['Cache-Control'] = 'public, max-age=31536000';
        }
        
        const body = needsBase64 ? data.Body.toString('base64') : data.Body.toString('utf-8');
        
        const response = {
            statusCode: 200,
            headers: headers,
            body: body,
            isBase64Encoded: needsBase64
        };
        
        console.log('✅ SUCCESS - Response headers:', response.headers);
        console.log('📏 Response body length:', response.body.length);
        
        return response;
        
    } catch (error) {
        console.error('❌ ERROR DETAILS:');
        console.error('   Code:', error.code);
        console.error('   Message:', error.message);
        console.error('   StatusCode:', error.statusCode);
        console.error('   Requested Key:', key);
        console.error('   Bucket:', bucketName);
        
        // Se não encontrar o arquivo e não for uma API route, serve index.html (SPA fallback)
        if (error.code === 'NoSuchKey' && !path.startsWith('/api/')) {
            console.log('⚠️ File not found, attempting fallback to index.html');
            console.log('🔄 Original path was:', path);
            console.log('🔑 Failed key was:', key);
            
            try {
                const indexParams = {
                    Bucket: bucketName,
                    Key: 'index.html'
                };
                
                console.log('🔍 Fetching fallback:', JSON.stringify(indexParams, null, 2));
                const indexData = await s3.getObject(indexParams).promise();
                console.log('✅ Successfully loaded index.html as fallback');
                
                return {
                    statusCode: 200,
                    headers: {
                        'Content-Type': 'text/html; charset=utf-8',
                        'Cache-Control': 'no-cache',
                        'Access-Control-Allow-Origin': '*'
                    },
                    body: indexData.Body.toString('utf-8')
                };
                
            } catch (indexError) {
                console.error('❌ Error loading index.html fallback:', indexError);
            }
        }
        
        console.log('📤 Returning 404 error');
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
                errorCode: error.code,
                timestamp: new Date().toISOString(),
                availableFiles: 'Check CloudWatch logs for bucket listing'
            }, null, 2)
        };
    }
};
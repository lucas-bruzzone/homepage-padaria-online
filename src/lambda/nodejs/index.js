exports.handler = async (event, context) => {
    console.log("Hello from Node.js Lambda!");
    
    return {
        statusCode: 200,
        headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({
            message: 'Hello World from Node.js Lambda!',
            environment: process.env.ENVIRONMENT || 'development'
        })
    };
};
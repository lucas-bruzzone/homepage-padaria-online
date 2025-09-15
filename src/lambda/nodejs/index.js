exports.handler = async (event, context) => {
    console.log("Hello from Node.js Lambda!");
    
    return {
        statusCode: 200
    };
};
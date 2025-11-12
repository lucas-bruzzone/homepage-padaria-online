import json
import os
import psycopg2
from psycopg2.extras import RealDictCursor


def get_db_connection():
    """Cria conexão com PostgreSQL"""
    return psycopg2.connect(
        host=os.environ['DB_HOST'].split(':')[0],
        port=os.environ['DB_PORT'],
        database=os.environ['DB_NAME'],
        user=os.environ['DB_USERNAME'],
        password=os.environ['DB_PASSWORD']
    )


def lambda_handler(event, context):
    """Handler principal da Lambda"""
    print("Python Lambda com psycopg2 iniciada!")
    
    try:
        # Testa conexão com banco
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Exemplo de query
        cursor.execute("SELECT version();")
        db_version = cursor.fetchone()
        
        cursor.close()
        conn.close()
        
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Conexao com PostgreSQL estabelecida!",
                "database_version": db_version['version'],
                "environment": os.environ.get('ENVIRONMENT', 'unknown')
            })
        }
        
    except Exception as e:
        print(f"Erro ao conectar ao banco: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": "Erro ao conectar ao banco de dados",
                "message": str(e)
            })
        }

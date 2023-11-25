from flask import Flask, jsonify, request, make_response
import sqlite3
from flask_restful import Api, Resource
from flask_cors import CORS 

app = Flask(__name__)
api = Api(app)
CORS(app)

def get_db_connection():
    conn = sqlite3.connect('database.db')
    conn.row_factory = sqlite3.Row
    return conn

# New route to select columns based on parameters
@app.route('/select_columns', methods=['GET'])
def select_columns():

    # Get parameters from the URL
    dependent_variable = request.args.get('dependent_variable')
    independent_variable = request.args.get('independent_variable')

    # Check if parameters are provided
    if not dependent_variable or not independent_variable:
        return jsonify({'error': 'Please provide both dependent_variable and independent_variable parameters'})

    # Connect to the database
    conn = get_db_connection()
    cur = conn.cursor()

    # Construct the SQL query to select columns based on parameters
    query = f"SELECT NAME, pop_total, {dependent_variable}, {independent_variable} FROM acs_zoning"

    # Execute the query
    cur.execute(query)
    
    # Fetch the rows
    rows = [dict(row) for row in cur.fetchall()]

    # Close the database connection
    conn.close()

    # Return the selected data
    return {'data': rows}


@app.route("/")
def hello_from_root():
    return jsonify(message='Hello from the root of the Housing Explorer API')

if __name__ == "__main__":
    app.debug = False
    app.run()



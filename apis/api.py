import uuid
import firebase_admin
from firebase_admin import credentials
from firebase_admin import db

from flask import Flask, request, jsonify
import requests
import json

app = Flask(__name__)

# Fetch the service account key JSON file contents
cred = credentials.Certificate('./serviceAccountKey.json')

# Initialize the app with a service account, granting admin privileges
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://chain-link-hackathon-default-rtdb.asia-southeast1.firebasedatabase.app/'
})

# As an admin, the app has access to read and write all data, regradless of Security Rules
ref = db.reference("/private_data")

@app.before_request
def beforeRequest():
	pass
	# print("This is executed before each request.")

@app.route('/storeDetails/', methods=['POST'])
def storeDetails():
	data = request.get_json()
	if "url" in data and "title" in data and "owner_address" in data and "num_tokens" in data:
		url = data["url"]
		private_link_id = uuid.uuid1().hex
		title = data["title"]
		owner_address = data["owner_address"]
		num_tokens = data["num_tokens"]
		post_data = {
			"private_link_id" :private_link_id, 
			"title" : title,
			"url" : url,
			"owner_address" : owner_address,
			"num_tokens" : num_tokens
		}
		ref.push(post_data)
		return private_link_id
	else:
		return "Either of the field(s) is/are empty in the request",400

@app.route('/createGatedAccess/', methods=['POST'])
def createGatedAccess():
	data = request.get_json()
	if "token_id" in data and "private_link_id" in data:
		token_id = data["token_id"]
		private_link_id = data["private_link_id"]
		storedData = ref.get()
		for key, value in storedData.items():
			if(value["private_link_id"] == private_link_id):
				url = value["url"]
				title = value["title"]
				owner_address = value["owner_address"]
				headers = {
				    'accept': 'application/json',
				    'Content-Type': 'application/json',
				}
				mintgate_params = {
					"url": url,
					"title": title,
					"tokens": [
					{
						"token": "0xA8337c9EdBeF1885cf6Dee4C4951e60cB93C426F",
						"ttype": "1155",
						"balance": 1,
						"network": 45,
						"subid": token_id
					}
					],
					"descr": "Gated access link",
					"img": "",
					"jwt": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOiIxMzY5MCIsInNjb3Blc19hcGkiOlsiYXBpIiwid2lkZ2V0Il0sImFwaSI6dHJ1ZSwiaWF0IjoxNjM3Mzk2OTY5fQ.xBUm3jw4o2jscyNmQSHVGqTOy3-LVqRBdJ80ownSA1U",
					"refid": "",
					"brand": 0
				}
				print("Mintgate Request : ", request)
				response = requests.post('http://mgate.io/api/v2/links/create', headers = headers, json = mintgate_params)
				print("Mintgate Response : ", response.text)
				return response.json()
		return "Either access to db failed or private_link_id not found on DB",400
	else:
		return "Either token id or private link id field is empty in the request",400

if __name__ == '__main__':
	app.run(host='0.0.0.0', port=5000)
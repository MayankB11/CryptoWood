import json
from web3 import Web3, HTTPProvider
from web3.contract import ConciseContract

# web3.py instance
w3 = Web3(HTTPProvider("https://kovan.infura.io/v3/9d52f971bff74213aa012e3882d99c24")) #added from infura/project
print(w3.isConnected())

key='0xd7f3d3c4ee2ed9742acf562b2fb164eb108cb610a72b001752859875b2c60229' #added from metamask (acc1)
acct = w3.eth.account.privateKeyToAccount(key)

# compile your smart contract with truffle first
chainLinkContract = json.load(open('./build/contracts/APIChainlink.json'))
abiCL = chainLinkContract['abi']
bytecodeCL = chainLinkContract['bytecode']
contractCL = w3.eth.contract(bytecode=bytecodeCL, abi=abiCL)

contentTokenContract = json.load(open('./build/contracts/ContentToken.json'))
abiCT = contentTokenContract['abi']
bytecodeCT = contentTokenContract['bytecode']
contractCT = w3.eth.contract(bytecode=bytecodeCT, abi=abiCT)

marketPlaceContract = json.load(open('./build/contracts/MarketPlace.json'))
abiMKT = marketPlaceContract['abi']
bytecodeMKT = marketPlaceContract['bytecode']
contractMKT= w3.eth.contract(bytecode=bytecodeMKT, abi=abiMKT)

#building transaction
construct_txn_MKT = contractMKT.constructor(acct.address).buildTransaction({
    'from': acct.address,
    'nonce': w3.eth.getTransactionCount(acct.address),
    'gas': 5728712,
    'gasPrice': w3.toWei('20', 'gwei')})
signed = acct.signTransaction(construct_txn_MKT)
tx_hash = w3.eth.sendRawTransaction(signed.rawTransaction)
print(tx_hash.hex())
tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
print("Contract MarketPlace Deployed At:", tx_receipt['contractAddress'])
address_contract_MKT = tx_receipt['contractAddress']

construct_txn_CL = contractCL.constructor().buildTransaction({
    'from': acct.address,
    'nonce': w3.eth.getTransactionCount(acct.address),
    'gas': 5728712,
    'gasPrice': w3.toWei('20', 'gwei')})
signed = acct.signTransaction(construct_txn_CL)
tx_hash = w3.eth.sendRawTransaction(signed.rawTransaction)
print(tx_hash.hex())
tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
print("Contract Chain Link Deployed At:", tx_receipt['contractAddress'])
address_contract_CL = tx_receipt['contractAddress']

construct_txn_CT = contractCT.constructor(acct.address, address_contract_MKT, address_contract_CL).buildTransaction({
    'from': acct.address,
    'nonce': w3.eth.getTransactionCount(acct.address),
    'gas': 5728712,
    'gasPrice': w3.toWei('20', 'gwei')})
signed = acct.signTransaction(construct_txn_CT)
tx_hash = w3.eth.sendRawTransaction(signed.rawTransaction)
print(tx_hash.hex())
tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
print("Contract Content Token Deployed At:", tx_receipt['contractAddress'])

address_contract_CT = tx_receipt['contractAddress']

# now create a transaction to set content token address to chain link contract
# by calling the setContractAddress(_address) function

import json
from web3 import Web3, HTTPProvider
from web3.contract import ConciseContract

# web3.py instance
w3 = Web3(HTTPProvider("https://ropsten.infura.io/v3/9d52f971bff74213aa012e3882d99c24")) #added from infura/project
print(w3.isConnected())

key='0xd7f3d3c4ee2ed9742acf562b2fb164eb108cb610a72b001752859875b2c60229' #added from metamask (acc1)
acct = w3.eth.account.privateKeyToAccount(key)

# compile your smart contract with truffle first
truffleFile = json.load(open('./build/contracts/ContentToken.json'))
abi = truffleFile['abi']
bytecode = truffleFile['bytecode']
contract= w3.eth.contract(bytecode=bytecode, abi=abi)

mkt = '0x5fD36D7B7b529B808BC5D1a16B4C5368b888A330'

#building transaction
construct_txn = contract.constructor(acct.address, mkt).buildTransaction({
    'from': acct.address,
    'nonce': w3.eth.getTransactionCount(acct.address),
    'gas': 1728712,
    'gasPrice': w3.toWei('20', 'gwei')})


signed = acct.signTransaction(construct_txn)

tx_hash=w3.eth.sendRawTransaction(signed.rawTransaction)
print(tx_hash.hex())
tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
print("Contract Deployed At:", tx_receipt['contractAddress'])
const fs = require('fs');
//const { MAINNET_CHAIN_ID, TESTNET_CHAIN_ID } = require('../deployment-config');
async function deploy() {
    // set contrat file full path:
    const contractsFile = __dirname + "/../contracts.json";
    const [deployer] = await hre.ethers.getSigners();
    // check deployer balance
    const balance = await deployer.getBalance();
    const balanceInEth = ethers.utils.formatEther(balance);
    console.log(
        "Deploying contracts with the account:",
        deployer.address,
        "balance:",
        balanceInEth.toString()
    );
    if (balance.lt(ethers.utils.parseEther("1"))) {
        throw new Error("balance is too low");
    }
    const network = await hre.ethers.provider.getNetwork();
    const chainId = network.chainId;
    const BulkSender = await hre.ethers.getContractFactory("BulkSender");
    const main = await BulkSender.deploy();
    await main.deployed();
    console.log(`BulkSender deployed network ${chainId} address: ${main.address}`);
    if (!fs.existsSync(contractsFile))
        fs.writeFileSync(contractsFile, JSON.stringify({}, null, 4));
    let contracts = JSON.parse(fs.readFileSync(contractsFile));
    if( ! contracts ) contracts = {};
    if( ! contracts[chainId] ) contracts[chainId] = {};
    contracts[chainId]['BulkSender'] = main.address;
    fs.writeFileSync(contractsFile, JSON.stringify(contracts, null, 4));
    try {
        //if (chainId === MAINNET_CHAIN_ID || chainId === TESTNET_CHAIN_ID) {
            console.log(`verify BulkSender on network ${chainId} address: ${main.address}`);
            await main.deployTransaction.wait(5);
            await hre.run("verify:verify",
                {
                    address: main.address
                }
            );
        //}
    } catch (e) {
        console.log(e);
    }

}
async function main() {
    await deploy();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });


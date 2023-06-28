const fs = require('fs');
const { MAINNET_CHAIN_ID, TESTNET_CHAIN_ID } = require('../deployment-config');
async function deploy(name:string, symbol:string, decimals:string, mintAmountInDecimals:string) {
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
    const MockERC20 = await hre.ethers.getContractFactory("MockERC20");
    const main = await MockERC20.deploy(name, symbol, decimals);
    await main.deployed();
    console.log(`${symbol} deployed network ${chainId} address: ${main.address}`);
    if (!fs.existsSync(contractsFile))
        fs.writeFileSync(contractsFile, JSON.stringify({}, null, 4));
    let contracts = JSON.parse(fs.readFileSync(contractsFile));
    if( ! contracts ) contracts = {};
    if( ! contracts[chainId] ) contracts[chainId] = {};
    contracts[chainId][symbol] = main.address;
    fs.writeFileSync(contractsFile, JSON.stringify(contracts, null, 4));
    if( mintAmountInDecimals ){
        const amountInWei = ethers.utils.parseUnits(mintAmountInDecimals, decimals);
        console.log(`minting ${mintAmountInDecimals} to ${deployer.address}`);
        const tx = await main.mint(deployer.address, amountInWei);
        await tx.wait();
    }
    try {
        if (chainId === MAINNET_CHAIN_ID || chainId === TESTNET_CHAIN_ID) {
            console.log(`verify ${symbol} on network ${chainId} address: ${main.address}`);
            await main.deployTransaction.wait(5);
            await hre.run("verify:verify",
                {
                    address: main.address,
                    constructorArguments: [name, symbol, decimals]
                }
            );
        }
    } catch (e) {
        console.log(e);
    }

}
async function main() {
    const network = await hre.ethers.provider.getNetwork();
    if (network.chainId === MAINNET_CHAIN_ID ) {
        new Error("mainnet not allowed");
        return;
    }
    await deploy("Mock USDC", "USDC", "6", "100000000");
    await deploy("Mock USDT", "USDT", "6", "100000000");
    await deploy("Mock WBTC", "WBTC", "8", "100000000");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });


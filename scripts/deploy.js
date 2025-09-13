const hre = require("hardhat");
const setup = require("./setup");

/**
 * @typedef {Object} ContractInterface
 * @property {string} contract
 * @property {Array<any>} contractArgs
 *
 */

async function main() {
    if (!(process.argv?.length >= 3)) {
        throw new Error("Insufficient Arguments");
    }

    const [prefEnv, contractName] = process.argv.slice(2)
    if (!contractName) {
        throw new Error("Please provide a contract name to deploy");
    }
    const currSetup = setup[prefEnv];

    const [signer] = await hre.ethers.getSigners();

    const minterFactory = await hre.ethers.getContractFactory(contractName);


    const documentContract = await minterFactory.deploy(...currSetup[contractName].args);
    await documentContract.waitForDeployment();
    const documentContractAddress = await documentContract.getAddress();
    console.log(
        `Contract deployed to: ${documentContractAddress}`,
        currSetup.network
    );

    const verify = new Promise((resolve, reject) => {
        setTimeout(async () => {
            try {
                const verified = await hre.run("verify:verify", {
                    address: documentContractAddress,
                    constructorArguments: currSetup[contractName].args,
                    network: currSetup.network
                });
                console.log(`Contract Verification: ${verified}`);
                resolve();
            } catch (err) {
                reject(err);
            }
        }, 5000)
    })
    await verify;


}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
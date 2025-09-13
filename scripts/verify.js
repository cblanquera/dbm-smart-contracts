const hre = require("hardhat");
const setup = require("./setup");

async function main() {
  if (process.argv.length < 4) {
    throw new Error("Usage: node scripts/verify.js <env> <contractName>");
  }

  const [env, contractName] = process.argv.slice(2);
  const currSetup = setup[env];

  if (!currSetup || !currSetup[contractName]) {
    throw new Error(`Invalid environment or contract name: ${env}, ${contractName}`);
  }

  const network = currSetup.network;
  const constructorArguments = currSetup[contractName].args;

  const contractAddress = currSetup[contractName].deployedAddress;
  if (!contractAddress) {
    throw new Error(`Missing deployedAddress in setup.js for ${contractName} on ${env}`);
  }

  console.log(`Verifying ${contractName} at ${contractAddress} on ${network}...`);

  try {
    await hre.run("verify:verify", {
      address: contractAddress,
      constructorArguments,
    });

    console.log(`✅ Contract verified successfully: ${contractAddress}`);
  } catch (err) {
    console.error("❌ Verification failed:", err.message);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

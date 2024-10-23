import {
  Account,
  Aptos,
  AptosConfig,
  Ed25519PrivateKey,
  Network,
} from "@aptos-labs/ts-sdk";

async function mintToken(aptos: Aptos, to: string) {
  // TODO: Add Contract Wallet Private Key, used during contract deployment
  const pk = "{{PRIVATE_KEY}}";

  const privateKey = new Ed25519PrivateKey(pk);
  const wallet = Account.fromPrivateKey({ privateKey });

  const txn = await aptos.transaction.build.simple({
    sender: wallet.accountAddress,
    data: {
      function:
        "0xc900cff263488493c8b442a4ceb42c947f690230324f40047f644c8ab81d50e9::custom_token::airdrop_and_register",
      //   typeArguments: [APTOS_COIN],
      functionArguments: [to, 100_000_000_000_000],
    },
  });

  const committedTxn = await aptos.signAndSubmitTransaction({
    signer: wallet,
    transaction: txn,
  });

  const res = await aptos.waitForTransaction({
    transactionHash: committedTxn.hash,
  });
  return res.success;
}

const config = new AptosConfig({ network: Network.MAINNET });
const aptos = new Aptos(config);

// TODO: Add CENTRAL_WALLET_ADDRESS (Treasury Wallet Public Address)
mintToken(aptos, "{{CENTRAL_WALLET_ADDRESS}}");

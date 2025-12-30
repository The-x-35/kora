import { KoraClient } from "@solana/kora";
import { createSolanaRpc } from "@solana/kit";
import { createKeyPairSignerFromBytes, getBase58Encoder, address } from "@solana/kit";
import { findAssociatedTokenPda, TOKEN_PROGRAM_ADDRESS } from "@solana-program/token";
import dotenv from "dotenv";
import path from "path";

dotenv.config({ path: path.join(process.cwd(), "..", ".env") });

const USDC_MINT = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"; // USDC on mainnet
const USDC_DECIMALS = 6;

async function getEnvKeyPair(envKey: string) {
  if (!process.env[envKey]) {
    throw new Error(`Environment variable ${envKey} is not set`);
  }
  const base58Encoder = getBase58Encoder();
  const b58SecretEncoded = base58Encoder.encode(process.env[envKey]!);
  return await createKeyPairSignerFromBytes(b58SecretEncoded);
}

async function main() {
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("Checking Account Requirements for Full Demo");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("");

  const solanaRpcUrl = process.env.SOLANA_RPC_URL || process.env.RPC_URL;
  if (!solanaRpcUrl) {
    throw new Error("SOLANA_RPC_URL or RPC_URL environment variable must be set");
  }
  const rpc = createSolanaRpc(solanaRpcUrl);

  const testSender = await getEnvKeyPair("TEST_SENDER_KEYPAIR");
  const destination = await getEnvKeyPair("DESTINATION_KEYPAIR");

  console.log("Account Addresses:");
  console.log(`  Sender: ${testSender.address}`);
  console.log(`  Destination: ${destination.address}`);
  console.log("");

  // Check SOL balances
  console.log("Checking SOL balances...");
  const senderSolBalance = await rpc.getBalance(address(testSender.address)).send();
  const destSolBalance = await rpc.getBalance(address(destination.address)).send();

  console.log(`  Sender SOL: ${(Number(senderSolBalance.value) / 1e9).toFixed(4)} SOL`);
  console.log(`  Destination SOL: ${(Number(destSolBalance.value) / 1e9).toFixed(4)} SOL`);
  console.log("");

  // Check USDC balances
  console.log("Checking USDC balances...");
  const [senderAta] = await findAssociatedTokenPda({
    mint: address(USDC_MINT),
    owner: address(testSender.address),
    tokenProgram: TOKEN_PROGRAM_ADDRESS,
  });

  const [destAta] = await findAssociatedTokenPda({
    mint: address(USDC_MINT),
    owner: address(destination.address),
    tokenProgram: TOKEN_PROGRAM_ADDRESS,
  });

  // Helper function to extract token balance from account data
  function getTokenBalance(data: Uint8Array): bigint {
    // Token account balance is at offset 64, 8 bytes (u64, little-endian)
    const balanceBytes = data.slice(64, 72);
    // Convert little-endian bytes to BigInt
    let balance = 0n;
    for (let i = 0; i < balanceBytes.length; i++) {
      balance += BigInt(balanceBytes[i]) << BigInt(i * 8);
    }
    return balance;
  }

  // Helper to convert account data to Uint8Array
  function getAccountDataBytes(data: string | Uint8Array): Uint8Array {
    if (typeof data === 'string') {
      // Decode base64 string to bytes using Buffer (Node.js)
      return new Uint8Array(Buffer.from(data, 'base64'));
    }
    // Already a Uint8Array
    return new Uint8Array(data);
  }

  try {
    const senderTokenAccount = await rpc.getAccountInfo(address(senderAta)).send();
    if (senderTokenAccount.value) {
      const data = senderTokenAccount.value.data;
      const accountData = getAccountDataBytes(data);
      const balance = getTokenBalance(accountData);
      console.log(`  Sender USDC: ${(Number(balance) / 10 ** USDC_DECIMALS).toFixed(2)} USDC`);
    } else {
      console.log(`  Sender USDC: Account not found (needs to be created)`);
    }
  } catch (e) {
    console.log(`  Sender USDC: Error checking balance`);
  }

  try {
    const destTokenAccount = await rpc.getAccountInfo(address(destAta)).send();
    if (destTokenAccount.value) {
      const data = destTokenAccount.value.data;
      const accountData = getAccountDataBytes(data);
      const balance = getTokenBalance(accountData);
      console.log(`  Destination USDC: ${(Number(balance) / 10 ** USDC_DECIMALS).toFixed(2)} USDC`);
    } else {
      console.log(`  Destination USDC: Account not found (will be created)`);
    }
  } catch (e) {
    console.log(`  Destination USDC: Error checking balance`);
  }

  console.log("");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("Full Demo Transfer Requirements:");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("");
  console.log("The full-demo will transfer:");
  console.log("  1. 0.1 USDC (100,000 with 6 decimals)");
  console.log("     From: Sender → Destination");
  console.log("  2. Payment to Kora (in USDC)");
  console.log("     Amount: ~0.01-0.05 USDC (estimated fee)");
  console.log("     From: Sender → Kora fee payer");
  console.log("");
  console.log("Note: SOL transfer has been removed from the demo.");
  console.log("      Transaction fees are paid by Kora (in SOL).");
  console.log("      You only pay Kora back in USDC.");
  console.log("");
  console.log("Total Required in Sender Account:");
  console.log(`  - USDC: ~0.15 USDC (0.1 for transfer + ~0.05 for Kora fee)`);
  console.log(`  - SOL: None needed (Kora pays transaction fees)`);
  console.log("");
  console.log("Note: Kora will pay the transaction fees in SOL, but you pay");
  console.log("      Kora back in USDC for the gasless transaction service.");
  console.log("");

  // Check if requirements are met
  const requiredUSDC = 0.15;
  const requiredSOL = 0.01;
  
  try {
    const senderTokenAccount = await rpc.getAccountInfo(address(senderAta)).send();
    if (senderTokenAccount.value) {
      const data = senderTokenAccount.value.data;
      const accountData = getAccountDataBytes(data);
      const balance = getTokenBalance(accountData);
      const usdcBalance = Number(balance) / 10 ** USDC_DECIMALS;
      const solBalance = Number(senderSolBalance.value) / 1e9;

      console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      if (usdcBalance >= requiredUSDC && solBalance >= requiredSOL) {
        console.log("✅ Requirements Met! You can run the full-demo.");
      } else {
        console.log("⚠️  Requirements NOT Met:");
        if (usdcBalance < requiredUSDC) {
          console.log(`   ❌ Need ${requiredUSDC.toFixed(2)} USDC, have ${usdcBalance.toFixed(2)} USDC`);
        }
        if (solBalance < requiredSOL) {
          console.log(`   ❌ Need ${requiredSOL.toFixed(4)} SOL, have ${solBalance.toFixed(4)} SOL`);
        }
      }
      console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    } else {
      console.log("⚠️  Sender USDC account doesn't exist. You need to:");
      console.log("   1. Create a USDC token account for the sender");
      console.log("   2. Transfer at least 0.15 USDC to it");
    }
  } catch (e) {
    console.log("⚠️  Could not verify USDC balance. Make sure sender has USDC.");
  }
}

main().catch(e => console.error("Error:", e));


### **Project Specification: Motoko SUI Wallet Canister**

**Version:** 1.0
**Date:** October 23, 2025

#### **1. Project Goal & Overview**

The objective of this project is to create a non-custodial SUI wallet as a canister on the Internet Computer. This "Wallet Canister" will abstract away all the complexities of interacting with the SUI blockchain. It will expose a simple, high-level API for other canisters or AI agents to perform common wallet operations like checking balances and transferring SUI tokens.

The canister will manage its identity via a separate, pre-existing "Signing Canister" and will communicate with the SUI network via HTTP outcalls. The core technical challenge is the implementation of a Motoko library for SUI's Binary Canonical Serialization (BCS), using the provided official TypeScript library as a definitive reference.

#### **2. Core Architecture**

The system consists of four main components:

1.  **Calling Agent/Canister:** The end-user of the service. It makes simple, high-level calls to the Wallet Canister.
2.  **Wallet Canister (This Project):** The "brain" of the operation. It exposes the public API, contains the SUI transaction-building logic, the new BCS library, and orchestrates calls to the other components.
3.  **Signing Canister (Existing):** A secure, minimal canister that holds the agent's identity. Its sole purpose is to sign 32-byte hashes when requested by the Wallet Canister.
4.  **SUI RPC Node (External):** A public, external service (e.g., `https://fullnode.testnet.sui.io:443`) that the Wallet Canister communicates with via HTTP outcalls.

**Flow Diagram:**
```
+-----------------+      (Inter-Canister Call)      +-----------------+
|  Calling Agent  | ------------------------------> |  Wallet Canister|
+-----------------+      (e.g., wallet_transfer)    +-----------------+
                                                               |      ^
                               (Inter-Canister Call)             |      | (HTTP Outcall)
                                     | sign(hash)                |      |
                                     v                           v      |
                             +-----------------+             +-------------+
                             | Signing Canister|             | SUI RPC Node|
                             +-----------------+             +-------------+
```

#### **3. Canister Interface Definition (Candid)**

The Wallet Canister MUST expose the following public methods:

```candid
service : {
  // Returns the canister's own SUI address.
  "wallet_get_address": () -> (text) query;

  // Returns the SUI balance in MIST (1 SUI = 1,000,000,000 MIST).
  // Returns an error if the RPC call fails.
  "wallet_get_balance": () -> (variant { Ok: nat; Err: text });

  // Transfers SUI to a destination address.
  // On success, returns the SUI transaction digest.
  // On failure, returns a descriptive error.
  "wallet_transfer": (record { to_address: text; amount: nat }) -> (variant { Ok: text; Err: text });
}
```

#### **4. Core Logic & Implementation Details**

##### **4.1. BCS Serialization Library (Primary Deliverable)**

The developer will create a new Motoko library for SUI's BCS.
*   **Reference:** The provided TypeScript BCS library (`bcs.ts`) is the ground truth. The Motoko implementation's output MUST be byte-for-byte identical to the TypeScript version for the same inputs.
*   **Structure:** The library should be modular, with clear separation for primitive types (`u8`, `bool`, `string`), composite types (`vector`, `struct`, `enum`, `option`), and a core `Writer` class for buffer manipulation.
*   **Key Feature:** The library must include a robust implementation for `uleb128` encoding, as this is critical for variable-length data.

##### **4.2. `wallet_transfer` Function Logic**

This is the most complex workflow and must be implemented in the following sequence:

1.  **Input Validation:** Validate the `to_address` format and ensure `amount` is greater than zero.
2.  **Get Self Address:** Call the Signing Canister to get its public key, then use the SUI Motoko library's `publicKeyToAddress` function to derive its own SUI address.
3.  **Get Gas Coins:** Perform an HTTP outcall to the SUI RPC node (`sui_getCoins`) to fetch a list of coin objects owned by the canister. Select a suitable coin to cover the `amount` and transaction fees.
4.  **Construct Transaction Intent:** Use the existing high-level SUI Motoko library (`mo:sui`) to create a `TransactionData` record for the transfer.
5.  **Serialize Transaction:** Use the **new BCS library** to serialize the `TransactionData` record into a `[Nat8]` byte array (`tx_bytes`).
6.  **Hash Payload:** Create a 32-byte SHA-256 hash of `tx_bytes`.
7.  **Sign Hash:** Make an inter-canister call to the `Signing Canister`'s `sign` method with the hash to get the signature.
8.  **Broadcast Transaction:** Make a final HTTP outcall to the SUI RPC node using the `sui_executeTransactionBlock` method.
    *   The request body MUST contain the base64-encoded `tx_bytes` and the `signature`.
    *   The request MUST use the `WaitForEffectsCert` option to ensure the canister waits for transaction finality.
9.  **Handle Response:** Parse the RPC response. If successful, extract and return the transaction digest. If failed, return a descriptive error message.

#### **5. Dependencies**

*   **Motoko SUI Library (`mo:sui`):** For high-level type definitions (`TransactionData`, etc.).
*   **Motoko BCS Library:** The new library to be built as part of this project.
*   **Signing Canister Principal ID:** The canister ID of the secure signing service (to be provided).
*   **SUI RPC Node URL:** A configurable URL for the SUI Testnet/Mainnet.

#### **6. Testing & Acceptance Criteria**

The project will not be considered complete until the following criteria are met:

1.  **BCS Library Unit Tests:**
    *   A comprehensive test suite for the BCS library.
    *   **Crucially, these tests must be comparative.** For a variety of data structures (from simple integers to complex, nested structs), the Motoko test must assert that `bcs_motoko.serialize(data)` produces the *exact same byte array* as `bcs_typescript.serialize(data)`.

2.  **Integration Tests:**
    *   Tests confirming the Wallet Canister can successfully make inter-canister calls to the Signing Canister.
    *   Tests confirming the Wallet Canister can successfully make HTTP outcalls and parse responses from the SUI RPC node.

3.  **End-to-End (E2E) Tests on SUI Testnet:**
    *   `wallet_get_address` returns a valid SUI address.
    *   `wallet_get_balance` returns an accurate balance.
    *   `wallet_transfer` successfully executes a transaction. The test must:
        a. Call `wallet_transfer`.
        b. Receive a successful transaction digest.
        c. **Verify on-chain:** Call `wallet_get_balance` again and confirm the balance has decreased by the expected amount.

#### **7. Deliverables**

1.  The complete, well-documented Motoko source code for the **BCS Serialization Library**.
2.  The complete, well-documented Motoko source code for the **Wallet Canister**.
3.  A comprehensive test suite (`mops test`) covering all acceptance criteria.
4.  A `README.md` file with clear instructions on how to deploy, configure (e.g., set the Signing Canister ID), and interact with the canister.
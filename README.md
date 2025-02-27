# Beacon Shared Wallet

A shared wallet system built on AO for beacon.


## Table of Contents
- [Usage](#usage)
- [Parent Handlers](#parent-handlers)
  - [CreateWallet](#createwallet)
- [Child Handlers](#child-handlers)
  - [Deploy](#deploy)
  - [ProposeTransaction](#proposetransaction)
  - [ApproveTransaction](#approvetransaction)
  - [Token Deposit](#tokendeposit)
  - [Token Withdraw](#tokenwithdraw)

## Usage

To deploy a shared wallet, you have two options:

1. **Call CreateWallet**: You can deploy a shared wallet by calling the [CreateWallet](#createwallet) handler on the process `cOl4yQx_oLBq1c2ZgXcFm9XI2-KT8xlSYzi1IaW5gCQ`.

2. **Load child.lua**: Alternatively, you can deploy your own process by using the `.load child.lua` command.

    ```sh
    .load child.lua
    ```

## Parent Handlers

The `parent.lua` process is responsible for spawning Shared Wallets (`child.lua`).

### CreateWallet

The `CreateWallet` process initializes a new shared wallet.

- **Tags:**
  - `WalletName`: The name of the wallet.
  - `Participants`: A JSON stringified list of participants.
  - `Threshold`: The number of approvals required for a transaction.

- **Example:**
    ```lua
    ao.send({
        Target = "processId",
        Tags = {
            Action = "CreateWallet",
            WalletName = "My Wallet",
            Participants = '["user1", "user2"]',
            Threshold = 2
        }
    })
    ```

## Child Handlers

The `child.lua` process is the shared wallet. It is responsbile for tracking funds and handling multi-signature transactions.

### Deploy

The `Deploy` process initializes the wallet with the provided name, threshold, and participants. This function is called only once.

- **Tags:**
- `WalletName`: The name of the wallet.
- `Participants`: A JSON stringified list of participants.
- `Threshold`: The number of approvals required for a transaction.

- **Example:**
```lua
ao.send({
    Target = "processId",
    Tags = {
        Action = "Deploy",
        WalletName = "My Wallet",
        Participants = '["user1", "user2"]',
        Threshold = 2
    }
})
```

### ProposeTransaction

The `ProposeTransaction` process allows participants to propose a new transaction.

- **Tags:**
  - `To`: The recipient of the transaction.
  - `Amount`: The amount to be transferred.
  - `TokenId`: The process ID of the token.

- **Example:**
    ```lua
    ao.send({
        Target = "processId",
        Tags = {
            Action = "ProposeTransaction",
            To = "recipient",
            Amount = 100,
            TokenId = "token123"
        }
    })
    ```

### ApproveTransaction

The `ApproveTransaction` process allows participants to approve or refuse a proposed transaction.

- **Tags:**
- `TxId`: The unique identifier of the transaction that needs approval.
- `Approved`: A boolean value indicating whether the transaction is approved (`true`) or declined (`false`).

- **Example:**
    ```lua
    ao.send({
        Target = "processId",
        Tags = {
            Action = "ApproveTransaction",
            TxId = "tx123",
            Approved = true
        },
        Data = "Approve the transaction."
    })
    ```

### tokenDeposit 

Resposible for handling token deposits to the wallet. Will add to the `tokens` table accordingly.

### tokenWithdraw

Responsible for handling token withdrawals from the wallet. Will subtract from the `tokens` table accordingly.
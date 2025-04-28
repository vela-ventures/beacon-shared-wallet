---@diagnostic disable: duplicate-set-field
require("spec.setup")()

_G.IsInUnitTest = true -- Prevent `ao.send()` from doing anything
_G.VerboseTests = 2    -- Set verbosity level for logging

-- Optional logging function for debugging
_G.printVerb = function(level)
    level = level or 2
    return function(...)
        if _G.VerboseTests >= level then print(table.unpack({ ... })) end
    end
end

-- Mock dependencies
_G.Handlers = {
    prepend = function() end,
    add = function(name, action, handler)
        _G.RegisteredHandlers = _G.RegisteredHandlers or {}
        _G.RegisteredHandlers[name] = handler
    end,
    utils = {
        hasMatchingTag = function()
            return function() end
        end
    }
}

local json = require("json")
local child = require("beacon-shared-wallet.child")

local resetGlobals = function()
    _G.WalletName = "Smart Account"
    _G.Participants = {}
    _G.Threshold = 2
    _G.Transactions = {}
    _G.Tokens = {}
    _G.Deployer = "Unknown"
end

describe("child.lua", function()
    before_each(function()
        resetGlobals()
    end)

    describe("state handler", function()
        it("should return the current state", function()
            -- Mock message
            local mockMsg = {
                reply = function() end
            }

            spy.on(mockMsg, "reply")

            -- Simulate the state handler being registered
            local stateHandler = _G.RegisteredHandlers["state"]

            -- Call the state handler
            stateHandler(mockMsg)

            -- Assertions
            assert.spy(mockMsg.reply).was_called_with({
                Response = json.encode({
                    Participants = _G.Participants,
                    Threshold = _G.Threshold,
                    Tokens = _G.Tokens,
                    Name = _G.WalletName
                })
            })
        end)
    end)

    describe("transactions handler", function()
        it("should return the current transactions", function()
            -- Mock message
            local mockMsg = {
                reply = function() end
            }

            spy.on(mockMsg, "reply")

            -- Simulate the transactions handler being registered
            local transactionsHandler = _G.RegisteredHandlers["transactions"]

            -- Add some transactions to test
            _G.Transactions = {
                { id = "tx1", amount = 100 },
                { id = "tx2", amount = 200 }
            }

            -- Call the transactions handler
            transactionsHandler(mockMsg)

            -- Assertions
            assert.spy(mockMsg.reply).was_called_with({
                Response = json.encode({
                    Transactions = _G.Transactions
                })
            })
        end)

        it("should handle an empty transactions list", function()
            -- Mock message
            local mockMsg = {
                reply = function() end
            }

            spy.on(mockMsg, "reply")

            -- Simulate the transactions handler being registered
            local transactionsHandler = _G.RegisteredHandlers["transactions"]

            -- Ensure Transactions is empty
            _G.Transactions = {}

            -- Call the transactions handler
            transactionsHandler(mockMsg)

            -- Assertions
            assert.spy(mockMsg.reply).was_called_with({
                Response = json.encode({
                    Transactions = {}
                })
            })
        end)
    end)

    describe("tokens handler", function()
        it("should return the current tokens", function()
            -- Mock message
            local mockMsg = {
                reply = function() end
            }

            spy.on(mockMsg, "reply")

            -- Simulate the tokens handler being registered
            local tokensHandler = _G.RegisteredHandlers["tokens"]

            -- Add some tokens to test
            _G.Tokens = {
                token1 = 1000,
                token2 = 2000
            }

            -- Call the tokens handler
            tokensHandler(mockMsg)

            -- Assertions
            assert.spy(mockMsg.reply).was_called_with({
                Response = json.encode({
                    Tokens = _G.Tokens
                })
            })
        end)
    end)

    describe("proposeTx handler", function()
        it("should propose a transaction when all inputs are valid", function()
            -- Mock message
            local mockMsg = {
                From = "User1",
                Tags = {
                    To = "Recipient1",
                    Amount = "100",
                    TokenId = "Token1"
                },
                Id = "tx1",
                reply = function() end
            }

            spy.on(mockMsg, "reply")

            -- Add User1 to Participants
            _G.Participants = { "User1" }

            -- Simulate the proposeTx handler being registered
            local proposeTxHandler = _G.RegisteredHandlers["proposeTx"]

            -- Call the proposeTx handler
            proposeTxHandler(mockMsg)

            -- Assertions
            assert.are.equal(#_G.Transactions, 1) -- Ensure a transaction was added
            assert.are.same(_G.Transactions[1], {
                id = "tx1",
                target = "Recipient1",
                tokenId = "Token1",
                amount = "100",
                approvals = { "User1" },
                refusals = {},
                status = "Proposed",
                createdAt = _G.Transactions[1].createdAt -- Ignore dynamic timestamp
            })
            assert.spy(mockMsg.reply).was_called_with({ Data = "Transaction Proposed." })
        end)

        it("should reject if the user is not a participant", function()
            -- Mock message
            local mockMsg = {
                From = "NonParticipant",
                Tags = {
                    To = "Recipient1",
                    Amount = "100",
                    TokenId = "Token1"
                },
                Id = "tx1",
                reply = function() end
            }

            spy.on(mockMsg, "reply")

            -- Ensure Participants does not include NonParticipant
            _G.Participants = { "User1" }

            -- Simulate the proposeTx handler being registered
            local proposeTxHandler = _G.RegisteredHandlers["proposeTx"]

            -- Call the proposeTx handler
            proposeTxHandler(mockMsg)

            -- Assertions
            assert.are.equal(#_G.Transactions, 0) -- Ensure no transaction was added
            assert.spy(mockMsg.reply).was_called_with({ Data = "Only participants can propose transactions" })
        end)

        it("should reject if 'To' is missing", function()
            -- Mock message
            local mockMsg = {
                From = "User1",
                Tags = {
                    Amount = "100",
                    TokenId = "Token1"
                },
                Id = "tx1",
                reply = function() end
            }

            spy.on(mockMsg, "reply")

            -- Add User1 to Participants
            _G.Participants = { "User1" }

            -- Simulate the proposeTx handler being registered
            local proposeTxHandler = _G.RegisteredHandlers["proposeTx"]

            -- Call the proposeTx handler
            proposeTxHandler(mockMsg)

            -- Assertions
            assert.are.equal(#_G.Transactions, 0) -- Ensure no transaction was added
            assert.spy(mockMsg.reply).was_called_with({ Data = "To is required" })
        end)

        it("should reject if 'Amount' is missing", function()
            -- Mock message
            local mockMsg = {
                From = "User1",
                Tags = {
                    To = "Recipient1",
                    TokenId = "Token1"
                },
                Id = "tx1",
                reply = function() end
            }

            spy.on(mockMsg, "reply")

            -- Add User1 to Participants
            _G.Participants = { "User1" }

            -- Simulate the proposeTx handler being registered
            local proposeTxHandler = _G.RegisteredHandlers["proposeTx"]

            -- Call the proposeTx handler
            proposeTxHandler(mockMsg)

            -- Assertions
            assert.are.equal(#_G.Transactions, 0) -- Ensure no transaction was added
            assert.spy(mockMsg.reply).was_called_with({ Data = "Amount is required" })
        end)

        it("should reject if 'TokenId' is missing", function()
            -- Mock message
            local mockMsg = {
                From = "User1",
                Tags = {
                    To = "Recipient1",
                    Amount = "100"
                },
                Id = "tx1",
                reply = function() end
            }

            spy.on(mockMsg, "reply")

            -- Add User1 to Participants
            _G.Participants = { "User1" }

            -- Simulate the proposeTx handler being registered
            local proposeTxHandler = _G.RegisteredHandlers["proposeTx"]

            -- Call the proposeTx handler
            proposeTxHandler(mockMsg)

            -- Assertions
            assert.are.equal(#_G.Transactions, 0) -- Ensure no transaction was added
            assert.spy(mockMsg.reply).was_called_with({ Data = "TokenId is required" })
        end)
    end)

    describe("approveTx handler", function()
        it("should approve a transaction when all inputs are valid", function()
            -- Mock message
            local mockMsg = {
                From = "User1",
                Tags = {
                    TxId = "tx1",
                    Approved = true
                },
                reply = function() end
            }
    
            spy.on(mockMsg, "reply")
    
            -- Add User1 to Participants
            _G.Participants = { "User1" }
    
            -- Add a transaction to test
            _G.Transactions = {
                {
                    id = "tx1",
                    target = "Recipient1",
                    tokenId = "Token1",
                    amount = "100",
                    approvals = {},
                    refusals = {},
                    status = "Proposed"
                }
            }
    
            -- Simulate the approveTx handler being registered
            local approveTxHandler = _G.RegisteredHandlers["approveTx"]
    
            -- Call the approveTx handler
            approveTxHandler(mockMsg)
    
            -- Assertions
            assert.are.same(_G.Transactions[1].approvals, { "User1" }) -- Ensure User1 is added to approvals
            assert.spy(mockMsg.reply).was_called_with({ Data = "Transaction approved" })
        end)
    
        it("should reject if the user is not a participant", function()
            -- Mock message
            local mockMsg = {
                From = "NonParticipant",
                Tags = {
                    TxId = "tx1",
                    Approved = true
                },
                reply = function() end
            }
    
            spy.on(mockMsg, "reply")
    
            -- Ensure Participants does not include NonParticipant
            _G.Participants = { "User1" }
    
            -- Simulate the approveTx handler being registered
            local approveTxHandler = _G.RegisteredHandlers["approveTx"]
    
            -- Call the approveTx handler
            approveTxHandler(mockMsg)
    
            -- Assertions
            assert.spy(mockMsg.reply).was_called_with({ Data = "Only participants can approve transactions" })
        end)
    
        it("should reject if TxId is missing", function()
            -- Mock message
            local mockMsg = {
                From = "User1",
                Tags = {
                    Approved = true
                },
                reply = function() end
            }
    
            spy.on(mockMsg, "reply")
    
            -- Add User1 to Participants
            _G.Participants = { "User1" }
    
            -- Simulate the approveTx handler being registered
            local approveTxHandler = _G.RegisteredHandlers["approveTx"]
    
            -- Call the approveTx handler
            approveTxHandler(mockMsg)
    
            -- Assertions
            assert.spy(mockMsg.reply).was_called_with({ Data = "TxId is required" })
        end)
    
        it("should reject if the transaction is not found", function()
            -- Mock message
            local mockMsg = {
                From = "User1",
                Tags = {
                    TxId = "nonexistent",
                    Approved = true
                },
                reply = function() end
            }
    
            spy.on(mockMsg, "reply")
    
            -- Add User1 to Participants
            _G.Participants = { "User1" }
    
            -- Simulate the approveTx handler being registered
            local approveTxHandler = _G.RegisteredHandlers["approveTx"]
    
            -- Call the approveTx handler
            approveTxHandler(mockMsg)
    
            -- Assertions
            assert.spy(mockMsg.reply).was_called_with({ Data = "Transaction not found" })
        end)
    end)

    describe("getTransaction handler", function()
        it("should return the transaction when TxId is valid", function()
            -- Mock message
            local mockMsg = {
                Tags = {
                    TxId = "tx1"
                },
                reply = function() end
            }
    
            spy.on(mockMsg, "reply")
    
            -- Add a transaction to test
            _G.Transactions = {
                {
                    id = "tx1",
                    target = "Recipient1",
                    tokenId = "Token1",
                    amount = "100",
                    approvals = { "User1" },
                    refusals = {},
                    status = "Proposed",
                    createdAt = os.time()
                }
            }
    
            -- Simulate the getTransaction handler being registered
            local getTransactionHandler = _G.RegisteredHandlers["getTransaction"]
    
            -- Call the getTransaction handler
            getTransactionHandler(mockMsg)
    
            -- Assertions
            assert.spy(mockMsg.reply).was_called_with({
                Data = json.encode(_G.Transactions[1])
            })
        end)
    
        it("should reject if TxId is missing", function()
            -- Mock message
            local mockMsg = {
                Tags = {},
                reply = function() end
            }
    
            spy.on(mockMsg, "reply")
    
            -- Simulate the getTransaction handler being registered
            local getTransactionHandler = _G.RegisteredHandlers["getTransaction"]
    
            -- Call the getTransaction handler
            getTransactionHandler(mockMsg)
    
            -- Assertions
            assert.spy(mockMsg.reply).was_called_with({ Data = "TxId is required" })
        end)
    
        it("should reject if the transaction is not found", function()
            -- Mock message
            local mockMsg = {
                Tags = {
                    TxId = "nonexistent"
                },
                reply = function() end
            }
    
            spy.on(mockMsg, "reply")
    
            -- Simulate the getTransaction handler being registered
            local getTransactionHandler = _G.RegisteredHandlers["getTransaction"]
    
            -- Call the getTransaction handler
            getTransactionHandler(mockMsg)
    
            -- Assertions
            assert.spy(mockMsg.reply).was_called_with({ Data = "Transaction not found" })
        end)
    end)

    describe("tokenDeposit handler", function()
        it("should add a new token if it does not exist", function()
            -- Mock message
            local mockMsg = {
                Tags = {
                    ["From-Process"] = "Token1",
                    Quantity = 1000
                },
                reply = function() end
            }
    
            -- Simulate the tokenDeposit handler being registered
            local tokenDepositHandler = _G.RegisteredHandlers["tokenDeposit"]
    
            -- Call the tokenDeposit handler
            tokenDepositHandler(mockMsg)
    
            -- Assertions
            assert.are.equal(_G.Tokens["Token1"], 1000) -- Ensure the token is added
        end)
    
        it("should update the balance of an existing token", function()
            -- Mock message
            local mockMsg = {
                Tags = {
                    ["From-Process"] = "Token1",
                    Quantity = 500
                },
                reply = function() end
            }
    
            -- Add an existing token
            _G.Tokens = {
                Token1 = 1000
            }
    
            -- Simulate the tokenDeposit handler being registered
            local tokenDepositHandler = _G.RegisteredHandlers["tokenDeposit"]
    
            -- Call the tokenDeposit handler
            tokenDepositHandler(mockMsg)
    
            -- Assertions
            assert.are.equal(_G.Tokens["Token1"], 1500) -- Ensure the token balance is updated
        end)
    end)

    describe("tokenWithdraw handler", function()
        it("should decrease the balance of an existing token", function()
            -- Mock message
            local mockMsg = {
                Tags = {
                    ["From-Process"] = "Token1",
                    Quantity = 500
                },
                reply = function() end
            }
    
            -- Add an existing token
            _G.Tokens = {
                Token1 = 1000
            }
    
            -- Simulate the tokenWithdraw handler being registered
            local tokenWithdrawHandler = _G.RegisteredHandlers["tokenWithdraw"]
    
            -- Call the tokenWithdraw handler
            tokenWithdrawHandler(mockMsg)
    
            -- Assertions
            assert.are.equal(_G.Tokens["Token1"], 500) -- Ensure the token balance is decreased
        end)
    
        it("should handle withdrawing from a token with zero balance", function()
            -- Mock message
            local mockMsg = {
                Tags = {
                    ["From-Process"] = "Token1",
                    Quantity = 500
                },
                reply = function() end
            }
    
            -- Add a token with zero balance
            _G.Tokens = {
                Token1 = 0
            }
    
            -- Simulate the tokenWithdraw handler being registered
            local tokenWithdrawHandler = _G.RegisteredHandlers["tokenWithdraw"]
    
            -- Call the tokenWithdraw handler
            tokenWithdrawHandler(mockMsg)
    
            -- Assertions
            assert.are.equal(_G.Tokens["Token1"], -500) -- Ensure the token balance is decreased into negative
        end)
    end)
end)

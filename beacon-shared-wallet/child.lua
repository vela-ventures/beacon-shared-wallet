local json = require("json")



-- [
-- State Variables
-- ]

WalletName = WalletName or "Smart Account"
Participants = Participants or {}
Threshold = Threshold or 2
Transactions = Transactions or {}
Tokens = Tokens or {}
Deployer = Deployer or "Unknown"





-- [
-- Initialization Function
-- ]

Handlers.prepend("deploy", "Deploy", function(msg)
    print(msg.From .. " Deploying")

    local walletName = msg.Tags.WalletName
    local threshold = msg.Tags.Threshold
    local participantsJson = msg.Tags.Participants

    -- Validate threshold
    local thresholdNumber = tonumber(threshold)
    if not thresholdNumber or thresholdNumber <= 0 then
        msg.reply({ Data = "Invalid threshold value" })
        return
    end

    -- Validate participants JSON
    local participants = json.decode(participantsJson)
    if not participants then
        msg.reply({ Data = "Invalid participants JSON" })
        return
    end

    -- Validate threshold is not more than the number of participants
    if thresholdNumber > #participants then
        msg.reply({ Data = "Threshold cannot be more than the number of participants" })
        return
    end

    WalletName = walletName
    Threshold = thresholdNumber
    Participants = participants
    Deployer = msg.From

    print(msg.From .. " Deployed")
end, 1)





-- [
-- Helper Functions
-- ]

local function contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

local function isParticipant(user)
    for _, participant in ipairs(Participants) do
        if participant == user then
            return true
        end
    end
    return false
end

local function findTransactionById(transactions, txId)
    for _, transaction in ipairs(transactions) do
        if transaction.id == txId then
            return transaction
        end
    end
    return nil
end

local function getTokenInformation(target)
	ao.send({ Target = target, Action = "Info" })
end

Handlers.add(
    "state", "State", function (msg)

    msg.reply({
        Response = json.encode({
            Participants = Participants,
            Threshold = Threshold,
            Tokens = Tokens,
            Name = WalletName
        })
    })
end)

Handlers.add(
    "transactions", "Transactions", function (msg)

    msg.reply({
        Response = json.encode({
            Transactions = Transactions
        })
    })
end)

Handlers.add(
    "tokens", "Tokens", function (msg)

    msg.reply({
        Response = json.encode({
            Tokens = Tokens
        })
    })
end)




-- [
-- Handlers
-- ]

Handlers.add("proposeTx", "Propose-Transaction", function(msg)
    local from = msg.From

    if not isParticipant(from) then
        msg.reply({ Data = "Only participants can propose transactions" })
        return
    end

    local to = msg.Tags.To
    local amount = msg.Tags.Amount
    local tokenId = msg.Tags.TokenId
    local id = msg.Id

    if not to then
        msg.reply({ Data = "To is required" })
        return
    end

    if not amount then
        msg.reply({ Data = "Amount is required" })
        return
    end

    if not tokenId then
        msg.reply({ Data = "TokenId is required" })
        return
    end

    local tx = {
        id = id,
		target = to,
		tokenId = tokenId,
		amount = amount,
        approvals = { from },
        refusals = { },
        status = "Proposed",
        createdAt = os.time()
    }

    table.insert(Transactions, tx)
    msg.reply({ Data = "Transaction Proposed." })
end)

Handlers.add("approveTx", "Approve-Transaction", function(msg)
    local from = msg.From

    if not isParticipant(from) then
        msg.reply({ Data = "Only participants can approve transactions" })
        return
    end

    local txId = msg.Tags.TxId
    local approved = msg.Tags.Approved
    local from = msg.From

    if not txId then
        msg.reply({ Data = "TxId is required" })
        return
    end

    local tx = findTransactionById(Transactions, txId)

    if not tx then
        msg.reply({ Data = "Transaction not found" })
        return
    end

    if not tx.approvals then
        tx.approvals = {}
    end
    
    if contains(tx.approvals, from) then
        msg.reply({ Data = "Already Approved" })
        return
    end
    
    if contains(tx.refusals, from) then
        msg.reply({ Data = "Already Refused" })
        return
    end

    if approved then
        table.insert(tx.approvals, from)
    else
        table.insert(tx.refusals, from)
    end

    local threshold = Threshold
    if not Threshold then
        msg.reply({ Data = "Invalid Threshold value" })
        return
    end
    
    if #tx.approvals >= threshold then
        print(tx.tokenId)

        ao.send({
            Target = tx.tokenId,
            Tags = {
                Action = "Transfer",
                Recipient = tx.target,
                Quantity = tx.amount,
            },
        })

        msg.reply({ Data = "Transaction executed" })
        tx.status = "Executed"

        return
    end

    if #tx.refusals >= threshold then
        msg.reply({ Data = "Transaction refused" })
        tx.status = "Refused"

        return
    end

    msg.reply({ Data = "Transaction approved" })
end)

Handlers.add("getTransaction", "Get-Transaction", function(msg)
    local txId = msg.Tags.TxId

    if not txId then
        msg.reply({ Data = "TxId is required" })
        return
    end

    local tx = findTransactionById(Transactions, txId)

    if not tx then
        msg.reply({ Data = "Transaction not found" })
        return
    end

    msg.reply({ Data = json.encode(tx) })
end)





-- [ 
-- Handle Tokens
-- ]

Handlers.add("tokenDeposit", Handlers.utils.hasMatchingTag("Action", "Credit-Notice"), function(msg)
    local tokenId = msg.Tags["From-Process"]
    local balance = msg.Tags.Quantity

	if not Tokens[tokenId] then
		Tokens[tokenId] = balance
		getTokenInformation(tokenId)
	else
		Tokens[tokenId] = Tokens[tokenId] + msg.Tags.Quantity
	end
end)

Handlers.add("tokenWithdraw", Handlers.utils.hasMatchingTag("Action", "Debit-Notice"), function(msg)
    local tokenId = msg.Tags["From-Process"]
	Tokens[tokenId] = Tokens[tokenId] - msg.Tags.Quantity
end)
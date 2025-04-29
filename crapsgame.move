module LuckyCraps::CrapsGame {

    use sui::object::UID;
    use sui::transfer;
    use sui::tx_context::TxContext;
    use sui::coin::{Coin, split, value, join, from_balance, into_balance, zero};
    use sui::balance::Balance;
    use sui::table::{self, Table};
    use sui::option::{self, Option};
    use std::string::String;
    use std::vector;

    use LuckyCraps::LuckyChipToken::{LuckyChip};

    const VAULT_WALLET: address = @0xcce6383bfe67b855f93e9d7ebb61296061c4cd15f303af884c3e0088a4f75e46;
    const HOUSE_FEE_BPS: u64 = 500; // 5% fee in basis points (bps)

    /// Storage object holding balances of users in CHIP
    struct CrapsBank has key {
        id: UID,
        player_balances: Table<address, Balance<LuckyChip>>,
    }

    /// Initialize Craps Bank
    public entry fun init(ctx: &mut TxContext): CrapsBank {
        CrapsBank {
            id: object::new(ctx),
            player_balances: table::new(ctx),
        }
    }

    /// Player swaps SUI to CHIP
    public entry fun swap_sui_for_chips(
        bank: &mut CrapsBank,
        mut payment: Coin<SUI>,
        player: address,
        ctx: &mut TxContext
    ) {
        let total_payment = value(&payment);

        // 5% fee to vault wallet
        let fee_amount = (total_payment * HOUSE_FEE_BPS) / 10_000;
        let (fee_coin, player_coin) = split(payment, fee_amount, ctx);

        // Send fee to vault wallet
        transfer::public_transfer(fee_coin, VAULT_WALLET);

        // Mint equivalent LuckyChip tokens to player
        let chip_amount = value(&player_coin) * 100_000; // 1 SUI = 100,000 LuckyChips (example rate)
        let chip_balance = into_balance<LuckyChip>(chip_amount);

        // Update player balance
        if (table::contains(&bank.player_balances, &player)) {
            let existing_balance = table::borrow_mut(&mut bank.player_balances, &player);
            *existing_balance = join(*existing_balance, chip_balance);
        } else {
            table::insert(&mut bank.player_balances, player, chip_balance);
        }
    }

    /// Player cashes out LuckyChip for SUI
    public entry fun cash_out(
        bank: &mut CrapsBank,
        mut chip_balance: Balance<LuckyChip>,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let chip_amt = into_balance(chip_balance);
        let sui_amt = chip_amt / 100_000; // inverse rate of mint

        let sui_balance = into_balance<SUI>(sui_amt);
        let sui_coin = from_balance(sui_balance, ctx);

        transfer::public_transfer(sui_coin, recipient);
    }

    /// Admin withdraws fees from Bank (if needed)
    public entry fun withdraw_fees(
        bank: &mut CrapsBank,
        admin: address,
        ctx: &mut TxContext
    ) {
        // For now fees directly sent to VAULT, so no-op
        // Future version could aggregate house profit here
    }
}

/// LuckyChipToken.move

module lucky_game::LuckyChipToken {
    use sui::coin::{Self, Coin};
    use sui::balance;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self, Url};

    /// Vault wallet to collect fees.
    const VAULT_WALLET: address = @0xVAULT_WALLET_ADDRESS;

    /// The LuckyChip token struct.
    public struct LUCKYCHIP has store, copy, drop {}

    /// Holds the treasury cap for minting/burning.
    public struct LuckyChipCap has key {
        id: UID,
        treasury_cap: balance::TreasuryCap<LUCKYCHIP>
    }

    /// Initialize the LuckyChip token.
    public entry fun init(ctx: &mut TxContext) {
        let (treasury_cap, _metadata) = coin::create_currency<LUCKYCHIP>(
            b"Lucky Chips",
            b"LUCKY",
            6u8,
            1_000_000_000_000u64, // 1 trillion chips (adjust if needed)
            Url { bytes: b"" },
            ctx
        );
        let cap = LuckyChipCap { id: object::new(ctx), treasury_cap };
        transfer::public_share_object(cap);
    }

    /// Mint new LuckyChips.
    public entry fun mint(recipient: address, amount: u64, cap: &mut LuckyChipCap, ctx: &mut TxContext) {
        let coins = coin::mint(&mut cap.treasury_cap, amount, ctx);
        transfer::transfer(coins, recipient);
    }

    /// Burn LuckyChips.
    public entry fun burn(coins: Coin<LUCKYCHIP>, cap: &mut LuckyChipCap) {
        coin::burn(coins, &mut cap.treasury_cap);
    }
}

module custom_token::custom_token {
    use std::signer;
    use std::string;
    use std::vector;
    use aptos_framework::coin;
    use aptos_framework::aptos_account;
    use aptos_framework::account;

    struct CustomToken {}

    struct MintCapability has key {
        cap: coin::MintCapability<CustomToken>
    }

    struct BurnCapability has key {
        cap: coin::BurnCapability<CustomToken>
    }

    struct FreezeCapability has key {
        cap: coin::FreezeCapability<CustomToken>
    }

    const E_NOT_INITIALIZED: u64 = 1;
    const E_ALREADY_INITIALIZED: u64 = 2;
    const E_NOT_ADMIN: u64 = 3;
    const E_INVALID_INPUTS: u64 = 4;
    const E_INSUFFICIENT_BALANCE: u64 = 5;

    fun init_module(account: &signer) {
        assert!(!coin::is_coin_initialized<CustomToken>(), E_ALREADY_INITIALIZED);
        assert!(signer::address_of(account) == @custom_token, E_NOT_ADMIN);

        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<CustomToken>(
            account,
            string::utf8(b"CustomToken"),
            string::utf8(b"CTK"),
            6,
            true,
        );

        coin::register<CustomToken>(account);
        let coins = coin::mint(1000000000000, &mint_cap);
        coin::deposit(signer::address_of(account), coins);

        move_to(account, MintCapability { cap: mint_cap });
        move_to(account, BurnCapability { cap: burn_cap });
        move_to(account, FreezeCapability { cap: freeze_cap });
    }

    public entry fun airdrop_and_register(
        admin: &signer,
        recipient: address,
        amount: u64
    ) acquires MintCapability {
        assert!(signer::address_of(admin) == @custom_token, E_NOT_ADMIN);

        if (account::exists_at(recipient)) {
            if (!coin::is_account_registered<CustomToken>(recipient)) {
                aptos_account::transfer_coins<CustomToken>(admin, recipient, 1); // Transfer 1 CustomToken to register
            };

            let mint_cap = &borrow_global<MintCapability>(@custom_token).cap;
            let coins = coin::mint(amount, mint_cap);
            coin::deposit(recipient, coins);
        };
    }

    public entry fun batch_airdrop(
        admin: &signer,
        recipients: vector<address>,
        amounts: vector<u64>
    ) acquires MintCapability {
        assert!(signer::address_of(admin) == @custom_token, E_NOT_ADMIN);
        assert!(vector::length(&recipients) == vector::length(&amounts), E_INVALID_INPUTS);

        let mint_cap = &borrow_global<MintCapability>(@custom_token).cap;
        let len = vector::length(&recipients);

        let i = 0;
        while (i < len) {
            let recipient_addr = *vector::borrow(&recipients, i);
            let amount = *vector::borrow(&amounts, i);

            if (!account::exists_at(recipient_addr)) {
                i = i + 1;
                continue
            };

            if (!coin::is_account_registered<CustomToken>(recipient_addr)) {
                i = i + 1;
                continue
            };

            let coins = coin::mint(amount, mint_cap);
            coin::deposit(recipient_addr, coins);

            i = i + 1;
        };
    }

    public entry fun open_airdrop(
        sender: &signer,
        recipients: vector<address>,
        amounts: vector<u64>
    ) {
        assert!(vector::length(&recipients) == vector::length(&amounts), E_INVALID_INPUTS);

        let sender_addr = signer::address_of(sender);
        let total_amount = sum_vector(&amounts);
        assert!(coin::balance<CustomToken>(sender_addr) >= total_amount, E_INSUFFICIENT_BALANCE);

        let len = vector::length(&recipients);
        let i = 0;
        while (i < len) {
            let recipient_addr = *vector::borrow(&recipients, i);
            let amount = *vector::borrow(&amounts, i);

            if (account::exists_at(recipient_addr)) {
              aptos_account::transfer_coins<CustomToken>(sender, recipient_addr, amount);


                // let coins = coin::withdraw<CustomToken>(sender, amount);
                // coin::deposit(recipient_addr, coins);
            };

            i = i + 1;
        };
    }

    public entry fun single_transfer(sender: &signer, recipient: address, amount: u64) {
        aptos_account::transfer_coins<CustomToken>(sender, recipient, amount);
    }

    public entry fun register(account: &signer) {
        coin::register<CustomToken>(account);
    }

    fun sum_vector(v: &vector<u64>): u64 {
        let sum = 0u64;
        let i = 0;
        let len = vector::length(v);
        while (i < len) {
            sum = sum + *vector::borrow(v, i);
            i = i + 1;
        };
        sum
    }

    #[test_only]
    public fun init_module_for_test(account: &signer) {
        init_module(account);
    }
}
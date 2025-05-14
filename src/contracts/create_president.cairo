use starknet::contract::ContractState;
use starknet::contract::traits::Contract;
use starknet::storage::{Storage, StorageMap};
use starknet::context::get_caller_address;
use starknet::prelude::*;

#[starknet::interface]
trait PresidentABI<TContractState> {
    fn create_president(
        ref self: TContractState,
        name: felt252,
        first_surname: felt252,
        second_surname: felt252,
        political_party: felt252
    );
    fn deactivate_president(
        ref self: ContractState,
        id: felt252
    );
}

#[derive(Copy, Drop, Serde, Clone)]
struct President {
    name: felt252,
    first_surname: felt252,
    second_surname: felt252,
    political_party: felt252,
    active: bool,
}

#[storage]
struct Storage {
    presidents: StorageMap<felt252, President>,
    next_president_id: felt252,
}

#[abi(embed_v0)]
impl PresidentABIImpl of PresidentABI<ContractState> {
    fn create_president(
        ref self: ContractState,
        name: felt252,
        first_surname: felt252,
        second_surname: felt252,
        political_party: felt252
    ) {
        let id = self.next_president_id.read();
        let new_president = President {
            name,
            first_surname,
            second_surname,
            political_party,
            active: true,
        };
        self.presidents.write(id, new_president);
        self.next_president_id.write(id + 1);
    }

    fn deactivate_president(ref self: ContractState, id: felt252) {
        let mut president = self.presidents.read(id);
        president.active = false;
        self.presidents.write(id, president);
    }
}

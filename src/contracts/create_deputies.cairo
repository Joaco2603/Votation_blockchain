use starknet::contract::ContractState;
use starknet::contract::traits::Contract;
use starknet::storage::{Storage, StorageMap};
use starknet::context::get_caller_address;
use core::dict::Felt252Dict;
use starknet::prelude::*;

#[starknet::interface]
trait DeputieABI<TContractState> {
    fn create_deputie(
        ref self: TContractState,
        name: felt252,
        first_surname: felt252,
        second_surname: felt252,
        political_party: felt252
    );
    fn create_deputies(ref self: ContractState, deputies: ArrayTrait::Felt252Dict<Deputies>);
    fn desactivate_deputie(
        ref self: TContractState,
        id: felt252
    );
}

#[derive(Copy, Drop, Serde, Clone)]
struct Deputies {
    name: felt252,
    first_surname: felt252,
    second_surname: felt252,
    political_party: felt252,
    active: bool,
}

#[storage]
struct Storage {
    deputies: StorageMap<felt252, Deputies>,
    next_deputie_id: felt252,
}

#[abi(embed_v0)]
impl DeputieABIImpl of DeputieABI<ContractState> {
    fn create_deputie(
        ref self: ContractState,
        name: felt252,
        first_surname: felt252,
        second_surname: felt252,
        political_party: felt252
    ) {
        let id = self.next_president_id.read();
        let new_deputie = Deputies {
            name,
            first_surname,
            second_surname,
            political_party,
            active: true,
        };
        self.deputies.write(id, new_deputie);
        self.next_deputie_id.write(id + 1);
    }

    
    fn create_deputies(ref self: ContractState, deputies: ArrayTrait::Felt252Dict<Deputies>){
        let mut number = self.next_deputie_id.read();
        
        while number > deputies.len(){
            self.deputies.write(number, deputies[number]);

            number += 1;
        }
    }

    fn desactivate_deputie(ref self: ContractState, id: felt252) {
        let mut deputiesInBlockchain = self.deputies.read(id);
        deputies.active = false;
        self.deputies.write(id, deputiesInBlockchain);
    }
}

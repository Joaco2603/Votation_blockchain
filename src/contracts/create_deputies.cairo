
#[derive(Drop, Copy, Serde, starknet::Store)]
struct Deputies {
    name: felt252,
    first_surname: felt252,
    second_surname: felt252,
    political_party: felt252,
    active: bool,
}


#[starknet::interface]
trait DeputieABI<TContractState> {
    fn create_deputie(
        ref self: TContractState,
        name: felt252,
        first_surname: felt252,
        second_surname: felt252,
        political_party: felt252,
        active: bool
    );
    fn create_deputies(ref self: TContractState, deputies: Array::<Deputies>);
    fn desactivate_deputie(
        ref self: TContractState,
        id: felt252
    );
}


#[starknet::contract]
mod DeputiesContract {
    use super::{DeputieABI, Deputies};
    use starknet::storage::Map;
    use starknet::storage::*;

    #[storage]
    struct Storage {
        deputie: Map<felt252, Deputies>,
        next_deputie_id: felt252,
    }

    #[abi(embed_v0)]
    impl DeputieABIImpl of DeputieABI<ContractState> {
        fn create_deputie(
            ref self: ContractState,
            name: felt252,
            first_surname: felt252,
            second_surname: felt252,
            political_party: felt252,
            active: bool
        ) {
            let id = self.next_deputie_id.read();
            let new_deputie = Deputies {
                name,
                first_surname,
                second_surname,
                political_party,
                active: true,
            };
            self.deputie.entry(id).write(new_deputie);
            self.next_deputie_id.write(id + 1);
        }
    
        fn create_deputies(ref self: ContractState, deputies: Array<Deputies>){
            let mut number: u32 = self.next_deputie_id.read().try_into().unwrap();
            
            while number < deputies.len(){
                self.deputie.write(number.into(), *deputies[number]);
    
                number += 1;
            }
        }
    
        fn desactivate_deputie(ref self: ContractState, id: felt252) {
            let mut deputiesInBlockchain = self.deputie.entry(id).read();
            deputiesInBlockchain.active = false;
            self.deputie.write(id, deputiesInBlockchain);
        }
    }
}
